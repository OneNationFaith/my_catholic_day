import 'dart:convert';
import 'dart:io';

const int _supportedOverrideSchemaVersion = 1;

const String _sourceDirectory =
    'tool/source/lectionary';

const String _importerPath =
    'tool/import_lectionary.dart';

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

const Set<String> _allowedReadingKinds = <String>{
  'firstReading',
  'responsorialPsalm',
  'secondReading',
  'gospelAcclamation',
  'gospel',
  'other',
};

const Map<String, int> _readingKindOrder =
    <String, int>{
  'firstReading': 1,
  'responsorialPsalm': 2,
  'secondReading': 3,
  'gospelAcclamation': 4,
  'gospel': 5,
  'other': 6,
};

Future<void> main(List<String> arguments) async {
  try {
    final OverrideOptions options =
        OverrideOptions.parse(arguments);

    if (options.showHelp) {
      _printUsage();
      return;
    }

    stdout.writeln(
      'My Catholic Day Lectionary Override Tool',
    );
    stdout.writeln(
      '=======================================',
    );
    stdout.writeln();

    stdout.writeln('Year: ${options.year}');
    stdout.writeln(
      'Fetched CSV: ${options.inputPath}',
    );
    stdout.writeln(
      'Overrides: ${options.overridePath}',
    );
    stdout.writeln(
      'Merged CSV: ${options.outputPath}',
    );
    stdout.writeln();

    final File inputFile = File(
      options.inputPath,
    );

    final File overrideFile = File(
      options.overridePath,
    );

    final File outputFile = File(
      options.outputPath,
    );

    if (!inputFile.existsSync()) {
      throw OverrideException(
        'The fetched CSV file was not found:\n'
        '${inputFile.path}\n\n'
        'Fetch the year first with:\n'
        'dart run tool/fetch_lectionary.dart '
        '${options.year} --include-partial --force',
      );
    }

    if (!overrideFile.existsSync()) {
      throw OverrideException(
        'The override JSON file was not found:\n'
        '${overrideFile.path}',
      );
    }

    if (outputFile.existsSync() &&
        !options.force) {
      throw OverrideException(
        'The merged CSV already exists:\n'
        '${outputFile.path}\n\n'
        'Use --force to replace it.',
      );
    }

    stdout.writeln(
      'Reading the fetched candidate CSV...',
    );

    final Map<String, DayData> daysByDate =
        _loadFetchedCsv(
      file: inputFile,
      expectedYear: options.year,
    );

    stdout.writeln(
      'Loaded ${daysByDate.length} date(s).',
    );
    stdout.writeln();

    stdout.writeln(
      'Reading the override file...',
    );

    final OverrideDocument overrides =
        OverrideDocument.load(
      file: overrideFile,
      expectedYear: options.year,
    );

    stdout.writeln(
      'Loaded ${overrides.days.length} '
      'date override(s).',
    );
    stdout.writeln();

    final ApplySummary applySummary =
        _applyOverrides(
      daysByDate: daysByDate,
      overrides: overrides,
    );

    _validateCalendarCoverage(
      year: options.year,
      daysByDate: daysByDate,
      allowIncomplete: options.allowIncomplete,
    );

    final List<CsvOutputRow> outputRows =
        _buildOutputRows(daysByDate);

    if (outputRows.isEmpty) {
      throw const OverrideException(
        'The merged calendar contains no rows.',
      );
    }

    final String csvText = _buildCsv(
      outputRows,
    );

    outputFile.parent.createSync(
      recursive: true,
    );

    outputFile.writeAsStringSync(
      csvText,
      encoding: utf8,
      flush: true,
    );

    stdout.writeln(
      'Override Summary',
    );
    stdout.writeln(
      '================',
    );
    stdout.writeln(
      'Dates in merged calendar: '
      '${daysByDate.length}',
    );
    stdout.writeln(
      'Override dates applied: '
      '${applySummary.overrideDateCount}',
    );
    stdout.writeln(
      'Reading groups replaced: '
      '${applySummary.replacedKindCount}',
    );
    stdout.writeln(
      'Replacement readings inserted: '
      '${applySummary.replacementReadingCount}',
    );
    stdout.writeln(
      'Merged readings: '
      '${_countReadings(daysByDate)}',
    );
    stdout.writeln(
      'Merged Scripture ranges: '
      '${outputRows.length}',
    );
    stdout.writeln();

    stdout.writeln(
      'Merged candidate CSV created:',
    );
    stdout.writeln(
      outputFile.path,
    );

    if (!options.install) {
      stdout.writeln();
      stdout.writeln(
        'OVERRIDES APPLIED SUCCESSFULLY',
      );
      stdout.writeln(
        'The app data has not been replaced.',
      );
      stdout.writeln(
        'Review the merged CSV before using '
        '--install.',
      );
      return;
    }

    stdout.writeln();
    stdout.writeln(
      'Installing the merged calendar...',
    );

    final bool installed =
        await _installMergedCalendar(
      year: options.year,
      mergedCsvText: csvText,
    );

    if (!installed) {
      throw const OverrideException(
        'The merged calendar could not be '
        'installed. The previous verified CSV '
        'was restored.',
      );
    }

    stdout.writeln();
    stdout.writeln(
      'OVERRIDES APPLIED AND INSTALLED '
      'SUCCESSFULLY',
    );
  } on OverrideException catch (error) {
    stderr.writeln();
    stderr.writeln(
      'OVERRIDE PROCESS FAILED',
    );
    stderr.writeln(error.message);
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln();
    stderr.writeln(
      'OVERRIDE PROCESS FAILED',
    );
    stderr.writeln(error.message);
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln();
    stderr.writeln(
      'OVERRIDE PROCESS FAILED',
    );
    stderr.writeln(error.message);
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr.writeln();
    stderr.writeln(
      'OVERRIDE PROCESS FAILED',
    );
    stderr.writeln(error);
    stderr.writeln();
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Map<String, DayData> _loadFetchedCsv({
  required File file,
  required int expectedYear,
}) {
  final String csvText = file.readAsStringSync(
    encoding: utf8,
  );

  final List<List<String>> rows =
      CsvParser.parse(csvText);

  if (rows.isEmpty) {
    throw const OverrideException(
      'The fetched CSV file is empty.',
    );
  }

  final HeaderIndex headerIndex =
      HeaderIndex.fromRow(rows.first);

  final Map<String, DayData> daysByDate =
      <String, DayData>{};

  for (int rowIndex = 1;
      rowIndex < rows.length;
      rowIndex++) {
    final List<String> row = rows[rowIndex];

    if (_isBlankRow(row)) {
      continue;
    }

    final int csvLineNumber = rowIndex + 1;

    final FetchedCsvRow fetchedRow =
        FetchedCsvRow.parse(
      row: row,
      headerIndex: headerIndex,
      csvLineNumber: csvLineNumber,
      expectedYear: expectedYear,
    );

    final DayData day = daysByDate.putIfAbsent(
      fetchedRow.date,
      () => DayData(
        date: fetchedRow.date,
        liturgicalDay:
            fetchedRow.liturgicalDay,
      ),
    );

    day.confirmLiturgicalDay(
      fetchedRow.liturgicalDay,
      csvLineNumber,
    );

    day.addFetchedRow(
      fetchedRow,
      csvLineNumber,
    );
  }

  if (daysByDate.isEmpty) {
    throw const OverrideException(
      'The fetched CSV contains no '
      'lectionary dates.',
    );
  }

  for (final DayData day in daysByDate.values) {
    day.validateSourceOrders();
  }

  return daysByDate;
}

ApplySummary _applyOverrides({
  required Map<String, DayData> daysByDate,
  required OverrideDocument overrides,
}) {
  int overrideDateCount = 0;
  int replacedKindCount = 0;
  int replacementReadingCount = 0;

  final List<String> sortedDates =
      overrides.days.keys.toList()
        ..sort();

  for (final String date in sortedDates) {
    final DayOverride dayOverride =
        overrides.days[date]!;

    final DayData? day = daysByDate[date];

    if (day == null) {
      throw OverrideException(
        'The override file contains $date, '
        'but that date is missing from the '
        'fetched CSV.\n\n'
        'Rerun the fetcher with partial dates '
        'included:\n'
        'dart run tool/fetch_lectionary.dart '
        '${overrides.year} '
        '--include-partial --force',
      );
    }

    if (dayOverride.liturgicalDay != null) {
      day.liturgicalDay =
          dayOverride.liturgicalDay!;
    }

    for (final MapEntry<String,
            List<ReadingData>>
        entry
        in dayOverride.replaceReadings.entries) {
      day.replaceReadingsOfKind(
        kind: entry.key,
        replacements: entry.value,
      );

      replacedKindCount++;
      replacementReadingCount +=
          entry.value.length;
    }

    overrideDateCount++;
  }

  for (final DayData day in daysByDate.values) {
    day.validateFinalReadings();
  }

  return ApplySummary(
    overrideDateCount: overrideDateCount,
    replacedKindCount: replacedKindCount,
    replacementReadingCount:
        replacementReadingCount,
  );
}

void _validateCalendarCoverage({
  required int year,
  required Map<String, DayData> daysByDate,
  required bool allowIncomplete,
}) {
  final DateTime startDate = DateTime.utc(
    year,
    1,
    1,
  );

  final DateTime endExclusive = DateTime.utc(
    year + 1,
    1,
    1,
  );

  final int expectedDateCount =
      endExclusive.difference(startDate).inDays;

  final List<String> missingDates = <String>[];

  DateTime currentDate = startDate;

  while (currentDate.isBefore(endExclusive)) {
    final String dateText = _formatDate(
      currentDate,
    );

    if (!daysByDate.containsKey(dateText)) {
      missingDates.add(dateText);
    }

    currentDate = currentDate.add(
      const Duration(days: 1),
    );
  }

  if (missingDates.isEmpty &&
      daysByDate.length == expectedDateCount) {
    return;
  }

  if (allowIncomplete) {
    stderr.writeln(
      'WARNING: The merged calendar contains '
      '${daysByDate.length} of '
      '$expectedDateCount expected dates.',
    );
    return;
  }

  final String visibleMissingDates =
      missingDates.take(12).join(', ');

  final String additionalText =
      missingDates.length > 12
          ? ' and ${missingDates.length - 12} more'
          : '';

  throw OverrideException(
    'The merged calendar is incomplete.\n'
    'Expected dates: $expectedDateCount\n'
    'Dates found: ${daysByDate.length}\n'
    'Missing: $visibleMissingDates'
    '$additionalText\n\n'
    'The fetched CSV must include partial '
    'rows for dates containing source errors.\n'
    'Run:\n'
    'dart run tool/fetch_lectionary.dart '
    '$year --include-partial --force',
  );
}

List<CsvOutputRow> _buildOutputRows(
  Map<String, DayData> daysByDate,
) {
  final List<String> sortedDates =
      daysByDate.keys.toList()
        ..sort();

  final List<CsvOutputRow> outputRows =
      <CsvOutputRow>[];

  for (final String date in sortedDates) {
    final DayData day = daysByDate[date]!;

    final List<ReadingData> readings =
        day.sortedReadings();

    for (int readingIndex = 0;
        readingIndex < readings.length;
        readingIndex++) {
      final ReadingData reading =
          readings[readingIndex];

      for (int rangeIndex = 0;
          rangeIndex < reading.ranges.length;
          rangeIndex++) {
        final ScriptureRangeData range =
            reading.ranges[rangeIndex];

        outputRows.add(
          CsvOutputRow(
            date: day.date,
            liturgicalDay:
                day.liturgicalDay,
            readingOrder: readingIndex + 1,
            kind: reading.kind,
            title: reading.title,
            displayReference:
                reading.displayReference,
            response: reading.response,
            choiceGroup:
                reading.choiceGroup,
            choiceLabel:
                reading.choiceLabel,
            rangeOrder: rangeIndex + 1,
            bookCode: range.bookCode,
            chapter: range.chapter,
            startVerse: range.startVerse,
            endVerse: range.endVerse,
            displayVerseOffset:
                range.displayVerseOffset,
          ),
        );
      }
    }
  }

  return outputRows;
}

String _buildCsv(
  List<CsvOutputRow> rows,
) {
  final StringBuffer csv = StringBuffer();

  csv.writeln(
    _csvHeaders
        .map(_escapeCsvField)
        .join(','),
  );

  for (final CsvOutputRow row in rows) {
    csv.writeln(
      row
          .toValues()
          .map(_escapeCsvField)
          .join(','),
    );
  }

  return csv.toString();
}

int _countReadings(
  Map<String, DayData> daysByDate,
) {
  int count = 0;

  for (final DayData day in daysByDate.values) {
    count += day.readings.length;
  }

  return count;
}

Future<bool> _installMergedCalendar({
  required int year,
  required String mergedCsvText,
}) async {
  final File canonicalCsv = File(
    '$_sourceDirectory/$year.csv',
  );

  final bool previouslyExisted =
      canonicalCsv.existsSync();

  final String? previousContent =
      previouslyExisted
          ? canonicalCsv.readAsStringSync(
              encoding: utf8,
            )
          : null;

  canonicalCsv.parent.createSync(
    recursive: true,
  );

  canonicalCsv.writeAsStringSync(
    mergedCsvText,
    encoding: utf8,
    flush: true,
  );

  try {
    final File importerFile = File(
      _importerPath,
    );

    if (!importerFile.existsSync()) {
      throw const OverrideException(
        'The yearly importer was not found:\n'
        'tool/import_lectionary.dart',
      );
    }

    final ProcessResult result =
        await Process.run(
      Platform.resolvedExecutable,
      <String>[
        'run',
        _importerPath,
        year.toString(),
      ],
      workingDirectory:
          Directory.current.path,
    );

    final String standardOutput =
        result.stdout.toString();

    final String standardError =
        result.stderr.toString();

    if (standardOutput.isNotEmpty) {
      stdout.write(standardOutput);
    }

    if (standardError.isNotEmpty) {
      stderr.write(standardError);
    }

    if (result.exitCode == 0) {
      return true;
    }

    _restoreCanonicalCsv(
      file: canonicalCsv,
      previouslyExisted: previouslyExisted,
      previousContent: previousContent,
    );

    return false;
  } catch (_) {
    _restoreCanonicalCsv(
      file: canonicalCsv,
      previouslyExisted: previouslyExisted,
      previousContent: previousContent,
    );

    rethrow;
  }
}

void _restoreCanonicalCsv({
  required File file,
  required bool previouslyExisted,
  required String? previousContent,
}) {
  if (previouslyExisted &&
      previousContent != null) {
    file.writeAsStringSync(
      previousContent,
      encoding: utf8,
      flush: true,
    );
    return;
  }

  if (file.existsSync()) {
    file.deleteSync();
  }
}

bool _isBlankRow(List<String> row) {
  return row.every(
    (String value) => value.trim().isEmpty,
  );
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

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime? _parseStrictDate(String value) {
  final Match? match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})$',
  ).firstMatch(value);

  if (match == null) {
    return null;
  }

  final int? year = int.tryParse(
    match.group(1)!,
  );

  final int? month = int.tryParse(
    match.group(2)!,
  );

  final int? day = int.tryParse(
    match.group(3)!,
  );

  if (year == null ||
      month == null ||
      day == null) {
    return null;
  }

  final DateTime date = DateTime.utc(
    year,
    month,
    day,
  );

  if (date.year != year ||
      date.month != month ||
      date.day != day) {
    return null;
  }

  return date;
}

