import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

const String _defaultBaseUrl = 'https://cpbjr.github.io/catholic-readings-api';

const String _bibleDatabasePath = 'assets/databases/webc.db';

const String _defaultOutputDirectory = 'tool/source/lectionary';

const String _usccbCacheDirectory = 'tool/cache/usccb';

const Duration _usccbMinimumDelay = Duration(seconds: 3);

const List<String> _csvHeaders = <String>[
  'date',
  'liturgicalDay',
  'readingOrder',
  'kind',
  'title',
  'displayReference',
  'response',
  'choiceGroup',
  'choiceLabel',
  'rangeOrder',
  'bookCode',
  'chapter',
  'startVerse',
  'endVerse',
  'displayVerseOffset',
];

const List<SourceReadingDefinition> _readingDefinitions =
    <SourceReadingDefinition>[
      SourceReadingDefinition(
        sourceKeys: <String>['firstReading', 'first_reading', 'reading1'],
        kind: 'firstReading',
        title: 'First Reading',
        required: true,
      ),
      SourceReadingDefinition(
        sourceKeys: <String>[
          'psalm',
          'responsorialPsalm',
          'responsorial_psalm',
        ],
        kind: 'responsorialPsalm',
        title: 'Responsorial Psalm',
        required: true,
      ),
      SourceReadingDefinition(
        sourceKeys: <String>['secondReading', 'second_reading', 'reading2'],
        kind: 'secondReading',
        title: 'Second Reading',
        required: false,
      ),
      SourceReadingDefinition(
        sourceKeys: <String>[
          'gospelAcclamation',
          'gospel_acclamation',
          'acclamation',
        ],
        kind: 'gospelAcclamation',
        title: 'Gospel Acclamation',
        required: false,
      ),
      SourceReadingDefinition(
        sourceKeys: <String>['gospel'],
        kind: 'gospel',
        title: 'Gospel',
        required: true,
      ),
    ];

