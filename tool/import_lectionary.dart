import 'dart:convert';
import 'dart:io';

const String _defaultSourceDirectory =
    'tool/source/lectionary';

const String _defaultOutputDirectory =
    'assets/data/lectionary';

const String _validatorPath =
    'tool/validate_lectionary.dart';

const int _schemaVersion = 1;

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

Future<void> main(List<String> arguments) async {
  try {
    final ImportOptions options = ImportOptions.parse(
      arguments,
    );

    if (options.showHelp) {
      _printUsage();
      return;
    }

    if (options.createTemplate) {
      _createTemplate(options);
      return;
    }

    if (options.exportExisting) {
      _exportExistingJson(options);
      return;
    }

    await _importCsv(options);
  } on ImportException catch (error) {
    stderr.writeln();
    stderr.writeln('IMPORT FAILED');
    stderr.writeln(error.message);
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln();
    stderr.writeln('IMPORT FAILED');
    stderr.writeln(error.message);
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln();
    stderr.writeln('IMPORT FAILED');
    stderr.writeln(error.message);
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr.writeln();
    stderr.writeln('IMPORT FAILED');
    stderr.writeln(error);
    stderr.writeln();
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Future<void> _importCsv(
  ImportOptions options,
) async {
  final File sourceFile = File(
    options.sourcePath,
  );

  final File outputFile = File(
    options.outputPath,
  );

  stdout.writeln(
    'My Catholic Day Lectionary Importer',
  );
  stdout.writeln(
    '==================================',
  );
  stdout.writeln();
  stdout.writeln(
    'Source: ${sourceFile.path}',
  );
  stdout.writeln(
    'Output: ${outputFile.path}',
  );
  stdout.writeln();

  if (!sourceFile.existsSync()) {
    throw ImportException(
      'The source CSV file does not exist:\n'
      '${sourceFile.path}\n\n'
      'Create it with:\n'
      'dart run tool/import_lectionary.dart '
      '${options.year} --export-existing',
    );
  }

  final String csvText = sourceFile.readAsStringSync();

  final List<List<String>> csvRows =
      CsvParser.parse(csvText);

  if (csvRows.isEmpty) {
    throw ImportException(
      'The source CSV file is empty.',
    );
  }

  final HeaderIndex headerIndex = HeaderIndex.fromRow(
    csvRows.first,
  );

  final Map<String, DayBuilder> daysByDate =
      <String, DayBuilder>{};

  int importedRowCount = 0;

  for (int rowIndex = 1;
      rowIndex < csvRows.length;
      rowIndex++) {
    final List<String> row = csvRows[rowIndex];

    if (_isBlankRow(row)) {
      continue;
    }

    final int csvLineNumber = rowIndex + 1;

    final SourceRow sourceRow = SourceRow.parse(
      row: row,
      headerIndex: headerIndex,
      csvLineNumber: csvLineNumber,
      expectedYear: options.year,
    );

    final DayBuilder day = daysByDate.putIfAbsent(
      sourceRow.date,
      () => DayBuilder(
        date: sourceRow.date,
        liturgicalDay: sourceRow.liturgicalDay,
      ),
    );

    day.confirmLiturgicalDay(
      sourceRow.liturgicalDay,
      csvLineNumber,
    );

    final ReadingBuilder reading =
        day.readingsByOrder.putIfAbsent(
      sourceRow.readingOrder,
      () => ReadingBuilder(
        order: sourceRow.readingOrder,
        kind: sourceRow.kind,
        title: sourceRow.title,
        displayReference:
            sourceRow.displayReference,
        response: sourceRow.response,
        choiceGroup: sourceRow.choiceGroup,
        choiceLabel: sourceRow.choiceLabel,
      ),
    );

    reading.confirmMetadata(
      sourceRow,
      csvLineNumber,
    );

    reading.addRange(
      order: sourceRow.rangeOrder,
      range: ScriptureRangeBuilder(
        bookCode: sourceRow.bookCode,
        chapter: sourceRow.chapter,
        startVerse: sourceRow.startVerse,
        endVerse: sourceRow.endVerse,
        displayVerseOffset:
            sourceRow.displayVerseOffset,
      ),
      csvLineNumber: csvLineNumber,
    );

    importedRowCount++;
  }

  if (daysByDate.isEmpty) {
    throw ImportException(
      'The source CSV contains no reading rows.',
    );
  }

  final List<DayBuilder> sortedDays =
      daysByDate.values.toList()
        ..sort(
          (DayBuilder first, DayBuilder second) =>
              first.date.compareTo(second.date),
        );

  for (final DayBuilder day in sortedDays) {
    day.validateOrders();
  }

  final int existingDayCount =
      _existingDayCount(outputFile);

  if (existingDayCount > sortedDays.length &&
      !options.allowShrink) {
    throw ImportException(
      'The generated file would contain only '
      '${sortedDays.length} day(s), but the existing '
      'file contains $existingDayCount day(s).\n\n'
      'This protection prevents accidental data loss.\n'
      'Use --allow-shrink only when removing dates '
      'is intentional.',
    );
  }

  final Map<String, dynamic> outputJson =
      <String, dynamic>{
    'schemaVersion': _schemaVersion,
    'year': options.year,
    'days': sortedDays
        .map(
          (DayBuilder day) => day.toJson(),
        )
        .toList(),
  };

  final String encodedJson =
      '${const JsonEncoder.withIndent('  ').convert(outputJson)}\n';

  await outputFile.parent.create(
    recursive: true,
  );

  final bool outputPreviouslyExisted =
      outputFile.existsSync();

  final String? previousOutput =
      outputPreviouslyExisted
          ? outputFile.readAsStringSync()
          : null;

  outputFile.writeAsStringSync(
    encodedJson,
    encoding: utf8,
    flush: true,
  );

  stdout.writeln(
    'Imported $importedRowCount CSV row(s).',
  );
  stdout.writeln(
    'Generated ${sortedDays.length} day(s).',
  );
  stdout.writeln(
    'Generated ${_countReadings(sortedDays)} '
    'reading(s).',
  );
  stdout.writeln(
    'Generated ${_countRanges(sortedDays)} '
    'Scripture range(s).',
  );
  stdout.writeln();

  if (!options.runValidator) {
    stdout.writeln(
      'Import completed without running the validator.',
    );
    return;
  }

  final bool validationPassed =
      await _runValidator();

  if (!validationPassed) {
    if (outputPreviouslyExisted &&
        previousOutput != null) {
      outputFile.writeAsStringSync(
        previousOutput,
        encoding: utf8,
        flush: true,
      );

      stderr.writeln();
      stderr.writeln(
        'The previous ${outputFile.path} file '
        'was restored.',
      );
    } else if (outputFile.existsSync()) {
      outputFile.deleteSync();

      stderr.writeln();
      stderr.writeln(
        'The invalid generated file was removed.',
      );
    }

    throw ImportException(
      'The generated lectionary file did not '
      'pass validation.',
    );
  }

  stdout.writeln();
  stdout.writeln(
    'IMPORT COMPLETED SUCCESSFULLY',
  );
}

Future<bool> _runValidator() async {
  final File validatorFile = File(
    _validatorPath,
  );

  if (!validatorFile.existsSync()) {
    throw ImportException(
      'The validator was not found:\n'
      '$_validatorPath',
    );
  }

  stdout.writeln(
    'Running the lectionary validator...',
  );
  stdout.writeln();

  final ProcessResult result = await Process.run(
    Platform.resolvedExecutable,
    <String>[
      'run',
      _validatorPath,
    ],
    workingDirectory: Directory.current.path,
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

  return result.exitCode == 0;
}

void _exportExistingJson(
  ImportOptions options,
) {
  final File sourceFile = File(
    options.sourcePath,
  );

  final File outputFile = File(
    options.outputPath,
  );

  stdout.writeln(
    'My Catholic Day Lectionary Exporter',
  );
  stdout.writeln(
    '==================================',
  );
  stdout.writeln();

  if (!outputFile.existsSync()) {
    throw ImportException(
      'The existing lectionary JSON file was '
      'not found:\n${outputFile.path}',
    );
  }

  if (sourceFile.existsSync() && !options.force) {
    throw ImportException(
      'The source CSV file already exists:\n'
      '${sourceFile.path}\n\n'
      'Use --force to replace it.',
    );
  }

  final Object? decoded = jsonDecode(
    outputFile.readAsStringSync(),
  );

  if (decoded is! Map<String, dynamic>) {
    throw ImportException(
      'The existing lectionary JSON does not '
      'contain a valid top-level object.',
    );
  }

  final int? jsonYear = _integerValue(
    decoded['year'],
  );

  if (jsonYear != options.year) {
    throw ImportException(
      'The JSON file is marked as year '
      '$jsonYear instead of ${options.year}.',
    );
  }

  final Object? daysValue = decoded['days'];

  if (daysValue is! List<dynamic>) {
    throw ImportException(
      'The existing lectionary JSON has no '
      'valid days list.',
    );
  }

  final StringBuffer csv = StringBuffer();

  csv.writeln(
    _csvHeaders.map(_escapeCsvField).join(','),
  );

  int exportedRowCount = 0;

  for (int dayIndex = 0;
      dayIndex < daysValue.length;
      dayIndex++) {
    final Map<String, dynamic> day = _requireMap(
      daysValue[dayIndex],
      'day ${dayIndex + 1}',
    );

    final String date = _requireJsonString(
      day['date'],
      'day ${dayIndex + 1} date',
    );

    final String liturgicalDay =
        _requireJsonString(
      day['liturgicalDay'],
      '$date liturgicalDay',
    );

    final Object? readingsValue =
        day['readings'];

    if (readingsValue is! List<dynamic>) {
      throw ImportException(
        '$date has no valid readings list.',
      );
    }

    for (int readingIndex = 0;
        readingIndex < readingsValue.length;
        readingIndex++) {
      final Map<String, dynamic> reading =
          _requireMap(
        readingsValue[readingIndex],
        '$date reading ${readingIndex + 1}',
      );

      final String kind = _requireJsonString(
        reading['kind'],
        '$date reading ${readingIndex + 1} kind',
      );

      final String title = _requireJsonString(
        reading['title'],
        '$date reading ${readingIndex + 1} title',
      );

      final String displayReference =
          _requireJsonString(
        reading['displayReference'],
        '$date reading ${readingIndex + 1} '
        'displayReference',
      );

      final String response =
          _nullableJsonString(
        reading['response'],
      );

      final String choiceGroup =
          _nullableJsonString(
        reading['choiceGroup'],
      );

      final String choiceLabel =
          _nullableJsonString(
        reading['choiceLabel'],
      );

      final Object? rangesValue =
          reading['ranges'];

      if (rangesValue is! List<dynamic>) {
        throw ImportException(
          '$date reading ${readingIndex + 1} '
          'has no valid ranges list.',
        );
      }

      for (int rangeIndex = 0;
          rangeIndex < rangesValue.length;
          rangeIndex++) {
        final Map<String, dynamic> range =
            _requireMap(
          rangesValue[rangeIndex],
          '$date reading ${readingIndex + 1} '
          'range ${rangeIndex + 1}',
        );

        final List<Object?> csvValues = <Object?>[
          date,
          liturgicalDay,
          readingIndex + 1,
          kind,
          title,
          displayReference,
          response,
          choiceGroup,
          choiceLabel,
          rangeIndex + 1,
          _requireJsonString(
            range['bookCode'],
            '$date bookCode',
          ),
          _requireJsonInteger(
            range['chapter'],
            '$date chapter',
          ),
          _requireJsonInteger(
            range['startVerse'],
            '$date startVerse',
          ),
          _requireJsonInteger(
            range['endVerse'],
            '$date endVerse',
          ),
          _integerValue(
                range['displayVerseOffset'],
              ) ??
              0,
        ];

        csv.writeln(
          csvValues
              .map(
                (Object? value) =>
                    _escapeCsvField(
                  value?.toString() ?? '',
                ),
              )
              .join(','),
        );

        exportedRowCount++;
      }
    }
  }

  sourceFile.parent.createSync(
    recursive: true,
  );

  sourceFile.writeAsStringSync(
    csv.toString(),
    encoding: utf8,
    flush: true,
  );

  stdout.writeln(
    'Exported $exportedRowCount row(s).',
  );
  stdout.writeln(
    'Created ${sourceFile.path}',
  );
  stdout.writeln();
  stdout.writeln(
    'EXPORT COMPLETED SUCCESSFULLY',
  );
}

void _createTemplate(
  ImportOptions options,
) {
  final File sourceFile = File(
    options.sourcePath,
  );

  if (sourceFile.existsSync() && !options.force) {
    throw ImportException(
      'The source CSV file already exists:\n'
      '${sourceFile.path}\n\n'
      'Use --force to replace it.',
    );
  }

  sourceFile.parent.createSync(
    recursive: true,
  );

  sourceFile.writeAsStringSync(
    '${_csvHeaders.map(_escapeCsvField).join(',')}\n',
    encoding: utf8,
    flush: true,
  );

  stdout.writeln(
    'Created empty lectionary template:',
  );
  stdout.writeln(
    sourceFile.path,
  );
}

int _existingDayCount(File outputFile) {
  if (!outputFile.existsSync()) {
    return 0;
  }

  final Object? decoded;

  try {
    decoded = jsonDecode(
      outputFile.readAsStringSync(),
    );
  } on FormatException catch (error) {
    throw ImportException(
      'The existing output file contains invalid '
      'JSON and will not be overwritten:\n'
      '${error.message}',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    throw ImportException(
      'The existing output file is not a valid '
      'JSON object and will not be overwritten.',
    );
  }

  final Object? daysValue = decoded['days'];

  if (daysValue is! List<dynamic>) {
    throw ImportException(
      'The existing output file has no valid '
      'days list and will not be overwritten.',
    );
  }

  return daysValue.length;
}

int _countReadings(
  List<DayBuilder> days,
) {
  int count = 0;

  for (final DayBuilder day in days) {
    count += day.readingsByOrder.length;
  }

  return count;
}

int _countRanges(
  List<DayBuilder> days,
) {
  int count = 0;

  for (final DayBuilder day in days) {
    for (final ReadingBuilder reading
        in day.readingsByOrder.values) {
      count += reading.rangesByOrder.length;
    }
  }

  return count;
}

bool _isBlankRow(List<String> row) {
  return row.every(
    (String value) => value.trim().isEmpty,
  );
}

String _escapeCsvField(String value) {
  final bool needsQuotes =
      value.contains(',') ||
      value.contains('"') ||
      value.contains('\r') ||
      value.contains('\n');

  if (!needsQuotes) {
    return value;
  }

  return '"${value.replaceAll('"', '""')}"';
}

Map<String, dynamic> _requireMap(
  Object? value,
  String location,
) {
  if (value is! Map<String, dynamic>) {
    throw ImportException(
      '$location is not a valid JSON object.',
    );
  }

  return value;
}

String _requireJsonString(
  Object? value,
  String location,
) {
  if (value is! String || value.trim().isEmpty) {
    throw ImportException(
      '$location is not valid text.',
    );
  }

  return value.trim();
}

String _nullableJsonString(Object? value) {
  if (value == null) {
    return '';
  }

  if (value is! String) {
    throw ImportException(
      'An optional JSON text value is invalid.',
    );
  }

  return value.trim();
}

int _requireJsonInteger(
  Object? value,
  String location,
) {
  final int? integer = _integerValue(value);

  if (integer == null) {
    throw ImportException(
      '$location is not a valid integer.',
    );
  }

  return integer;
}

int? _integerValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num &&
      value.isFinite &&
      value == value.roundToDouble()) {
    return value.toInt();
  }

  return null;
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

  final DateTime parsed = DateTime.utc(
    year,
    month,
    day,
  );

  if (parsed.year != year ||
      parsed.month != month ||
      parsed.day != day) {
    return null;
  }

  return parsed;
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

String _normalizeBookCode(String value) {
  return value.trim().toUpperCase();
}

void _printUsage() {
  stdout.writeln(
    'My Catholic Day Lectionary Importer',
  );
  stdout.writeln();
  stdout.writeln(
    'Import a CSV file and generate yearly JSON:',
  );
  stdout.writeln(
    '  dart run tool/import_lectionary.dart 2026',
  );
  stdout.writeln();
  stdout.writeln(
    'Export the current yearly JSON to CSV:',
  );
  stdout.writeln(
    '  dart run tool/import_lectionary.dart '
    '2026 --export-existing',
  );
  stdout.writeln();
  stdout.writeln(
    'Create an empty CSV template:',
  );
  stdout.writeln(
    '  dart run tool/import_lectionary.dart '
    '2026 --template',
  );
  stdout.writeln();
  stdout.writeln(
    'Options:',
  );
  stdout.writeln(
    '  --source PATH       Use a custom CSV path.',
  );
  stdout.writeln(
    '  --output PATH       Use a custom JSON path.',
  );
  stdout.writeln(
    '  --no-validate       Do not run the validator.',
  );
  stdout.writeln(
    '  --allow-shrink      Permit fewer dates than '
    'the existing file.',
  );
  stdout.writeln(
    '  --force             Replace an existing CSV '
    'during export/template creation.',
  );
  stdout.writeln(
    '  --help              Show this help.',
  );
}

class ImportOptions {
  ImportOptions({
    required this.year,
    required this.sourcePath,
    required this.outputPath,
    required this.runValidator,
    required this.exportExisting,
    required this.createTemplate,
    required this.allowShrink,
    required this.force,
    required this.showHelp,
  });

  final int year;
  final String sourcePath;
  final String outputPath;
  final bool runValidator;
  final bool exportExisting;
  final bool createTemplate;
  final bool allowShrink;
  final bool force;
  final bool showHelp;

  static ImportOptions parse(
    List<String> arguments,
  ) {
    if (arguments.contains('--help') ||
        arguments.contains('-h')) {
      return ImportOptions(
        year: DateTime.now().year,
        sourcePath: '',
        outputPath: '',
        runValidator: true,
        exportExisting: false,
        createTemplate: false,
        allowShrink: false,
        force: false,
        showHelp: true,
      );
    }

    int? year;
    String? customSourcePath;
    String? customOutputPath;

    bool runValidator = true;
    bool exportExisting = false;
    bool createTemplate = false;
    bool allowShrink = false;
    bool force = false;

    for (int index = 0;
        index < arguments.length;
        index++) {
      final String argument = arguments[index];

      if (argument == '--no-validate') {
        runValidator = false;
        continue;
      }

      if (argument == '--export-existing') {
        exportExisting = true;
        continue;
      }

      if (argument == '--template') {
        createTemplate = true;
        continue;
      }

      if (argument == '--allow-shrink') {
        allowShrink = true;
        continue;
      }

      if (argument == '--force') {
        force = true;
        continue;
      }

      if (argument == '--source') {
        if (index + 1 >= arguments.length) {
          throw ImportException(
            '--source requires a file path.',
          );
        }

        customSourcePath = arguments[++index];
        continue;
      }

      if (argument.startsWith('--source=')) {
        customSourcePath = argument.substring(
          '--source='.length,
        );
        continue;
      }

      if (argument == '--output') {
        if (index + 1 >= arguments.length) {
          throw ImportException(
            '--output requires a file path.',
          );
        }

        customOutputPath = arguments[++index];
        continue;
      }

      if (argument.startsWith('--output=')) {
        customOutputPath = argument.substring(
          '--output='.length,
        );
        continue;
      }

      if (argument.startsWith('-')) {
        throw ImportException(
          'Unknown option: $argument',
        );
      }

      if (year != null) {
        throw ImportException(
          'Only one year may be supplied.',
        );
      }

      year = int.tryParse(argument);

      if (year == null ||
          year < 1900 ||
          year > 3000) {
        throw ImportException(
          'Invalid year: $argument',
        );
      }
    }

    if (year == null) {
      throw ImportException(
        'A year is required.\n\n'
        'Example:\n'
        'dart run tool/import_lectionary.dart 2026',
      );
    }

    if (exportExisting && createTemplate) {
      throw ImportException(
        '--export-existing and --template cannot '
        'be used together.',
      );
    }

    return ImportOptions(
      year: year,
      sourcePath: customSourcePath ??
          '$_defaultSourceDirectory/$year.csv',
      outputPath: customOutputPath ??
          '$_defaultOutputDirectory/$year.json',
      runValidator: runValidator,
      exportExisting: exportExisting,
      createTemplate: createTemplate,
      allowShrink: allowShrink,
      force: force,
      showHelp: false,
    );
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

      if (indexes.containsKey(normalizedHeader)) {
        throw ImportException(
          'The CSV contains the header '
          '"${headerRow[index]}" more than once.',
        );
      }

      indexes[normalizedHeader] = index;
    }

    for (final String requiredHeader
        in _csvHeaders) {
      final String normalizedRequired =
          _normalizeHeader(requiredHeader);

      if (!indexes.containsKey(
        normalizedRequired,
      )) {
        throw ImportException(
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

class SourceRow {
  SourceRow({
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

  static SourceRow parse({
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
        throw ImportException(
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
        throw ImportException(
          'CSV line $csvLineNumber has an '
          'invalid $header: $text',
        );
      }

      return value;
    }

    final String date = requiredText('date');

    final DateTime? parsedDate =
        _parseStrictDate(date);

    if (parsedDate == null) {
      throw ImportException(
        'CSV line $csvLineNumber has an invalid '
        'date: $date. Use YYYY-MM-DD.',
      );
    }

    if (parsedDate.year != expectedYear) {
      throw ImportException(
        'CSV line $csvLineNumber uses $date, '
        'but this import is for $expectedYear.',
      );
    }

    final String kind = requiredText('kind');

    if (!_allowedReadingKinds.contains(kind)) {
      throw ImportException(
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
      throw ImportException(
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
      throw ImportException(
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
      throw ImportException(
        'CSV line $csvLineNumber has an invalid '
        'displayVerseOffset: $offsetText',
      );
    }

    final String bookCode =
        _normalizeBookCode(
      requiredText('bookCode'),
    );

    if (!RegExp(r'^[A-Z0-9]{2,4}$')
        .hasMatch(bookCode)) {
      throw ImportException(
        'CSV line $csvLineNumber has an invalid '
        'bookCode: $bookCode',
      );
    }

    return SourceRow(
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
      bookCode: bookCode,
      chapter:
          requiredPositiveInteger('chapter'),
      startVerse: startVerse,
      endVerse: endVerse,
      displayVerseOffset:
          displayVerseOffset,
    );
  }
}

class DayBuilder {
  DayBuilder({
    required this.date,
    required this.liturgicalDay,
  });

  final String date;
  final String liturgicalDay;

  final Map<int, ReadingBuilder> readingsByOrder =
      <int, ReadingBuilder>{};

  void confirmLiturgicalDay(
    String otherLiturgicalDay,
    int csvLineNumber,
  ) {
    if (otherLiturgicalDay != liturgicalDay) {
      throw ImportException(
        'CSV line $csvLineNumber gives $date a '
        'different liturgicalDay.\n'
        'Expected: $liturgicalDay\n'
        'Found: $otherLiturgicalDay',
      );
    }
  }

  void validateOrders() {
    if (readingsByOrder.isEmpty) {
      throw ImportException(
        '$date contains no readings.',
      );
    }

    final List<int> readingOrders =
        readingsByOrder.keys.toList()
          ..sort();

    for (int index = 0;
        index < readingOrders.length;
        index++) {
      final int expectedOrder = index + 1;

      if (readingOrders[index] != expectedOrder) {
        throw ImportException(
          '$date is missing readingOrder '
          '$expectedOrder.',
        );
      }
    }

    for (final ReadingBuilder reading
        in readingsByOrder.values) {
      reading.validateOrders(date);
    }
  }

  Map<String, dynamic> toJson() {
    final List<int> sortedOrders =
        readingsByOrder.keys.toList()
          ..sort();

    return <String, dynamic>{
      'date': date,
      'liturgicalDay': liturgicalDay,
      'readings': sortedOrders
          .map(
            (int order) =>
                readingsByOrder[order]!.toJson(),
          )
          .toList(),
    };
  }
}

class ReadingBuilder {
  ReadingBuilder({
    required this.order,
    required this.kind,
    required this.title,
    required this.displayReference,
    required this.response,
    required this.choiceGroup,
    required this.choiceLabel,
  });

  final int order;
  final String kind;
  final String title;
  final String displayReference;
  final String? response;
  final String? choiceGroup;
  final String? choiceLabel;

  final Map<int, ScriptureRangeBuilder>
      rangesByOrder =
      <int, ScriptureRangeBuilder>{};

  void confirmMetadata(
    SourceRow row,
    int csvLineNumber,
  ) {
    if (row.kind != kind ||
        row.title != title ||
        row.displayReference != displayReference ||
        row.response != response ||
        row.choiceGroup != choiceGroup ||
        row.choiceLabel != choiceLabel) {
      throw ImportException(
        'CSV line $csvLineNumber contains '
        'different metadata for readingOrder '
        '$order on ${row.date}.',
      );
    }
  }

  void addRange({
    required int order,
    required ScriptureRangeBuilder range,
    required int csvLineNumber,
  }) {
    if (rangesByOrder.containsKey(order)) {
      throw ImportException(
        'CSV line $csvLineNumber duplicates '
        'rangeOrder $order.',
      );
    }

    rangesByOrder[order] = range;
  }

  void validateOrders(String date) {
    if (rangesByOrder.isEmpty) {
      throw ImportException(
        '$date readingOrder $order contains '
        'no Scripture ranges.',
      );
    }

    final List<int> rangeOrders =
        rangesByOrder.keys.toList()
          ..sort();

    for (int index = 0;
        index < rangeOrders.length;
        index++) {
      final int expectedOrder = index + 1;

      if (rangeOrders[index] != expectedOrder) {
        throw ImportException(
          '$date readingOrder $order is missing '
          'rangeOrder $expectedOrder.',
        );
      }
    }
  }

  Map<String, dynamic> toJson() {
    final List<int> sortedOrders =
        rangesByOrder.keys.toList()
          ..sort();

    return <String, dynamic>{
      'kind': kind,
      'title': title,
      'displayReference': displayReference,
      'response': response,
      'choiceGroup': choiceGroup,
      'choiceLabel': choiceLabel,
      'ranges': sortedOrders
          .map(
            (int rangeOrder) =>
                rangesByOrder[rangeOrder]!
                    .toJson(),
          )
          .toList(),
    };
  }
}

class ScriptureRangeBuilder {
  ScriptureRangeBuilder({
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bookCode': bookCode,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'displayVerseOffset':
          displayVerseOffset,
    };
  }
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

        throw ImportException(
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
      throw ImportException(
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

class ImportException implements Exception {
  const ImportException(this.message);

  final String message;

  @override
  String toString() => message;
}