String? _optionalText(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw const OverrideException(
      'An optional text value in the override '
      'file is not valid text.',
    );
  }

  final String trimmed = value.trim();

  return trimmed.isEmpty ? null : trimmed;
}

String _requiredText(
  Object? value,
  String location,
) {
  if (value is! String ||
      value.trim().isEmpty) {
    throw OverrideException(
      '$location must contain text.',
    );
  }

  return value.trim();
}

int _requiredInteger(
  Object? value,
  String location,
) {
  if (value is int) {
    return value;
  }

  if (value is num &&
      value.isFinite &&
      value == value.roundToDouble()) {
    return value.toInt();
  }

  throw OverrideException(
    '$location must contain an integer.',
  );
}

Map<String, dynamic> _requiredMap(
  Object? value,
  String location,
) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map<dynamic, dynamic>) {
    return value.map(
      (
        dynamic key,
        dynamic item,
      ) =>
          MapEntry<String, dynamic>(
        key.toString(),
        item,
      ),
    );
  }

  throw OverrideException(
    '$location must be a JSON object.',
  );
}

void _printUsage() {
  stdout.writeln(
    'My Catholic Day Lectionary Override Tool',
  );
  stdout.writeln();
  stdout.writeln(
    'Merge reviewed overrides into a fetched '
    'candidate CSV:',
  );
  stdout.writeln(
    '  dart run '
    'tool/apply_lectionary_overrides.dart 2026',
  );
  stdout.writeln();
  stdout.writeln(
    'Install the merged calendar into the app:',
  );
  stdout.writeln(
    '  dart run '
    'tool/apply_lectionary_overrides.dart '
    '2026 --force --install',
  );
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln(
    '  --input PATH       Fetched candidate CSV.',
  );
  stdout.writeln(
    '  --overrides PATH   Override JSON file.',
  );
  stdout.writeln(
    '  --output PATH      Merged candidate CSV.',
  );
  stdout.writeln(
    '  --allow-incomplete Permit fewer than a '
    'full year of dates.',
  );
  stdout.writeln(
    '  --install          Replace the canonical '
    'CSV and generate app JSON.',
  );
  stdout.writeln(
    '  --force            Replace an existing '
    'merged CSV.',
  );
  stdout.writeln(
    '  --help             Show this help.',
  );
}