Future<void> main(List<String> arguments) async {
  try {
    final FetchOptions options = FetchOptions.parse(arguments);

    if (options.showHelp) {
      _printUsage();
      return;
    }

    stdout.writeln('One Nation Faith Lectionary Fetcher');
    stdout.writeln('=================================');
    stdout.writeln();

    stdout.writeln('Year: ${options.year}');
    stdout.writeln('From: ${_formatDate(options.startDate)}');
    stdout.writeln('To: ${_formatDate(options.endDate)}');
    stdout.writeln('Output: ${options.outputPath}');
    stdout.writeln('Report: ${options.reportPath}');
    stdout.writeln();

    final File databaseFile = File(_bibleDatabasePath);

    if (!databaseFile.existsSync()) {
      throw FetchException(
        'The WEBC database was not found:\n'
        '$_bibleDatabasePath',
      );
    }

    final File outputFile = File(options.outputPath);

    final File reportFile = File(options.reportPath);

    if (outputFile.existsSync() && !options.force) {
      throw FetchException(
        'The candidate CSV already exists:\n'
        '${outputFile.path}\n\n'
        'Use --force to replace it.',
      );
    }

    if (reportFile.existsSync() && !options.force) {
      throw FetchException(
        'The fetch report already exists:\n'
        '${reportFile.path}\n\n'
        'Use --force to replace it.',
      );
    }

    stdout.writeln('Loading the WEBC Bible index...');

    final BibleCatalog bibleCatalog = BibleCatalog.load(databaseFile);

    stdout.writeln(
      'Loaded ${bibleCatalog.bookCount} '
      'Bible books.',
    );
    stdout.writeln();

    final List<DateTime> dates = _datesBetween(
      options.startDate,
      options.endDate,
    );

    stdout.writeln('Fetching ${dates.length} date(s)...');
    stdout.writeln();

    final HttpJsonClient httpClient = HttpJsonClient(baseUrl: options.baseUrl);

    late final List<DayFetchResult> results;

    try {
      results = await _fetchAllDates(
        dates: dates,
        options: options,
        bibleCatalog: bibleCatalog,
        httpClient: httpClient,
      );
    } finally {
      httpClient.close();
    }

    results.sort(
      (DayFetchResult first, DayFetchResult second) =>
          first.date.compareTo(second.date),
    );

    final List<CsvReadingRow> outputRows = <CsvReadingRow>[];

    for (final DayFetchResult result in results) {
      if (result.isIncluded) {
        outputRows.addAll(result.rows);
      }
    }

    outputRows.sort((CsvReadingRow first, CsvReadingRow second) {
      final int dateComparison = first.date.compareTo(second.date);

      if (dateComparison != 0) {
        return dateComparison;
      }

      final int readingComparison = first.readingOrder.compareTo(
        second.readingOrder,
      );

      if (readingComparison != 0) {
        return readingComparison;
      }

      return first.rangeOrder.compareTo(second.rangeOrder);
    });

    await outputFile.parent.create(recursive: true);

    await reportFile.parent.create(recursive: true);

    outputFile.writeAsStringSync(
      _buildCsv(outputRows),
      encoding: utf8,
      flush: true,
    );

    final FetchSummary summary = FetchSummary.fromResults(
      requestedDateCount: dates.length,
      results: results,
      outputRowCount: outputRows.length,
    );

    reportFile.writeAsStringSync(
      _buildReport(options: options, results: results, summary: summary),
      encoding: utf8,
      flush: true,
    );

    stdout.writeln();
    stdout.writeln('Fetch Summary');
    stdout.writeln('=============');
    stdout.writeln(
      'Dates requested: '
      '${summary.requestedDateCount}',
    );
    stdout.writeln(
      'Reading files fetched: '
      '${summary.fetchedDateCount}',
    );
    stdout.writeln(
      'Dates written to CSV: '
      '${summary.includedDateCount}',
    );
    stdout.writeln(
      'Dates omitted from CSV: '
      '${summary.omittedDateCount}',
    );
    stdout.writeln(
      'CSV rows written: '
      '${summary.outputRowCount}',
    );
    stdout.writeln('Warnings: ${summary.warningCount}');
    stdout.writeln('Errors: ${summary.errorCount}');
    stdout.writeln();

    stdout.writeln('Candidate CSV created:');
    stdout.writeln(outputFile.path);
    stdout.writeln();

    stdout.writeln('Review report created:');
    stdout.writeln(reportFile.path);
    stdout.writeln();

    if (summary.errorCount > 0) {
      stdout.writeln('FETCH COMPLETED WITH ERRORS');
      stdout.writeln('Review the report before using the CSV.');
      exitCode = 2;
      return;
    }

    stdout.writeln('FETCH COMPLETED SUCCESSFULLY');
    stdout.writeln(
      'The candidate CSV still requires '
      'liturgical review before it replaces '
      'the verified source file.',
    );
  } on FetchException catch (error) {
    stderr.writeln();
    stderr.writeln('FETCH FAILED');
    stderr.writeln(error.message);
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln();
    stderr.writeln('FETCH FAILED');
    stderr.writeln(error.message);
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln();
    stderr.writeln('FETCH FAILED');
    stderr.writeln(error.message);
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr.writeln();
    stderr.writeln('FETCH FAILED');
    stderr.writeln(error);
    stderr.writeln();
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Future<List<DayFetchResult>> _fetchAllDates({
  required List<DateTime> dates,
  required FetchOptions options,
  required BibleCatalog bibleCatalog,
  required HttpJsonClient httpClient,
}) async {
  final List<DayFetchResult?> results = List<DayFetchResult?>.filled(
    dates.length,
    null,
  );

  int nextIndex = 0;
  int completedCount = 0;

  Future<void> worker() async {
    while (true) {
      if (nextIndex >= dates.length) {
        return;
      }

      final int index = nextIndex;
      nextIndex++;

      final DateTime date = dates[index];

      final DayFetchResult result = await _fetchDate(
        date: date,
        options: options,
        bibleCatalog: bibleCatalog,
        httpClient: httpClient,
      );

      results[index] = result;
      completedCount++;

      if (completedCount == dates.length || completedCount % 10 == 0) {
        stdout.writeln(
          'Fetched $completedCount of '
          '${dates.length} date(s)...',
        );
      }
    }
  }

  final int workerCount = options.concurrency > dates.length
      ? dates.length
      : options.concurrency;

  await Future.wait(List<Future<void>>.generate(workerCount, (_) => worker()));

  return results.whereType<DayFetchResult>().toList();
}

Future<DayFetchResult> _fetchDate({
  required DateTime date,
  required FetchOptions options,
  required BibleCatalog bibleCatalog,
  required HttpJsonClient httpClient,
}) async {
  final String dateText = _formatDate(date);
  final String monthDay = _formatMonthDay(date);

  final List<String> warnings = <String>[];
  final List<String> errors = <String>[];

  Map<String, dynamic>? readingsJson;
  Map<String, dynamic>? calendarJson;

  try {
    readingsJson = await httpClient.getJson(
      '/readings/${options.year}/'
      '$monthDay.json',
    );
  } on FetchException catch (error) {
    errors.add(
      'Could not fetch readings: '
      '${error.message}',
    );
  }

  try {
    calendarJson = await httpClient.getJson(
      '/liturgical-calendar/${options.year}/'
      '$monthDay.json',
    );
  } on FetchException catch (error) {
    warnings.add(
      'Could not fetch calendar information: '
      '${error.message}',
    );
  }

  if (readingsJson == null) {
    errors.add('The readings endpoint returned no data.');

    return DayFetchResult(
      date: dateText,
      rows: const <CsvReadingRow>[],
      warnings: warnings,
      errors: errors,
      readingsFetched: false,
      isIncluded: false,
    );
  }

  final String? sourceDate = _optionalString(readingsJson['date']);

  if (sourceDate != null && sourceDate != dateText) {
    errors.add(
      'The readings endpoint returned '
      '$sourceDate instead of $dateText.',
    );
  }

  final Map<String, dynamic>? readings = _asStringMap(readingsJson['readings']);

  if (readings == null) {
    errors.add(
      'The readings endpoint has no valid '
      'readings object.',
    );

    return DayFetchResult(
      date: dateText,
      rows: const <CsvReadingRow>[],
      warnings: warnings,
      errors: errors,
      readingsFetched: true,
      isIncluded: false,
    );
  }

  final String usccbPageUrl =
      _optionalString(readingsJson['usccbLink']) ??
      _buildUsccbDailyReadingsUrl(date);

  String? usccbHtml;

  try {
    final File usccbCacheFile = File('$_usccbCacheDirectory/$dateText.html');

    usccbHtml = await httpClient.getTextUrl(
      usccbPageUrl,
      cacheFile: usccbCacheFile,
    );

    if (usccbHtml == null) {
      warnings.add(
        'The USCCB page was not found: '
        '$usccbPageUrl',
      );
    } else if (!_containsGospelAcclamation(readings)) {
      final String? reference = _extractUsccbGospelAcclamationReference(
        usccbHtml,
      );

      if (reference == null) {
        warnings.add(
          'The USCCB page supplied no '
          'Scripture reference for the Gospel '
          'Acclamation. The acclamation may be '
          'text-only and requires review.',
        );
      } else {
        readings['gospelAcclamation'] = reference;
      }
    }
  } on FetchException catch (error) {
    warnings.add(
      'Could not fetch the USCCB page: '
      '${error.message}',
    );
  }

  final String? season = _optionalString(readingsJson['season']);

  String? liturgicalDay = usccbHtml == null
      ? null
      : _extractUsccbLiturgicalDayTitle(usccbHtml);

  liturgicalDay ??= _extractLiturgicalDay(calendarJson);

  if (liturgicalDay == null) {
    liturgicalDay = _fallbackLiturgicalDay(date, season);

    warnings.add(
      'A precise liturgical-day title was not '
      'available. Used "$liturgicalDay".',
    );
  }

  final List<CsvReadingRow> rows = <CsvReadingRow>[];

  int readingOrder = 1;

  for (final SourceReadingDefinition definition in _readingDefinitions) {
    final Object? sourceValue = _firstMapValue(readings, definition.sourceKeys);

    final List<String> choices = _extractReferenceChoices(sourceValue);

    if (choices.isEmpty) {
      if (definition.required) {
        errors.add(
          'No ${definition.title.toLowerCase()} '
          'reference was supplied.',
        );
      }

      continue;
    }

    final String? response = definition.kind == 'responsorialPsalm'
        ? _firstOptionalString(readings, const <String>[
            'psalmResponse',
            'psalm_response',
            'response',
          ])
        : null;

    for (int choiceIndex = 0; choiceIndex < choices.length; choiceIndex++) {
      final String reference = choices[choiceIndex];

      final String? choiceGroup = choices.length > 1 ? definition.kind : null;

      final String? choiceLabel = choices.length > 1
          ? _choiceLabel(choiceIndex)
          : null;

      final String title = choiceLabel == null
          ? definition.title
          : '${definition.title} — '
                '$choiceLabel';

      final ReferenceParseResult parsed = ReferenceParser(
        bibleCatalog,
      ).parse(_referenceForParsing(reference));

      for (final String warning in parsed.warnings) {
        warnings.add(
          '${definition.title} '
          '"$reference": $warning',
        );
      }

      for (final String error in parsed.errors) {
        errors.add(
          '${definition.title} '
          '"$reference": $error',
        );
      }

      if (parsed.ranges.isEmpty) {
        continue;
      }

      for (
        int rangeIndex = 0;
        rangeIndex < parsed.ranges.length;
        rangeIndex++
      ) {
        final ScriptureRange range = parsed.ranges[rangeIndex];

        rows.add(
          CsvReadingRow(
            date: dateText,
            liturgicalDay: liturgicalDay,
            readingOrder: readingOrder,
            kind: definition.kind,
            title: title,
            displayReference: _normalizeDisplayReference(reference),
            response: response,
            choiceGroup: choiceGroup,
            choiceLabel: choiceLabel,
            rangeOrder: rangeIndex + 1,
            bookCode: range.bookCode,
            chapter: range.chapter,
            startVerse: range.startVerse,
            endVerse: range.endVerse,
            displayVerseOffset: range.displayVerseOffset,
          ),
        );
      }

      readingOrder++;
    }
  }

  if (!_containsGospelAcclamation(readings)) {
    warnings.add(
      'The source supplied no Gospel '
      'Acclamation reference.',
    );
  }

  if (_firstOptionalString(readings, const <String>[
        'psalmResponse',
        'psalm_response',
        'response',
      ]) ==
      null) {
    warnings.add(
      'The source supplied no Responsorial '
      'Psalm response.',
    );
  }

  final bool hasErrors = errors.isNotEmpty;

  final bool includeDay =
      rows.isNotEmpty && (!hasErrors || options.includePartial);

  return DayFetchResult(
    date: dateText,
    rows: includeDay ? rows : const <CsvReadingRow>[],
    warnings: warnings,
    errors: errors,
    readingsFetched: true,
    isIncluded: includeDay,
  );
}

String? _extractLiturgicalDay(Map<String, dynamic>? calendarJson) {
  if (calendarJson == null) {
    return null;
  }

  final List<Object?> directValues = <Object?>[
    calendarJson['liturgicalDay'],
    calendarJson['liturgical_day'],
    calendarJson['title'],
    calendarJson['name'],
  ];

  for (final Object? value in directValues) {
    final String? text = _optionalString(value);

    if (text != null) {
      return text;
    }
  }

  final Map<String, dynamic>? celebration = _asStringMap(
    calendarJson['celebration'],
  );

  if (celebration != null) {
    final String? celebrationType = _firstOptionalString(
      celebration,
      const <String>['type', 'rank'],
    );

    if (celebrationType?.toUpperCase() == 'OPT_MEMORIAL') {
      final String? dateText = _optionalString(calendarJson['date']);

      final DateTime? date = dateText == null
          ? null
          : DateTime.tryParse(dateText);

      final String? subSeason = _firstOptionalString(
        calendarJson,
        const <String>['subSeason', 'sub_season'],
      );

      if (date != null && subSeason != null) {
        final String weekday = const <String>[
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ][date.weekday - 1];

        if (subSeason.toLowerCase() == 'time after epiphany') {
          return '$weekday after Epiphany';
        }
      }

      return null;
    }

    final String? name = _firstOptionalString(celebration, const <String>[
      'name',
      'title',
      'celebration',
    ]);

    if (name != null) {
      return name;
    }
  }

  final Map<String, dynamic>? day = _asStringMap(calendarJson['day']);

  if (day != null) {
    final String? name = _firstOptionalString(day, const <String>[
      'name',
      'title',
      'celebration',
      'liturgicalDay',
    ]);

    if (name != null) {
      return name;
    }

    final Map<String, dynamic>? nestedCelebration = _asStringMap(
      day['celebration'],
    );

    if (nestedCelebration != null) {
      return _firstOptionalString(nestedCelebration, const <String>[
        'name',
        'title',
      ]);
    }
  }

  return null;
}

String _fallbackLiturgicalDay(DateTime date, String? season) {
  final String weekday = const <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][date.weekday - 1];

  if (season == null) {
    return '$weekday — Liturgical title '
        'needs review';
  }

  return '$weekday — $season';
}

List<String> _extractReferenceChoices(Object? value) {
  if (value == null) {
    return const <String>[];
  }

  if (value is String) {
    final String trimmed = value.trim();

    if (!_looksLikeReference(trimmed)) {
      return const <String>[];
    }

    final List<String> splitChoices = trimmed.split(
      RegExp(
        r'\s+(?:or|OR)\s+'
        r'(?=(?:[1-3]\s+)?[A-Za-z])',
      ),
    );

    return splitChoices
        .map((String item) => item.trim())
        .where(_looksLikeReference)
        .toList();
  }

  if (value is List<dynamic>) {
    final List<String> choices = <String>[];

    for (final Object? item in value) {
      choices.addAll(_extractReferenceChoices(item));
    }

    return choices;
  }

  final Map<String, dynamic>? map = _asStringMap(value);

  if (map != null) {
    for (final String key in const <String>[
      'reference',
      'citation',
      'reading',
      'value',
    ]) {
      if (map.containsKey(key)) {
        final List<String> choices = _extractReferenceChoices(map[key]);

        if (choices.isNotEmpty) {
          return choices;
        }
      }
    }

    if (map.containsKey('choices')) {
      return _extractReferenceChoices(map['choices']);
    }
  }

  return const <String>[];
}

bool _looksLikeReference(String value) {
  if (value.isEmpty || value.length > 250) {
    return false;
  }

  return RegExp(r'\d').hasMatch(value);
}

bool _containsGospelAcclamation(Map<String, dynamic> readings) {
  return readings.containsKey('gospelAcclamation') ||
      readings.containsKey('gospel_acclamation') ||
      readings.containsKey('acclamation');
}

String _buildUsccbDailyReadingsUrl(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');

  final String day = date.day.toString().padLeft(2, '0');

  final String year = (date.year % 100).toString().padLeft(2, '0');

  return 'https://bible.usccb.org/bible/readings/'
      '$month$day$year.cfm';
}

String? _extractUsccbLiturgicalDayTitle(String html) {
  final RegExp titlePattern = RegExp(
    r'<title\b[^>]*>(.*?)</title>',
    caseSensitive: false,
    dotAll: true,
  );

  final RegExpMatch? match = titlePattern.firstMatch(html);

  if (match == null) {
    return null;
  }

  final String title = _htmlToPlainText(match.group(1) ?? '');

  final String cleaned = title
      .replaceFirst(RegExp(r'\s*\|\s*USCCB\s*$', caseSensitive: false), '')
      .trim();

  return cleaned.isEmpty ? null : cleaned;
}

String? _extractUsccbGospelAcclamationReference(String html) {
  final RegExp headingPattern = RegExp(
    r'<h[1-6]\b[^>]*>(.*?)</h[1-6]>',
    caseSensitive: false,
    dotAll: true,
  );

  for (final RegExpMatch headingMatch in headingPattern.allMatches(html)) {
    final String heading = _htmlToPlainText(
      headingMatch.group(1) ?? '',
    ).toLowerCase();

    if (heading != 'alleluia' && heading != 'verse before the gospel') {
      continue;
    }

    final int sectionStart = headingMatch.end;

    final RegExpMatch? nextHeading = RegExp(
      r'<h[1-6]\b',
      caseSensitive: false,
    ).firstMatch(html.substring(sectionStart));

    final int sectionEnd = nextHeading == null
        ? html.length
        : sectionStart + nextHeading.start;

    final String section = html.substring(sectionStart, sectionEnd);

    final RegExp anchorPattern = RegExp(
      r'<a\b[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );

    for (final RegExpMatch anchorMatch in anchorPattern.allMatches(section)) {
      final String candidate = _htmlToPlainText(anchorMatch.group(1) ?? '');

      if (_looksLikeScriptureReference(candidate)) {
        return candidate;
      }
    }

    final String sectionText = _htmlToPlainText(
      section,
      preserveLineBreaks: true,
    );

    for (final String line in sectionText.split('\n')) {
      final String candidate = line.trim();

      if (_looksLikeScriptureReference(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  return null;
}

bool _looksLikeScriptureReference(String value) {
  final String candidate = value.trim();

  if (!_looksLikeReference(candidate)) {
    return false;
  }

  return RegExp(
    r'^(?:(?:cf\.?|see)\s+)?'
    r'(?:[1-3]\s+)?[A-Za-z]'
    r'[A-Za-z .]*\s+\d+\s*:\s*\d+',
    caseSensitive: false,
  ).hasMatch(candidate);
}

String _referenceForParsing(String reference) {
  return reference
      .replaceFirst(RegExp(r'^(?:cf\.?|see)\s+', caseSensitive: false), '')
      .trim();
}

String _htmlToPlainText(String html, {bool preserveLineBreaks = false}) {
  String value = html;

  if (preserveLineBreaks) {
    value = value.replaceAll(
      RegExp(r'<(?:br\s*/?|/p|/div|/li)>', caseSensitive: false),
      '\n',
    );
  }

  value = value.replaceAll(RegExp(r'<[^>]+>', dotAll: true), ' ');

  value = _decodeBasicHtmlEntities(value);

  if (preserveLineBreaks) {
    return value
        .split('\n')
        .map((String line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((String line) => line.isNotEmpty)
        .join('\n');
  }

  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _decodeBasicHtmlEntities(String value) {
  String decoded = value
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&ndash;', '–')
      .replaceAll('&mdash;', '—');

  decoded = decoded.replaceAllMapped(RegExp(r'&#(\d+);'), (Match match) {
    final int? codePoint = int.tryParse(match.group(1) ?? '');

    return codePoint == null
        ? match.group(0) ?? ''
        : String.fromCharCode(codePoint);
  });

  decoded = decoded.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (
    Match match,
  ) {
    final int? codePoint = int.tryParse(match.group(1) ?? '', radix: 16);

    return codePoint == null
        ? match.group(0) ?? ''
        : String.fromCharCode(codePoint);
  });

  return decoded;
}

Object? _firstMapValue(Map<String, dynamic> map, List<String> keys) {
  for (final String key in keys) {
    if (map.containsKey(key)) {
      return map[key];
    }
  }

  return null;
}

String? _firstOptionalString(Map<String, dynamic> map, List<String> keys) {
  for (final String key in keys) {
    final String? value = _optionalString(map[key]);

    if (value != null) {
      return value;
    }
  }

  return null;
}

String? _optionalString(Object? value) {
  if (value is! String) {
    return null;
  }

  final String trimmed = value.trim();

  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic>? _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map<dynamic, dynamic>) {
    return value.map(
      (dynamic key, dynamic item) =>
          MapEntry<String, dynamic>(key.toString(), item),
    );
  }

  return null;
}

String _choiceLabel(int zeroBasedIndex) {
  const List<String> words = <String>[
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
  ];

  if (zeroBasedIndex < words.length) {
    return 'Choice ${words[zeroBasedIndex]}';
  }

  return 'Choice ${zeroBasedIndex + 1}';
}

String _normalizeDisplayReference(String reference) {
  return reference
      .trim()
      .replaceAll('—', '–')
      .replaceAllMapped(
        RegExp(r'(\d)-(\d)'),
        (Match match) => '${match.group(1)}–${match.group(2)}',
      );
}

String _buildCsv(List<CsvReadingRow> rows) {
  final StringBuffer output = StringBuffer();

  output.writeln(_csvHeaders.map(_escapeCsvField).join(','));

  for (final CsvReadingRow row in rows) {
    output.writeln(row.toValues().map(_escapeCsvField).join(','));
  }

  return output.toString();
}

String _buildReport({
  required FetchOptions options,
  required List<DayFetchResult> results,
  required FetchSummary summary,
}) {
  final StringBuffer report = StringBuffer();

  report.writeln('One Nation Faith Lectionary Fetch Report');
  report.writeln('======================================');
  report.writeln();
  report.writeln(
    'Generated: '
    '${DateTime.now().toUtc().toIso8601String()}',
  );
  report.writeln('Source: ${options.baseUrl}');
  report.writeln('Year: ${options.year}');
  report.writeln('From: ${_formatDate(options.startDate)}');
  report.writeln('To: ${_formatDate(options.endDate)}');
  report.writeln();
  report.writeln(
    'Dates requested: '
    '${summary.requestedDateCount}',
  );
  report.writeln(
    'Reading files fetched: '
    '${summary.fetchedDateCount}',
  );
  report.writeln(
    'Dates written to CSV: '
    '${summary.includedDateCount}',
  );
  report.writeln(
    'Dates omitted from CSV: '
    '${summary.omittedDateCount}',
  );
  report.writeln(
    'CSV rows written: '
    '${summary.outputRowCount}',
  );
  report.writeln('Warnings: ${summary.warningCount}');
  report.writeln('Errors: ${summary.errorCount}');
  report.writeln();

  report.writeln('IMPORTANT REVIEW NOTES');
  report.writeln('----------------------');
  report.writeln(
    '1. This is candidate data and must not '
    'automatically replace the verified CSV.',
  );
  report.writeln(
    '2. The source may not provide Gospel '
    'Acclamations or Responsorial Psalm '
    'responses.',
  );
  report.writeln(
    '3. Psalm verse numbering must be checked '
    'against the WEBC numbering.',
  );
  report.writeln(
    '4. Verse-letter references such as 4a or '
    '6b are expanded to the complete WEBC verse.',
  );
  report.writeln(
    '5. Sundays, solemnities, memorials, '
    'optional readings, transferred feasts, '
    'and local U.S. observances require review.',
  );
  report.writeln(
    '6. Successful USCCB pages are cached in '
    '$_usccbCacheDirectory. If access is blocked, '
    'rerun later to resume from the cache.',
  );
  report.writeln();

  for (final DayFetchResult result in results) {
    if (result.warnings.isEmpty && result.errors.isEmpty) {
      continue;
    }

    report.writeln(result.date);
    report.writeln('-' * result.date.length);

    for (final String warning in result.warnings) {
      report.writeln('WARNING: $warning');
    }

    for (final String error in result.errors) {
      report.writeln('ERROR: $error');
    }

    if (!result.isIncluded) {
      report.writeln('RESULT: Date omitted from candidate CSV.');
    }

    report.writeln();
  }

  return report.toString();
}

String _escapeCsvField(String value) {
  final bool requiresQuotes =
      value.contains(',') ||
      value.contains('"') ||
      value.contains('\r') ||
      value.contains('\n');

  if (!requiresQuotes) {
    return value;
  }

  return '"${value.replaceAll('"', '""')}"';
}

List<DateTime> _datesBetween(DateTime start, DateTime end) {
  final List<DateTime> dates = <DateTime>[];

  DateTime current = DateTime.utc(start.year, start.month, start.day);

  final DateTime finalDate = DateTime.utc(end.year, end.month, end.day);

  while (!current.isAfter(finalDate)) {
    dates.add(current);

    current = current.add(const Duration(days: 1));
  }

  return dates;
}

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _formatMonthDay(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime? _parseStrictDate(String value) {
  final Match? match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);

  if (match == null) {
    return null;
  }

  final int? year = int.tryParse(match.group(1)!);

  final int? month = int.tryParse(match.group(2)!);

  final int? day = int.tryParse(match.group(3)!);

  if (year == null || month == null || day == null) {
    return null;
  }

  final DateTime parsed = DateTime.utc(year, month, day);

  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }

  return parsed;
}

void _printUsage() {
  stdout.writeln('One Nation Faith Lectionary Fetcher');
  stdout.writeln();
  stdout.writeln('Fetch an entire year into a candidate CSV:');
  stdout.writeln('  dart run tool/fetch_lectionary.dart 2026');
  stdout.writeln();
  stdout.writeln('Fetch a smaller test range:');
  stdout.writeln(
    '  dart run tool/fetch_lectionary.dart 2026 '
    '--from 2026-07-28 --to 2026-08-02',
  );
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln('  --from DATE          First date to fetch.');
  stdout.writeln('  --to DATE            Last date to fetch.');
  stdout.writeln('  --output PATH        Candidate CSV path.');
  stdout.writeln('  --report PATH        Review-report path.');
  stdout.writeln('  --base-url URL       Override the API URL.');
  stdout.writeln(
    '  --concurrency N      Simultaneous requests '
    '(default 6).',
  );
  stdout.writeln(
    '  --include-partial    Include dates with '
    'parsing errors.',
  );
  stdout.writeln(
    '  --force              Replace existing '
    'candidate files.',
  );
  stdout.writeln('  --help               Show this help.');
}

class FetchOptions {
  const FetchOptions({
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.outputPath,
    required this.reportPath,
    required this.baseUrl,
    required this.concurrency,
    required this.includePartial,
    required this.force,
    required this.showHelp,
  });

  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final String outputPath;
  final String reportPath;
  final String baseUrl;
  final int concurrency;
  final bool includePartial;
  final bool force;
  final bool showHelp;

  static FetchOptions parse(List<String> arguments) {
    if (arguments.contains('--help') || arguments.contains('-h')) {
      final int year = DateTime.now().year;

      return FetchOptions(
        year: year,
        startDate: DateTime.utc(year, 1, 1),
        endDate: DateTime.utc(year, 12, 31),
        outputPath: '',
        reportPath: '',
        baseUrl: _defaultBaseUrl,
        concurrency: 6,
        includePartial: false,
        force: false,
        showHelp: true,
      );
    }

    int? year;
    DateTime? startDate;
    DateTime? endDate;

    String? outputPath;
    String? reportPath;

    String baseUrl = _defaultBaseUrl;

    int concurrency = 6;

    bool includePartial = false;
    bool force = false;

    for (int index = 0; index < arguments.length; index++) {
      final String argument = arguments[index];

      if (argument == '--force') {
        force = true;
        continue;
      }

      if (argument == '--include-partial') {
        includePartial = true;
        continue;
      }

      if (argument == '--from') {
        if (index + 1 >= arguments.length) {
          throw const FetchException('--from requires a date.');
        }

        final String value = arguments[++index];

        startDate = _parseStrictDate(value);

        if (startDate == null) {
          throw FetchException('Invalid --from date: $value');
        }

        continue;
      }

      if (argument.startsWith('--from=')) {
        final String value = argument.substring('--from='.length);

        startDate = _parseStrictDate(value);

        if (startDate == null) {
          throw FetchException('Invalid --from date: $value');
        }

        continue;
      }

      if (argument == '--to') {
        if (index + 1 >= arguments.length) {
          throw const FetchException('--to requires a date.');
        }

        final String value = arguments[++index];

        endDate = _parseStrictDate(value);

        if (endDate == null) {
          throw FetchException('Invalid --to date: $value');
        }

        continue;
      }

      if (argument.startsWith('--to=')) {
        final String value = argument.substring('--to='.length);

        endDate = _parseStrictDate(value);

        if (endDate == null) {
          throw FetchException('Invalid --to date: $value');
        }

        continue;
      }

      if (argument == '--output') {
        if (index + 1 >= arguments.length) {
          throw const FetchException('--output requires a path.');
        }

        outputPath = arguments[++index];
        continue;
      }

      if (argument.startsWith('--output=')) {
        outputPath = argument.substring('--output='.length);
        continue;
      }

      if (argument == '--report') {
        if (index + 1 >= arguments.length) {
          throw const FetchException('--report requires a path.');
        }

        reportPath = arguments[++index];
        continue;
      }

      if (argument.startsWith('--report=')) {
        reportPath = argument.substring('--report='.length);
        continue;
      }

      if (argument == '--base-url') {
        if (index + 1 >= arguments.length) {
          throw const FetchException('--base-url requires a URL.');
        }

        baseUrl = arguments[++index];
        continue;
      }

      if (argument.startsWith('--base-url=')) {
        baseUrl = argument.substring('--base-url='.length);
        continue;
      }

      if (argument == '--concurrency') {
        if (index + 1 >= arguments.length) {
          throw const FetchException('--concurrency requires a number.');
        }

        final String value = arguments[++index];

        concurrency = int.tryParse(value) ?? 0;

        if (concurrency < 1 || concurrency > 12) {
          throw FetchException(
            'Invalid concurrency: $value. '
            'Use a value from 1 through 12.',
          );
        }

        continue;
      }

      if (argument.startsWith('--concurrency=')) {
        final String value = argument.substring('--concurrency='.length);

        concurrency = int.tryParse(value) ?? 0;

        if (concurrency < 1 || concurrency > 12) {
          throw FetchException(
            'Invalid concurrency: $value. '
            'Use a value from 1 through 12.',
          );
        }

        continue;
      }

      if (argument.startsWith('-')) {
        throw FetchException('Unknown option: $argument');
      }

      if (year != null) {
        throw const FetchException('Only one year may be supplied.');
      }

      year = int.tryParse(argument);

      if (year == null || year < 1900 || year > 3000) {
        throw FetchException('Invalid year: $argument');
      }
    }

    if (year == null) {
      throw const FetchException(
        'A year is required.\n\n'
        'Example:\n'
        'dart run tool/fetch_lectionary.dart 2026',
      );
    }

    startDate ??= DateTime.utc(year, 1, 1);

    endDate ??= DateTime.utc(year, 12, 31);

    if (startDate.year != year) {
      throw FetchException('--from must be within $year.');
    }

    if (endDate.year != year) {
      throw FetchException('--to must be within $year.');
    }

    if (endDate.isBefore(startDate)) {
      throw const FetchException('--to cannot come before --from.');
    }

    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return FetchOptions(
      year: year,
      startDate: startDate,
      endDate: endDate,
      outputPath:
          outputPath ??
          '$_defaultOutputDirectory/'
              '${year}_fetched.csv',
      reportPath:
          reportPath ??
          '$_defaultOutputDirectory/'
              '${year}_fetch_report.txt',
      baseUrl: normalizedBaseUrl,
      concurrency: concurrency,
      includePartial: includePartial,
      force: force,
      showHelp: false,
    );
  }
}

class SourceReadingDefinition {
  const SourceReadingDefinition({
    required this.sourceKeys,
    required this.kind,
    required this.title,
    required this.required,
  });

  final List<String> sourceKeys;
  final String kind;
  final String title;
  final bool required;
}

class HttpJsonClient {
  HttpJsonClient({required this.baseUrl}) {
    _client.connectionTimeout = const Duration(seconds: 20);

    _client.userAgent = 'OneNationFaithLectionaryFetcher/1.0';
  }

  final String baseUrl;

  final HttpClient _client = HttpClient();

  Future<void> _usccbQueue = Future<void>.value();
  DateTime? _lastUsccbRequestAt;
  bool _usccbBlocked = false;

  Future<Map<String, dynamic>?> getJson(String path) async {
    final Uri uri = Uri.parse('$baseUrl$path');

    Object? lastError;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final HttpClientRequest request = await _client.getUrl(uri);

        request.headers.set(HttpHeaders.acceptHeader, 'application/json');

        final HttpClientResponse response = await request.close();

        final String responseBody = await utf8.decoder.bind(response).join();

        if (response.statusCode == HttpStatus.notFound) {
          return null;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw FetchException(
            'HTTP ${response.statusCode} '
            'for $path.',
          );
        }

        final Object? decoded = jsonDecode(responseBody);

        final Map<String, dynamic>? json = _asStringMap(decoded);

        if (json == null) {
          throw FetchException(
            'The response for $path was not '
            'a JSON object.',
          );
        }

        return json;
      } catch (error) {
        lastError = error;

        if (attempt < 3) {
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    throw FetchException(
      'Request failed for $path after '
      'three attempts: $lastError',
    );
  }

  Future<String?> getTextUrl(String url, {File? cacheFile}) {
    final Completer<String?> completer = Completer<String?>();

    _usccbQueue = _usccbQueue.then((_) async {
      try {
        final String? result = await _getTextUrlSerial(
          url,
          cacheFile: cacheFile,
        );

        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  Future<String?> _getTextUrlSerial(String url, {File? cacheFile}) async {
    if (cacheFile != null &&
        cacheFile.existsSync() &&
        cacheFile.lengthSync() > 0) {
      return cacheFile.readAsStringSync(encoding: utf8);
    }

    if (_usccbBlocked) {
      throw const FetchException(
        'USCCB blocked further requests earlier '
        'in this run. Successful pages were '
        'cached. Rerun later to resume.',
      );
    }

    final Uri uri = Uri.parse(url);
    Object? lastError;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final DateTime now = DateTime.now();
        final DateTime? lastRequest = _lastUsccbRequestAt;

        if (lastRequest != null) {
          final Duration elapsed = now.difference(lastRequest);

          if (elapsed < _usccbMinimumDelay) {
            await Future<void>.delayed(_usccbMinimumDelay - elapsed);
          }
        }

        _lastUsccbRequestAt = DateTime.now();

        final HttpClientRequest request = await _client.getUrl(uri);

        request.headers.set(
          HttpHeaders.acceptHeader,
          'text/html,application/xhtml+xml',
        );

        request.headers.set(
          HttpHeaders.userAgentHeader,
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
          'AppleWebKit/537.36 Chrome/142.0 Safari/537.36',
        );

        request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');

        final HttpClientResponse response = await request.close();

        final String responseBody = await utf8.decoder.bind(response).join();

        if (response.statusCode == HttpStatus.notFound) {
          return null;
        }

        if (response.statusCode == HttpStatus.forbidden ||
            response.statusCode == 429) {
          _usccbBlocked = true;

          throw FetchException(
            'HTTP ${response.statusCode} for '
            '$url. USCCB blocked further '
            'requests. Successful pages were '
            'cached. Rerun later to resume.',
          );
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw FetchException(
            'HTTP ${response.statusCode} '
            'for $url.',
          );
        }

        if (cacheFile != null) {
          await cacheFile.parent.create(recursive: true);

          cacheFile.writeAsStringSync(
            responseBody,
            encoding: utf8,
            flush: true,
          );
        }

        return responseBody;
      } catch (error) {
        lastError = error;

        if (_usccbBlocked) {
          rethrow;
        }

        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: 3 * attempt));
        }
      }
    }

    throw FetchException(
      'Request failed for $url after '
      'three attempts: $lastError',
    );
  }

  void close() {
    _client.close(force: true);
  }
}

class BibleCatalog {
  BibleCatalog._({required this.booksByCode, required this.aliases}) {
    _sortedAliases = aliases.keys.toList()
      ..sort(
        (String first, String second) => second.length.compareTo(first.length),
      );
  }

  final Map<String, BibleBookInfo> booksByCode;

  final Map<String, BibleBookInfo> aliases;

  late final List<String> _sortedAliases;

  int get bookCount => booksByCode.length;

  static BibleCatalog load(File databaseFile) {
    final Database database = sqlite3.open(
      databaseFile.path,
      mode: OpenMode.readOnly,
    );

    try {
      final ResultSet bookRows = database.select('''
SELECT
  id,
  usfm_code,
  name,
  full_name,
  short_name
FROM bible_books
ORDER BY canonical_order
''');

      final Map<int, BibleBookInfo> booksById = <int, BibleBookInfo>{};

      final Map<String, BibleBookInfo> booksByCode = <String, BibleBookInfo>{};

      for (final Row row in bookRows) {
        final int id = row['id'] as int;

        final String code = row['usfm_code'].toString().trim().toUpperCase();

        final BibleBookInfo book = BibleBookInfo(
          id: id,
          code: code,
          name: row['name'].toString(),
          fullName: row['full_name'].toString(),
          shortName: row['short_name'].toString(),
        );

        booksById[id] = book;
        booksByCode[code] = book;
      }

      final ResultSet verseRows = database.select('''
SELECT
  book_id,
  chapter,
  MAX(verse_end) AS maximum_verse
FROM bible_verses
GROUP BY
  book_id,
  chapter
ORDER BY
  book_id,
  chapter
''');

      for (final Row row in verseRows) {
        final int bookId = row['book_id'] as int;

        final int chapter = row['chapter'] as int;

        final int maximumVerse = row['maximum_verse'] as int;

        booksById[bookId]?.maximumVerseByChapter[chapter] = maximumVerse;
      }

      if (booksByCode.isEmpty) {
        throw const FormatException(
          'The WEBC database contains no '
          'Bible books.',
        );
      }

      final Map<String, BibleBookInfo> aliases = <String, BibleBookInfo>{};

      void addAlias(String alias, BibleBookInfo book) {
        final String normalized = _normalizeBookAlias(alias);

        if (normalized.isEmpty) {
          return;
        }

        aliases.putIfAbsent(normalized, () => book);
      }

      for (final BibleBookInfo book in booksByCode.values) {
        addAlias(book.code, book);
        addAlias(book.name, book);
        addAlias(book.fullName, book);
        addAlias(book.shortName, book);
      }

      void addAliasesForCode(
        List<String> possibleCodes,
        List<String> additionalAliases,
      ) {
        BibleBookInfo? book;

        for (final String code in possibleCodes) {
          book = booksByCode[code];

          if (book != null) {
            break;
          }
        }

        if (book == null) {
          return;
        }

        for (final String alias in additionalAliases) {
          addAlias(alias, book);
        }
      }

      addAliasesForCode(
        const <String>['PSA'],
        const <String>['Psalm', 'Psalms', 'Ps'],
      );

      addAliasesForCode(
        const <String>['SNG'],
        const <String>[
          'Song of Songs',
          'Song of Solomon',
          'Canticle of Canticles',
          'Canticles',
        ],
      );

      addAliasesForCode(
        const <String>['SIR'],
        const <String>['Sirach', 'Ecclesiasticus'],
      );

      addAliasesForCode(
        const <String>['REV'],
        const <String>['Revelation', 'Apocalypse'],
      );

      addAliasesForCode(const <String>['ESG', 'EST'], const <String>['Esther']);

      addAliasesForCode(const <String>['DAG', 'DAN'], const <String>['Daniel']);

      _addCommonAbbreviations(booksByCode, addAlias);

      return BibleCatalog._(booksByCode: booksByCode, aliases: aliases);
    } finally {
      database.close();
    }
  }

  BookMatch? matchBook(String reference) {
    final String cleaned = _cleanReferenceForBookMatching(reference);

    final String lower = cleaned.toLowerCase();

    for (final String alias in _sortedAliases) {
      if (lower == alias) {
        return BookMatch(book: aliases[alias]!, remainder: '');
      }

      if (lower.startsWith('$alias ')) {
        return BookMatch(
          book: aliases[alias]!,
          remainder: cleaned.substring(alias.length).trim(),
        );
      }
    }

    return null;
  }

  static void _addCommonAbbreviations(
    Map<String, BibleBookInfo> booksByCode,
    void Function(String alias, BibleBookInfo book) addAlias,
  ) {
    const Map<String, List<String>> abbreviations = <String, List<String>>{
      'GEN': <String>['Gen'],
      'EXO': <String>['Ex', 'Exod'],
      'LEV': <String>['Lev'],
      'NUM': <String>['Num'],
      'DEU': <String>['Deut', 'Dt'],
      'JOS': <String>['Josh'],
      'JDG': <String>['Judg'],
      '1SA': <String>['1 Sam'],
      '2SA': <String>['2 Sam'],
      '1KI': <String>['1 Kgs'],
      '2KI': <String>['2 Kgs'],
      '1CH': <String>['1 Chr'],
      '2CH': <String>['2 Chr'],
      'NEH': <String>['Neh'],
      '1MA': <String>['1 Macc'],
      '2MA': <String>['2 Macc'],
      'PRO': <String>['Prov'],
      'ECC': <String>['Eccl'],
      'WIS': <String>['Wis'],
      'SIR': <String>['Sir'],
      'ISA': <String>['Isa'],
      'JER': <String>['Jer'],
      'LAM': <String>['Lam'],
      'BAR': <String>['Bar'],
      'EZK': <String>['Ezek'],
      'HOS': <String>['Hos'],
      'JOL': <String>['Joel'],
      'AMO': <String>['Am'],
      'OBA': <String>['Obad'],
      'JON': <String>['Jon'],
      'MIC': <String>['Mic'],
      'NAM': <String>['Nah'],
      'HAB': <String>['Hab'],
      'ZEP': <String>['Zeph'],
      'HAG': <String>['Hag'],
      'ZEC': <String>['Zech'],
      'MAL': <String>['Mal'],
      'MAT': <String>['Matt', 'Mt'],
      'MRK': <String>['Mark', 'Mk'],
      'LUK': <String>['Luke', 'Lk'],
      'JHN': <String>['John', 'Jn'],
      'ACT': <String>['Acts'],
      'ROM': <String>['Rom'],
      '1CO': <String>['1 Cor'],
      '2CO': <String>['2 Cor'],
      'GAL': <String>['Gal'],
      'EPH': <String>['Eph'],
      'PHP': <String>['Phil'],
      'COL': <String>['Col'],
      '1TH': <String>['1 Thess'],
      '2TH': <String>['2 Thess'],
      '1TI': <String>['1 Tim'],
      '2TI': <String>['2 Tim'],
      'TIT': <String>['Tit'],
      'PHM': <String>['Phlm', 'Philemon'],
      'HEB': <String>['Heb'],
      'JAS': <String>['Jas'],
      '1PE': <String>['1 Pet'],
      '2PE': <String>['2 Pet'],
      '1JN': <String>['1 Jn'],
      '2JN': <String>['2 Jn'],
      '3JN': <String>['3 Jn'],
      'JUD': <String>['Jude'],
      'REV': <String>['Rev'],
    };

    for (final MapEntry<String, List<String>> entry in abbreviations.entries) {
      final BibleBookInfo? book = booksByCode[entry.key];

      if (book == null) {
        continue;
      }

      for (final String alias in entry.value) {
        addAlias(alias, book);
      }
    }
  }
}

String _cleanReferenceForBookMatching(String value) {
  return value
      .replaceAll('\u00A0', ' ')
      .replaceAll('.', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalizeBookAlias(String value) {
  return _cleanReferenceForBookMatching(value)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class BibleBookInfo {
  BibleBookInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.fullName,
    required this.shortName,
  });

  final int id;
  final String code;
  final String name;
  final String fullName;
  final String shortName;

  final Map<int, int> maximumVerseByChapter = <int, int>{};

  int get chapterCount => maximumVerseByChapter.length;

  bool containsChapter(int chapter) {
    return maximumVerseByChapter.containsKey(chapter);
  }

  int? maximumVerse(int chapter) {
    return maximumVerseByChapter[chapter];
  }
}

class BookMatch {
  const BookMatch({required this.book, required this.remainder});

  final BibleBookInfo book;
  final String remainder;
}

class ReferenceParser {
  ReferenceParser(this.catalog);

  final BibleCatalog catalog;

  ReferenceParseResult parse(String reference) {
    final List<ScriptureRange> ranges = <ScriptureRange>[];

    final List<String> warnings = <String>[];

    final List<String> errors = <String>[];

    final BookMatch? bookMatch = catalog.matchBook(reference);

    if (bookMatch == null) {
      errors.add('The Bible book could not be recognized.');

      return ReferenceParseResult(
        ranges: ranges,
        warnings: warnings,
        errors: errors,
      );
    }

    final BibleBookInfo book = bookMatch.book;

    String remainder = bookMatch.remainder
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+(?:and|AND)\s+'), ', ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (remainder.isEmpty) {
      errors.add(
        'The reference contains no chapter '
        'or verse numbers.',
      );

      return ReferenceParseResult(
        ranges: ranges,
        warnings: warnings,
        errors: errors,
      );
    }

    if (remainder.contains(RegExp(r'\b(?:or|OR)\b'))) {
      errors.add(
        'The reference contains an unresolved '
        'alternative reading.',
      );

      return ReferenceParseResult(
        ranges: ranges,
        warnings: warnings,
        errors: errors,
      );
    }

    if (book.code == 'PSA') {
      warnings.add(
        'Psalm numbering and '
        'displayVerseOffset require review.',
      );
    }

    final List<String> segments = remainder.split(';');

    int? currentChapter;

    for (String segment in segments) {
      segment = segment.trim();

      if (segment.isEmpty) {
        continue;
      }

      final Match? chapterMatch = RegExp(
        r'^(\d+)\s*:\s*(.+)$',
      ).firstMatch(segment);

      String verseSpecification;

      if (chapterMatch != null) {
        currentChapter = int.parse(chapterMatch.group(1)!);

        verseSpecification = chapterMatch.group(2)!.trim();
      } else {
        if (currentChapter == null) {
          if (book.chapterCount == 1) {
            currentChapter = 1;
          } else {
            errors.add(
              'No numeric chapter was found '
              'before "$segment".',
            );
            continue;
          }
        }

        verseSpecification = segment;
      }

      final List<String> verseTokens = verseSpecification.split(',');

      for (String token in verseTokens) {
        token = token.replaceAll(RegExp(r'\([^)]*\)'), '').trim();

        if (token.isEmpty) {
          continue;
        }

        final Match? tokenChapterMatch = RegExp(
          r'^(\d+)\s*:\s*(.+)$',
        ).firstMatch(token);

        if (tokenChapterMatch != null) {
          currentChapter = int.parse(tokenChapterMatch.group(1)!);

          token = tokenChapterMatch.group(2)!.trim();
        }

        final int dashIndex = token.indexOf('-');

        final String startText = dashIndex < 0
            ? token
            : token.substring(0, dashIndex).trim();

        final String endText = dashIndex < 0
            ? token
            : token.substring(dashIndex + 1).trim();

        final VerseEndpoint? startEndpoint = _parseEndpoint(
          startText,
          defaultChapter: currentChapter,
        );

        final VerseEndpoint? endEndpoint = _parseEndpoint(
          endText,
          defaultChapter: startEndpoint?.chapter ?? currentChapter,
        );

        if (startEndpoint == null || endEndpoint == null) {
          errors.add(
            'Could not parse verse token '
            '"$token".',
          );
          continue;
        }

        currentChapter = startEndpoint.chapter;

        if (startEndpoint.suffix != null || endEndpoint.suffix != null) {
          warnings.add(
            'Verse-letter notation in "$token" '
            'was expanded to complete verses.',
          );
        }

        if (endEndpoint.chapter < startEndpoint.chapter) {
          errors.add(
            'The range "$token" ends in an '
            'earlier chapter.',
          );
          continue;
        }

        final List<ScriptureRange> expandedRanges = _expandRange(
          book: book,
          start: startEndpoint,
          end: endEndpoint,
          errors: errors,
          originalToken: token,
        );

        ranges.addAll(expandedRanges);

        currentChapter = endEndpoint.chapter;
      }
    }

    if (book.code == 'PSA') {
      _applyPsalmVerseOffsets(
        book: book,
        ranges: ranges,
        warnings: warnings,
        errors: errors,
      );
    }

    return ReferenceParseResult(
      ranges: ranges,
      warnings: warnings.toSet().toList(),
      errors: errors.toSet().toList(),
    );
  }

  VerseEndpoint? _parseEndpoint(String value, {required int? defaultChapter}) {
    String cleaned = value.trim();

    int? chapter = defaultChapter;

    final Match? chapterMatch = RegExp(
      r'^(\d+)\s*:\s*(.+)$',
    ).firstMatch(cleaned);

    if (chapterMatch != null) {
      chapter = int.parse(chapterMatch.group(1)!);

      cleaned = chapterMatch.group(2)!.trim();
    }

    if (chapter == null) {
      return null;
    }

    final Match? verseMatch = RegExp(
      r'^(\d+)([a-zA-Z]+)?$',
    ).firstMatch(cleaned);

    if (verseMatch == null) {
      return null;
    }

    return VerseEndpoint(
      chapter: chapter,
      verse: int.parse(verseMatch.group(1)!),
      suffix: verseMatch.group(2),
    );
  }

  List<ScriptureRange> _expandRange({
    required BibleBookInfo book,
    required VerseEndpoint start,
    required VerseEndpoint end,
    required List<String> errors,
    required String originalToken,
  }) {
    final List<ScriptureRange> ranges = <ScriptureRange>[];

    for (int chapter = start.chapter; chapter <= end.chapter; chapter++) {
      final int? maximumVerse = book.maximumVerse(chapter);

      if (maximumVerse == null) {
        errors.add(
          '${book.code} chapter $chapter '
          'does not exist for "$originalToken".',
        );
        continue;
      }

      final int rangeStart = chapter == start.chapter ? start.verse : 1;

      final int rangeEnd = chapter == end.chapter ? end.verse : maximumVerse;

      final int allowedMaximumVerse = book.code == 'PSA'
          ? maximumVerse + 1
          : maximumVerse;

      if (rangeStart < 1 ||
          rangeEnd < rangeStart ||
          rangeEnd > allowedMaximumVerse) {
        errors.add(
          '${book.code} $chapter:'
          '$rangeStart-$rangeEnd is outside '
          'the WEBC chapter for '
          '"$originalToken".',
        );
        continue;
      }

      ranges.add(
        ScriptureRange(
          bookCode: book.code,
          chapter: chapter,
          startVerse: rangeStart,
          endVerse: rangeEnd,
          displayVerseOffset: 0,
        ),
      );
    }

    return ranges;
  }

  void _applyPsalmVerseOffsets({
    required BibleBookInfo book,
    required List<ScriptureRange> ranges,
    required List<String> warnings,
    required List<String> errors,
  }) {
    final Map<int, List<int>> indexesByChapter = <int, List<int>>{};

    for (int index = 0; index < ranges.length; index++) {
      final ScriptureRange range = ranges[index];

      indexesByChapter.putIfAbsent(range.chapter, () => <int>[]).add(index);
    }

    for (final MapEntry<int, List<int>> entry in indexesByChapter.entries) {
      final int chapter = entry.key;

      final int? maximumVerse = book.maximumVerse(chapter);

      if (maximumVerse == null) {
        continue;
      }

      final List<int> indexes = entry.value;

      final bool needsOffset = indexes.any(
        (int index) => ranges[index].endVerse > maximumVerse,
      );

      if (!needsOffset) {
        continue;
      }

      final bool canShiftByOne = indexes.every((int index) {
        final ScriptureRange range = ranges[index];

        return range.startVerse > 1 && range.endVerse - 1 <= maximumVerse;
      });

      if (!canShiftByOne) {
        errors.add(
          'Psalm $chapter appears to require '
          'a verse-number offset, but its ranges '
          'cannot safely be shifted.',
        );
        continue;
      }

      for (final int index in indexes) {
        final ScriptureRange range = ranges[index];

        ranges[index] = ScriptureRange(
          bookCode: range.bookCode,
          chapter: range.chapter,
          startVerse: range.startVerse - 1,
          endVerse: range.endVerse - 1,
          displayVerseOffset: 1,
        );
      }

      warnings.add(
        'Psalm $chapter was automatically '
        'mapped using displayVerseOffset 1.',
      );
    }
  }
}

class VerseEndpoint {
  const VerseEndpoint({
    required this.chapter,
    required this.verse,
    required this.suffix,
  });

  final int chapter;
  final int verse;
  final String? suffix;
}

class ReferenceParseResult {
  const ReferenceParseResult({
    required this.ranges,
    required this.warnings,
    required this.errors,
  });

  final List<ScriptureRange> ranges;
  final List<String> warnings;
  final List<String> errors;
}

class ScriptureRange {
  const ScriptureRange({
    required this.bookCode,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.displayVerseOffset,
  });

  final String bookCode;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final int displayVerseOffset;
}

class CsvReadingRow {
  const CsvReadingRow({
    required this.date,
    required this.liturgicalDay,
    required this.readingOrder,
    required this.kind,
    required this.title,
    required this.displayReference,
    required this.response,
    required this.choiceGroup,
    required this.choiceLabel,
    required this.rangeOrder,
    required this.bookCode,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.displayVerseOffset,
  });

  final String date;
  final String liturgicalDay;
  final int readingOrder;
  final String kind;
  final String title;
  final String displayReference;
  final String? response;
  final String? choiceGroup;
  final String? choiceLabel;
  final int rangeOrder;
  final String bookCode;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final int displayVerseOffset;

  List<String> toValues() {
    return <String>[
      date,
      liturgicalDay,
      readingOrder.toString(),
      kind,
      title,
      displayReference,
      response ?? '',
      choiceGroup ?? '',
      choiceLabel ?? '',
      rangeOrder.toString(),
      bookCode,
      chapter.toString(),
      startVerse.toString(),
      endVerse.toString(),
      displayVerseOffset.toString(),
    ];
  }
}

class DayFetchResult {
  const DayFetchResult({
    required this.date,
    required this.rows,
    required this.warnings,
    required this.errors,
    required this.readingsFetched,
    required this.isIncluded,
  });

  final String date;
  final List<CsvReadingRow> rows;
  final List<String> warnings;
  final List<String> errors;
  final bool readingsFetched;
  final bool isIncluded;
}

class FetchSummary {
  const FetchSummary({
    required this.requestedDateCount,
    required this.fetchedDateCount,
    required this.includedDateCount,
    required this.omittedDateCount,
    required this.outputRowCount,
    required this.warningCount,
    required this.errorCount,
  });

  final int requestedDateCount;
  final int fetchedDateCount;
  final int includedDateCount;
  final int omittedDateCount;
  final int outputRowCount;
  final int warningCount;
  final int errorCount;

  static FetchSummary fromResults({
    required int requestedDateCount,
    required List<DayFetchResult> results,
    required int outputRowCount,
  }) {
    int fetchedDateCount = 0;
    int includedDateCount = 0;
    int warningCount = 0;
    int errorCount = 0;

    for (final DayFetchResult result in results) {
      if (result.readingsFetched) {
        fetchedDateCount++;
      }

      if (result.isIncluded) {
        includedDateCount++;
      }

      warningCount += result.warnings.length;
      errorCount += result.errors.length;
    }

    return FetchSummary(
      requestedDateCount: requestedDateCount,
      fetchedDateCount: fetchedDateCount,
      includedDateCount: includedDateCount,
      omittedDateCount: requestedDateCount - includedDateCount,
      outputRowCount: outputRowCount,
      warningCount: warningCount,
      errorCount: errorCount,
    );
  }
}

class FetchException implements Exception {
  const FetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