class OverrideOptions {
  const OverrideOptions({
    required this.year,
    required this.inputPath,
    required this.overridePath,
    required this.outputPath,
    required this.allowIncomplete,
    required this.install,
    required this.force,
    required this.showHelp,
  });

  final int year;
  final String inputPath;
  final String overridePath;
  final String outputPath;
  final bool allowIncomplete;
  final bool install;
  final bool force;
  final bool showHelp;

  static OverrideOptions parse(
    List<String> arguments,
  ) {
    if (arguments.contains('--help') ||
        arguments.contains('-h')) {
      final int currentYear =
          DateTime.now().year;

      return OverrideOptions(
        year: currentYear,
        inputPath: '',
        overridePath: '',
        outputPath: '',
        allowIncomplete: false,
        install: false,
        force: false,
        showHelp: true,
      );
    }

    int? year;
    String? inputPath;
    String? overridePath;
    String? outputPath;

    bool allowIncomplete = false;
    bool install = false;
    bool force = false;

    for (int index = 0;
        index < arguments.length;
        index++) {
      final String argument = arguments[index];

      if (argument == '--allow-incomplete') {
        allowIncomplete = true;
        continue;
      }

      if (argument == '--install') {
        install = true;
        continue;
      }

      if (argument == '--force') {
        force = true;
        continue;
      }

      if (argument == '--input') {
        if (index + 1 >= arguments.length) {
          throw const OverrideException(
            '--input requires a file path.',
          );
        }

        inputPath = arguments[++index];
        continue;
      }

      if (argument.startsWith('--input=')) {
        inputPath = argument.substring(
          '--input='.length,
        );
        continue;
      }

      if (argument == '--overrides') {
        if (index + 1 >= arguments.length) {
          throw const OverrideException(
            '--overrides requires a file path.',
          );
        }

        overridePath = arguments[++index];
        continue;
      }

      if (argument.startsWith(
        '--overrides=',
      )) {
        overridePath = argument.substring(
          '--overrides='.length,
        );
        continue;
      }

      if (argument == '--output') {
        if (index + 1 >= arguments.length) {
          throw const OverrideException(
            '--output requires a file path.',
          );
        }

        outputPath = arguments[++index];
        continue;
      }

      if (argument.startsWith('--output=')) {
        outputPath = argument.substring(
          '--output='.length,
        );
        continue;
      }

      if (argument.startsWith('-')) {
        throw OverrideException(
          'Unknown option: $argument',
        );
      }

      if (year != null) {
        throw const OverrideException(
          'Only one year may be supplied.',
        );
      }

      year = int.tryParse(argument);

      if (year == null ||
          year < 1900 ||
          year > 3000) {
        throw OverrideException(
          'Invalid year: $argument',
        );
      }
    }

    if (year == null) {
      throw const OverrideException(
        'A year is required.\n\n'
        'Example:\n'
        'dart run '
        'tool/apply_lectionary_overrides.dart '
        '2026',
      );
    }

    return OverrideOptions(
      year: year,
      inputPath: inputPath ??
          '$_sourceDirectory/'
              '${year}_fetched.csv',
      overridePath: overridePath ??
          '$_sourceDirectory/'
              '${year}_overrides.json',
      outputPath: outputPath ??
          '$_sourceDirectory/'
              '${year}_merged.csv',
      allowIncomplete: allowIncomplete,
      install: install,
      force: force,
      showHelp: false,
    );
  }
}

class OverrideDocument {
  const OverrideDocument({
    required this.year,
    required this.days,
  });

  final int year;
  final Map<String, DayOverride> days;

  static OverrideDocument load({
    required File file,
    required int expectedYear,
  }) {
    final Object? decoded = jsonDecode(
      file.readAsStringSync(
        encoding: utf8,
      ),
    );

    final Map<String, dynamic> root =
        _requiredMap(
      decoded,
      'The override file',
    );

    final int schemaVersion =
        _requiredInteger(
      root['schemaVersion'],
      'schemaVersion',
    );

    if (schemaVersion !=
        _supportedOverrideSchemaVersion) {
      throw OverrideException(
        'The override file uses schemaVersion '
        '$schemaVersion. The supported version '
        'is $_supportedOverrideSchemaVersion.',
      );
    }

    final int year = _requiredInteger(
      root['year'],
      'year',
    );

    if (year != expectedYear) {
      throw OverrideException(
        'The override file is for $year, '
        'but this run is for $expectedYear.',
      );
    }

    final Map<String, dynamic> daysMap =
        _requiredMap(
      root['days'],
      'days',
    );

    final Map<String, DayOverride> days =
        <String, DayOverride>{};

    for (final MapEntry<String, dynamic> entry
        in daysMap.entries) {
      final String date = entry.key.trim();

      final DateTime? parsedDate =
          _parseStrictDate(date);

      if (parsedDate == null ||
          parsedDate.year != expectedYear) {
        throw OverrideException(
          'The override date "$date" is invalid '
          'or is not within $expectedYear.',
        );
      }

      days[date] = DayOverride.fromJson(
        date: date,
        json: _requiredMap(
          entry.value,
          '$date override',
        ),
      );
    }

    if (days.isEmpty) {
      throw const OverrideException(
        'The override file contains no dates.',
      );
    }

    return OverrideDocument(
      year: year,
      days: days,
    );
  }
}

class DayOverride {
  const DayOverride({
    required this.liturgicalDay,
    required this.replaceReadings,
  });

  final String? liturgicalDay;

  final Map<String, List<ReadingData>>
      replaceReadings;

  static DayOverride fromJson({
    required String date,
    required Map<String, dynamic> json,
  }) {
    final String? liturgicalDay =
        _optionalText(
      json['liturgicalDay'],
    );

    final Map<String, dynamic> replacementMap =
        _requiredMap(
      json['replaceReadings'],
      '$date replaceReadings',
    );

    final Map<String, List<ReadingData>>
        replacements =
        <String, List<ReadingData>>{};

    for (final MapEntry<String, dynamic> entry
        in replacementMap.entries) {
      final String kind = entry.key.trim();

      if (!_allowedReadingKinds.contains(kind)) {
        throw OverrideException(
          '$date contains an unsupported '
          'replacement kind: $kind',
        );
      }

      final Object? listValue = entry.value;

      if (listValue is! List<dynamic> ||
          listValue.isEmpty) {
        throw OverrideException(
          '$date replacement kind $kind must '
          'contain at least one reading.',
        );
      }

      final List<ReadingData> readings =
          <ReadingData>[];

      for (int index = 0;
          index < listValue.length;
          index++) {
        final ReadingData reading =
            ReadingData.fromOverrideJson(
          json: _requiredMap(
            listValue[index],
            '$date $kind replacement '
            '${index + 1}',
          ),
          expectedKind: kind,
          sourceOrder: index + 1,
          location:
              '$date $kind replacement '
              '${index + 1}',
        );

        readings.add(reading);
      }

      replacements[kind] = readings;
    }

    if (replacements.isEmpty) {
      throw OverrideException(
        '$date contains no replacement '
        'readings.',
      );
    }

    return DayOverride(
      liturgicalDay: liturgicalDay,
      replaceReadings: replacements,
    );
  }
}

class DayData {
  DayData({
    required this.date,
    required this.liturgicalDay,
  });

  final String date;

  String liturgicalDay;

  final Map<int, ReadingData> _readingsByOrder =
      <int, ReadingData>{};

  List<ReadingData> get readings =>
      _readingsByOrder.values.toList();

  void confirmLiturgicalDay(
    String otherLiturgicalDay,
    int csvLineNumber,
  ) {
    if (liturgicalDay != otherLiturgicalDay) {
      throw OverrideException(
        'CSV line $csvLineNumber gives $date '
        'a different liturgicalDay.\n'
        'Expected: $liturgicalDay\n'
        'Found: $otherLiturgicalDay',
      );
    }
  }

  void addFetchedRow(
    FetchedCsvRow row,
    int csvLineNumber,
  ) {
    final ReadingData reading =
        _readingsByOrder.putIfAbsent(
      row.readingOrder,
      () => ReadingData(
        sourceOrder: row.readingOrder,
        kind: row.kind,
        title: row.title,
        displayReference:
            row.displayReference,
        response: row.response,
        choiceGroup: row.choiceGroup,
        choiceLabel: row.choiceLabel,
        ranges: <ScriptureRangeData>[],
      ),
    );

    reading.confirmMetadata(
      row,
      csvLineNumber,
    );

    reading.addFetchedRange(
      order: row.rangeOrder,
      range: ScriptureRangeData(
        bookCode: row.bookCode,
        chapter: row.chapter,
        startVerse: row.startVerse,
        endVerse: row.endVerse,
        displayVerseOffset:
            row.displayVerseOffset,
      ),
      csvLineNumber: csvLineNumber,
    );
  }

  void replaceReadingsOfKind({
    required String kind,
    required List<ReadingData> replacements,
  }) {
    final List<int> ordersToRemove =
        _readingsByOrder.entries
            .where(
              (
                MapEntry<int, ReadingData>
                    entry,
              ) =>
                  entry.value.kind == kind,
            )
            .map(
              (
                MapEntry<int, ReadingData>
                    entry,
              ) =>
                  entry.key,
            )
            .toList();

    for (final int order in ordersToRemove) {
      _readingsByOrder.remove(order);
    }

    int temporaryOrder = 100000;

    while (_readingsByOrder.containsKey(
      temporaryOrder,
    )) {
      temporaryOrder++;
    }

    for (final ReadingData replacement
        in replacements) {
      while (_readingsByOrder.containsKey(
        temporaryOrder,
      )) {
        temporaryOrder++;
      }

      _readingsByOrder[temporaryOrder] =
          replacement;

      temporaryOrder++;
    }
  }

  void validateSourceOrders() {
    if (_readingsByOrder.isEmpty) {
      throw OverrideException(
        '$date contains no fetched readings.',
      );
    }

    for (final ReadingData reading
        in _readingsByOrder.values) {
      reading.finalizeFetchedRanges(date);
    }
  }

  void validateFinalReadings() {
    if (_readingsByOrder.isEmpty) {
      throw OverrideException(
        '$date contains no readings after '
        'overrides were applied.',
      );
    }

    for (final ReadingData reading
        in _readingsByOrder.values) {
      reading.validateFinal(
        '$date ${reading.kind}',
      );
    }
  }

  List<ReadingData> sortedReadings() {
    final List<ReadingData> sorted =
        _readingsByOrder.values.toList();

    sorted.sort(
      (
        ReadingData first,
        ReadingData second,
      ) {
        final int firstKindOrder =
            _readingKindOrder[first.kind] ?? 999;

        final int secondKindOrder =
            _readingKindOrder[second.kind] ??
                999;

        final int kindComparison =
            firstKindOrder.compareTo(
          secondKindOrder,
        );

        if (kindComparison != 0) {
          return kindComparison;
        }

        return first.sourceOrder.compareTo(
          second.sourceOrder,
        );
      },
    );

    return sorted;
  }
}

class ReadingData {
  ReadingData({
    required this.sourceOrder,
    required this.kind,
    required this.title,
    required this.displayReference,
    required this.response,
    required this.choiceGroup,
    required this.choiceLabel,
    required this.ranges,
  });

  final int sourceOrder;
  final String kind;
  final String title;
  final String displayReference;
  final String? response;
  final String? choiceGroup;
  final String? choiceLabel;

  List<ScriptureRangeData> ranges;

  final Map<int, ScriptureRangeData>
      _fetchedRangesByOrder =
      <int, ScriptureRangeData>{};

  static ReadingData fromOverrideJson({
    required Map<String, dynamic> json,
    required String expectedKind,
    required int sourceOrder,
    required String location,
  }) {
    final String kind = _requiredText(
      json['kind'],
      '$location kind',
    );

    if (kind != expectedKind) {
      throw OverrideException(
        '$location is listed under '
        '$expectedKind but says its kind is '
        '$kind.',
      );
    }

    if (!_allowedReadingKinds.contains(kind)) {
      throw OverrideException(
        '$location contains an unsupported '
        'reading kind: $kind',
      );
    }

    final String? choiceGroup =
        _optionalText(
      json['choiceGroup'],
    );

    final String? choiceLabel =
        _optionalText(
      json['choiceLabel'],
    );

    if ((choiceGroup == null) !=
        (choiceLabel == null)) {
      throw OverrideException(
        '$location must provide both '
        'choiceGroup and choiceLabel, or leave '
        'both null.',
      );
    }

    final Object? rangesValue =
        json['ranges'];

    if (rangesValue is! List<dynamic> ||
        rangesValue.isEmpty) {
      throw OverrideException(
        '$location must contain at least one '
        'Scripture range.',
      );
    }

    final List<ScriptureRangeData> ranges =
        <ScriptureRangeData>[];

    for (int index = 0;
        index < rangesValue.length;
        index++) {
      ranges.add(
        ScriptureRangeData.fromJson(
          json: _requiredMap(
            rangesValue[index],
            '$location range ${index + 1}',
          ),
          location:
              '$location range ${index + 1}',
        ),
      );
    }

    return ReadingData(
      sourceOrder: sourceOrder,
      kind: kind,
      title: _requiredText(
        json['title'],
        '$location title',
      ),
      displayReference: _requiredText(
        json['displayReference'],
        '$location displayReference',
      ),
      response: _optionalText(
        json['response'],
      ),
      choiceGroup: choiceGroup,
      choiceLabel: choiceLabel,
      ranges: ranges,
    );
  }

  void confirmMetadata(
    FetchedCsvRow row,
    int csvLineNumber,
  ) {
    if (kind != row.kind ||
        title != row.title ||
        displayReference !=
            row.displayReference ||
        response != row.response ||
        choiceGroup != row.choiceGroup ||
        choiceLabel != row.choiceLabel) {
      throw OverrideException(
        'CSV line $csvLineNumber contains '
        'different metadata for readingOrder '
        '${row.readingOrder} on ${row.date}.',
      );
    }
  }

  void addFetchedRange({
    required int order,
    required ScriptureRangeData range,
    required int csvLineNumber,
  }) {
    if (_fetchedRangesByOrder.containsKey(
      order,
    )) {
      throw OverrideException(
        'CSV line $csvLineNumber duplicates '
        'rangeOrder $order.',
      );
    }

    _fetchedRangesByOrder[order] = range;
  }

  void finalizeFetchedRanges(String date) {
    if (_fetchedRangesByOrder.isEmpty) {
      if (ranges.isEmpty) {
        throw OverrideException(
          '$date readingOrder $sourceOrder '
          'contains no Scripture ranges.',
        );
      }

      return;
    }

    final List<int> sortedOrders =
        _fetchedRangesByOrder.keys.toList()
          ..sort();

    final List<ScriptureRangeData>
        sortedRanges =
        <ScriptureRangeData>[];

    for (int index = 0;
        index < sortedOrders.length;
        index++) {
      final int expectedOrder = index + 1;

      if (sortedOrders[index] != expectedOrder) {
        throw OverrideException(
          '$date readingOrder $sourceOrder '
          'is missing rangeOrder '
          '$expectedOrder.',
        );
      }

      sortedRanges.add(
        _fetchedRangesByOrder[
            sortedOrders[index]]!,
      );
    }

    ranges = sortedRanges;
  }

  void validateFinal(String location) {
    if (!_allowedReadingKinds.contains(kind)) {
      throw OverrideException(
        '$location contains an unsupported '
        'kind: $kind',
      );
    }

    if (title.trim().isEmpty) {
      throw OverrideException(
        '$location has no title.',
      );
    }

    if (displayReference.trim().isEmpty) {
      throw OverrideException(
        '$location has no displayReference.',
      );
    }

    if ((choiceGroup == null) !=
        (choiceLabel == null)) {
      throw OverrideException(
        '$location must provide both '
        'choiceGroup and choiceLabel, or leave '
        'both blank.',
      );
    }

    if (ranges.isEmpty) {
      throw OverrideException(
        '$location contains no Scripture '
        'ranges.',
      );
    }

    for (int index = 0;
        index < ranges.length;
        index++) {
      ranges[index].validate(
        '$location range ${index + 1}',
      );
    }
  }
}

class ScriptureRangeData {
  const ScriptureRangeData({
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

  static ScriptureRangeData fromJson({
    required Map<String, dynamic> json,
    required String location,
  }) {
    final ScriptureRangeData range =
        ScriptureRangeData(
      bookCode: _requiredText(
        json['bookCode'],
        '$location bookCode',
      ).toUpperCase(),
      chapter: _requiredInteger(
        json['chapter'],
        '$location chapter',
      ),
      startVerse: _requiredInteger(
        json['startVerse'],
        '$location startVerse',
      ),
      endVerse: _requiredInteger(
        json['endVerse'],
        '$location endVerse',
      ),
      displayVerseOffset:
          _requiredInteger(
        json['displayVerseOffset'],
        '$location displayVerseOffset',
      ),
    );

    range.validate(location);

    return range;
  }

  void validate(String location) {
    if (!RegExp(r'^[A-Z0-9]{2,4}$')
        .hasMatch(bookCode)) {
      throw OverrideException(
        '$location has an invalid bookCode: '
        '$bookCode',
      );
    }

    if (chapter < 1) {
      throw OverrideException(
        '$location has an invalid chapter: '
        '$chapter',
      );
    }

    if (startVerse < 1) {
      throw OverrideException(
        '$location has an invalid startVerse: '
        '$startVerse',
      );
    }

    if (endVerse < startVerse) {
      throw OverrideException(
        '$location ends at verse $endVerse '
        'before start verse $startVerse.',
      );
    }
  }
}

class FetchedCsvRow {
  const FetchedCsvRow({
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

  static FetchedCsvRow parse({
    required List<String> row,
    required HeaderIndex headerIndex,
    required int csvLineNumber,
    required int expectedYear,
  }) {
    String requiredText(String header) {
      final String value = headerIndex.value(
        row,
        header,
      );

      if (value.isEmpty) {
        throw OverrideException(
          'CSV line $csvLineNumber has no '
          '$header.',
        );
      }

      return value;
    }

    String? optionalText(String header) {
      final String value = headerIndex.value(
        row,
        header,
      );

      return value.isEmpty ? null : value;
    }

    int requiredPositiveInteger(
      String header,
    ) {
      final String text = requiredText(header);
      final int? value = int.tryParse(text);

      if (value == null || value < 1) {
        throw OverrideException(
          'CSV line $csvLineNumber has an '
          'invalid $header: $text',
        );
      }

      return value;
    }

    final String date = requiredText('date');

    final DateTime? parsedDate =
        _parseStrictDate(date);

    if (parsedDate == null ||
        parsedDate.year != expectedYear) {
      throw OverrideException(
        'CSV line $csvLineNumber has an invalid '
        'date for $expectedYear: $date',
      );
    }

    final String kind = requiredText('kind');

    if (!_allowedReadingKinds.contains(kind)) {
      throw OverrideException(
        'CSV line $csvLineNumber has an '
        'unsupported reading kind: $kind',
      );
    }

    final String? choiceGroup =
        optionalText('choiceGroup');

    final String? choiceLabel =
        optionalText('choiceLabel');

    if ((choiceGroup == null) !=
        (choiceLabel == null)) {
      throw OverrideException(
        'CSV line $csvLineNumber must provide '
        'both choiceGroup and choiceLabel, or '
        'leave both blank.',
      );
    }

    final int startVerse =
        requiredPositiveInteger(
      'startVerse',
    );

    final int endVerse =
        requiredPositiveInteger(
      'endVerse',
    );

    if (endVerse < startVerse) {
      throw OverrideException(
        'CSV line $csvLineNumber ends at verse '
        '$endVerse before start verse '
        '$startVerse.',
      );
    }

    final String offsetText =
        headerIndex.value(
      row,
      'displayVerseOffset',
    );

    final int? displayVerseOffset =
        offsetText.isEmpty
            ? 0
            : int.tryParse(offsetText);

    if (displayVerseOffset == null) {
      throw OverrideException(
        'CSV line $csvLineNumber has an invalid '
        'displayVerseOffset: $offsetText',
      );
    }

    return FetchedCsvRow(
      date: date,
      liturgicalDay:
          requiredText('liturgicalDay'),
      readingOrder:
          requiredPositiveInteger(
        'readingOrder',
      ),
      kind: kind,
      title: requiredText('title'),
      displayReference:
          requiredText('displayReference'),
      response: optionalText('response'),
      choiceGroup: choiceGroup,
      choiceLabel: choiceLabel,
      rangeOrder:
          requiredPositiveInteger(
        'rangeOrder',
      ),
      bookCode: requiredText(
        'bookCode',
      ).toUpperCase(),
      chapter:
          requiredPositiveInteger('chapter'),
      startVerse: startVerse,
      endVerse: endVerse,
      displayVerseOffset:
          displayVerseOffset,
    );
  }
}

class CsvOutputRow {
  const CsvOutputRow({
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

class HeaderIndex {
  HeaderIndex(this._indexes);

  final Map<String, int> _indexes;

  static HeaderIndex fromRow(
    List<String> headerRow,
  ) {
    final Map<String, int> indexes =
        <String, int>{};

    for (int index = 0;
        index < headerRow.length;
        index++) {
      final String normalizedHeader =
          _normalizeHeader(
        headerRow[index],
      );

      if (normalizedHeader.isEmpty) {
        continue;
      }

      if (indexes.containsKey(
        normalizedHeader,
      )) {
        throw OverrideException(
          'The CSV contains the header '
          '"${headerRow[index]}" more than once.',
        );
      }

      indexes[normalizedHeader] = index;
    }

    for (final String requiredHeader
        in _csvHeaders) {
      final String normalizedRequired =
          _normalizeHeader(
        requiredHeader,
      );

      if (!indexes.containsKey(
        normalizedRequired,
      )) {
        throw OverrideException(
          'The CSV is missing the required '
          'column: $requiredHeader',
        );
      }
    }

    return HeaderIndex(indexes);
  }

  String value(
    List<String> row,
    String header,
  ) {
    final int? index = _indexes[
        _normalizeHeader(header)];

    if (index == null || index >= row.length) {
      return '';
    }

    return row[index].trim();
  }
}

String _normalizeHeader(String value) {
  return value
      .replaceFirst('\uFEFF', '')
      .trim()
      .toLowerCase()
      .replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
}

class CsvParser {
  static List<List<String>> parse(
    String input,
  ) {
    final List<List<String>> rows =
        <List<String>>[];

    List<String> currentRow = <String>[];
    StringBuffer currentField = StringBuffer();

    bool insideQuotes = false;
    bool afterClosingQuote = false;

    void finishField() {
      currentRow.add(
        currentField.toString(),
      );

      currentField = StringBuffer();
      afterClosingQuote = false;
    }

    void finishRow() {
      finishField();
      rows.add(currentRow);
      currentRow = <String>[];
    }

    for (int index = 0;
        index < input.length;
        index++) {
      final String character = input[index];

      if (insideQuotes) {
        if (character == '"') {
          final bool escapedQuote =
              index + 1 < input.length &&
              input[index + 1] == '"';

          if (escapedQuote) {
            currentField.write('"');
            index++;
          } else {
            insideQuotes = false;
            afterClosingQuote = true;
          }

          continue;
        }

        if (character == '\r') {
          final bool hasLineFeed =
              index + 1 < input.length &&
              input[index + 1] == '\n';

          if (hasLineFeed) {
            index++;
          }

          currentField.write('\n');
          continue;
        }

        currentField.write(character);
        continue;
      }

      if (afterClosingQuote) {
        if (character == ',') {
          finishField();
          continue;
        }

        if (character == '\r' ||
            character == '\n') {
          if (character == '\r' &&
              index + 1 < input.length &&
              input[index + 1] == '\n') {
            index++;
          }

          finishRow();
          continue;
        }

        if (character.trim().isEmpty) {
          continue;
        }

        throw const OverrideException(
          'The CSV contains unexpected text '
          'after a closing quote.',
        );
      }

      if (character == '"' &&
          currentField.isEmpty) {
        insideQuotes = true;
        continue;
      }

      if (character == ',') {
        finishField();
        continue;
      }

      if (character == '\r' ||
          character == '\n') {
        if (character == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index++;
        }

        finishRow();
        continue;
      }

      currentField.write(character);
    }

    if (insideQuotes) {
      throw const OverrideException(
        'The CSV ends inside a quoted field.',
      );
    }

    if (currentRow.isNotEmpty ||
        currentField.isNotEmpty ||
        afterClosingQuote) {
      finishRow();
    }

    return rows;
  }
}

class ApplySummary {
  const ApplySummary({
    required this.overrideDateCount,
    required this.replacedKindCount,
    required this.replacementReadingCount,
  });

  final int overrideDateCount;
  final int replacedKindCount;
  final int replacementReadingCount;
}

class OverrideException implements Exception {
  const OverrideException(this.message);

  final String message;

  @override
  String toString() => message;
}