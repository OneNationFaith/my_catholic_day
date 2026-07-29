import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

const String _lectionaryDirectoryPath =
    'assets/data/lectionary';

const String _bibleDatabasePath =
    'assets/databases/webc.db';

const int _supportedSchemaVersion = 1;

const Set<String> _allowedReadingKinds = <String>{
  'firstReading',
  'responsorialPsalm',
  'secondReading',
  'gospelAcclamation',
  'gospel',
  'other',
};

void main(List<String> arguments) {
  final ValidationReport report = ValidationReport();

  stdout.writeln(
    'My Catholic Day Lectionary Validator',
  );
  stdout.writeln(
    '====================================',
  );
  stdout.writeln();

  final Directory lectionaryDirectory = Directory(
    _lectionaryDirectoryPath,
  );

  if (!lectionaryDirectory.existsSync()) {
    report.error(
      'The lectionary directory was not found: '
      '$_lectionaryDirectoryPath',
    );

    _printFinalReport(report);
    exitCode = 1;
    return;
  }

  final File bibleDatabaseFile = File(
    _bibleDatabasePath,
  );

  if (!bibleDatabaseFile.existsSync()) {
    report.error(
      'The WEBC database was not found: '
      '$_bibleDatabasePath',
    );

    _printFinalReport(report);
    exitCode = 1;
    return;
  }

  late final BibleIndex bibleIndex;

  try {
    stdout.writeln(
      'Loading the WEBC Bible database...',
    );

    bibleIndex = BibleIndex.load(
      bibleDatabaseFile,
    );

    stdout.writeln(
      'Loaded ${bibleIndex.bookCount} Bible books '
      'and ${bibleIndex.verseRecordCount} verse records.',
    );
    stdout.writeln();
  } catch (error) {
    report.error(
      'The WEBC database could not be read: $error',
    );

    _printFinalReport(report);
    exitCode = 1;
    return;
  }

  final List<File> jsonFiles = lectionaryDirectory
      .listSync()
      .whereType<File>()
      .where(
        (File file) =>
            file.path.toLowerCase().endsWith('.json'),
      )
      .toList()
    ..sort(
      (File first, File second) =>
          first.path.compareTo(second.path),
    );

  if (jsonFiles.isEmpty) {
    report.error(
      'No JSON files were found in '
      '$_lectionaryDirectoryPath.',
    );

    _printFinalReport(report);
    exitCode = 1;
    return;
  }

  final Map<String, String> datesAcrossFiles =
      <String, String>{};

  for (final File file in jsonFiles) {
    _validateLectionaryFile(
      file: file,
      bibleIndex: bibleIndex,
      report: report,
      datesAcrossFiles: datesAcrossFiles,
    );
  }

  _printFinalReport(report);

  if (report.errorCount > 0) {
    exitCode = 1;
  }
}

void _validateLectionaryFile({
  required File file,
  required BibleIndex bibleIndex,
  required ValidationReport report,
  required Map<String, String> datesAcrossFiles,
}) {
  final String fileName = _fileName(file);

  stdout.writeln('Checking $fileName...');

  Object? decodedJson;

  try {
    decodedJson = jsonDecode(
      file.readAsStringSync(),
    );
  } on FormatException catch (error) {
    report.error(
      '$fileName contains invalid JSON: '
      '${error.message}',
    );

    stdout.writeln();
    return;
  } on FileSystemException catch (error) {
    report.error(
      '$fileName could not be read: '
      '${error.message}',
    );

    stdout.writeln();
    return;
  }

  if (decodedJson is! Map<String, dynamic>) {
    report.error(
      '$fileName must contain one JSON object '
      'at the top level.',
    );

    stdout.writeln();
    return;
  }

  final Map<String, dynamic> root = decodedJson;

  final int? schemaVersion = _integerValue(
    root['schemaVersion'],
  );

  if (schemaVersion == null) {
    report.error(
      '$fileName has no valid schemaVersion.',
    );
  } else if (schemaVersion !=
      _supportedSchemaVersion) {
    report.error(
      '$fileName uses schemaVersion '
      '$schemaVersion. The validator supports '
      'version $_supportedSchemaVersion.',
    );
  }

  final int? year = _integerValue(
    root['year'],
  );

  if (year == null || year < 1) {
    report.error(
      '$fileName has no valid year.',
    );
  }

  final int? fileNameYear =
      _yearFromFileName(fileName);

  if (year != null &&
      fileNameYear != null &&
      year != fileNameYear) {
    report.error(
      '$fileName says it contains year $year, '
      'but its filename says $fileNameYear.',
    );
  }

  final Object? daysValue = root['days'];

  if (daysValue is! List<dynamic>) {
    report.error(
      '$fileName has no valid days list.',
    );

    stdout.writeln();
    return;
  }

  if (daysValue.isEmpty) {
    report.warning(
      '$fileName contains no lectionary days.',
    );
  }

  final Set<String> datesInFile = <String>{};

  int validDayCount = 0;
  int readingCount = 0;
  int rangeCount = 0;

  for (int dayIndex = 0;
      dayIndex < daysValue.length;
      dayIndex++) {
    final Object? dayValue = daysValue[dayIndex];

    final String dayLocation =
        '$fileName, day ${dayIndex + 1}';

    if (dayValue is! Map<String, dynamic>) {
      report.error(
        '$dayLocation is not a valid JSON object.',
      );
      continue;
    }

    final String? dateText = _nonEmptyString(
      dayValue['date'],
    );

    if (dateText == null) {
      report.error(
        '$dayLocation has no valid date.',
      );
      continue;
    }

    final DateTime? parsedDate = _parseStrictDate(
      dateText,
    );

    if (parsedDate == null) {
      report.error(
        '$dayLocation has an invalid date: '
        '$dateText. Use YYYY-MM-DD.',
      );
      continue;
    }

    validDayCount++;

    if (year != null && parsedDate.year != year) {
      report.error(
        '$dayLocation uses $dateText, but the '
        'file is marked as year $year.',
      );
    }

    if (!datesInFile.add(dateText)) {
      report.error(
        '$fileName contains $dateText '
        'more than once.',
      );
    }

    final String? previousLocation =
        datesAcrossFiles[dateText];

    if (previousLocation != null) {
      report.error(
        '$dateText appears in both '
        '$previousLocation and $dayLocation.',
      );
    } else {
      datesAcrossFiles[dateText] = dayLocation;
    }

    final String? liturgicalDay = _nonEmptyString(
      dayValue['liturgicalDay'],
    );

    if (liturgicalDay == null) {
      report.error(
        '$dayLocation has no liturgicalDay.',
      );
    }

    final Object? readingsValue =
        dayValue['readings'];

    if (readingsValue is! List<dynamic>) {
      report.error(
        '$dayLocation has no valid readings list.',
      );
      continue;
    }

    if (readingsValue.isEmpty) {
      report.warning(
        '$dayLocation contains no readings.',
      );
    }

    for (int readingIndex = 0;
        readingIndex < readingsValue.length;
        readingIndex++) {
      final Object? readingValue =
          readingsValue[readingIndex];

      final String readingLocation =
          '$dayLocation, reading '
          '${readingIndex + 1}';

      if (readingValue
          is! Map<String, dynamic>) {
        report.error(
          '$readingLocation is not a valid '
          'JSON object.',
        );
        continue;
      }

      readingCount++;

      _validateReading(
        reading: readingValue,
        location: readingLocation,
        bibleIndex: bibleIndex,
        report: report,
        onRangeChecked: () {
          rangeCount++;
        },
      );
    }
  }

  report.fileCount++;
  report.dayCount += validDayCount;
  report.readingCount += readingCount;
  report.rangeCount += rangeCount;

  stdout.writeln(
    '  $validDayCount day(s), '
    '$readingCount reading(s), '
    '$rangeCount range(s)',
  );
  stdout.writeln();
}

void _validateReading({
  required Map<String, dynamic> reading,
  required String location,
  required BibleIndex bibleIndex,
  required ValidationReport report,
  required void Function() onRangeChecked,
}) {
  final String? kind = _nonEmptyString(
    reading['kind'],
  );

  if (kind == null) {
    report.error(
      '$location has no reading kind.',
    );
  } else if (!_allowedReadingKinds.contains(
    kind,
  )) {
    report.error(
      '$location has an unsupported reading '
      'kind: $kind.',
    );
  }

  final String? title = _nonEmptyString(
    reading['title'],
  );

  if (title == null) {
    report.error(
      '$location has no title.',
    );
  }

  final String? displayReference =
      _nonEmptyString(
    reading['displayReference'],
  );

  if (displayReference == null) {
    report.error(
      '$location has no displayReference.',
    );
  }

  final Object? responseValue =
      reading['response'];

  if (responseValue != null &&
      responseValue is! String) {
    report.error(
      '$location has a response that is not text.',
    );
  }

  if (responseValue is String &&
      responseValue.trim().isEmpty) {
    report.warning(
      '$location has an empty response.',
    );
  }

  final Object? choiceGroupValue =
      reading['choiceGroup'];

  final Object? choiceLabelValue =
      reading['choiceLabel'];

  if (choiceGroupValue != null &&
      choiceGroupValue is! String) {
    report.error(
      '$location has a choiceGroup that is '
      'not text.',
    );
  }

  if (choiceLabelValue != null &&
      choiceLabelValue is! String) {
    report.error(
      '$location has a choiceLabel that is '
      'not text.',
    );
  }

  final String? choiceGroup =
      _nonEmptyString(choiceGroupValue);

  final String? choiceLabel =
      _nonEmptyString(choiceLabelValue);

  if (choiceGroup == null && choiceLabel != null) {
    report.warning(
      '$location has a choiceLabel but no '
      'choiceGroup.',
    );
  }

  if (choiceGroup != null && choiceLabel == null) {
    report.warning(
      '$location has a choiceGroup but no '
      'choiceLabel.',
    );
  }

  final Object? rangesValue =
      reading['ranges'];

  if (rangesValue is! List<dynamic>) {
    report.error(
      '$location has no valid ranges list.',
    );
    return;
  }

  if (rangesValue.isEmpty) {
    report.error(
      '$location contains no Scripture ranges.',
    );
    return;
  }

  final Set<String> rangesInReading = <String>{};

  for (int rangeIndex = 0;
      rangeIndex < rangesValue.length;
      rangeIndex++) {
    final Object? rangeValue =
        rangesValue[rangeIndex];

    final String rangeLocation =
        '$location, range ${rangeIndex + 1}';

    if (rangeValue is! Map<String, dynamic>) {
      report.error(
        '$rangeLocation is not a valid '
        'JSON object.',
      );
      continue;
    }

    onRangeChecked();

    _validateRange(
      range: rangeValue,
      location: rangeLocation,
      bibleIndex: bibleIndex,
      report: report,
      rangesInReading: rangesInReading,
    );
  }
}

void _validateRange({
  required Map<String, dynamic> range,
  required String location,
  required BibleIndex bibleIndex,
  required ValidationReport report,
  required Set<String> rangesInReading,
}) {
  final String? bookCode = _nonEmptyString(
    range['bookCode'],
  );

  final int? chapter = _integerValue(
    range['chapter'],
  );

  final int? startVerse = _integerValue(
    range['startVerse'],
  );

  final int? endVerse = _integerValue(
    range['endVerse'],
  );

  final Object? offsetValue =
      range['displayVerseOffset'];

  final int? displayVerseOffset =
      offsetValue == null
          ? 0
          : _integerValue(offsetValue);

  if (bookCode == null) {
    report.error(
      '$location has no valid bookCode.',
    );
  }

  if (chapter == null || chapter < 1) {
    report.error(
      '$location has an invalid chapter.',
    );
  }

  if (startVerse == null || startVerse < 1) {
    report.error(
      '$location has an invalid startVerse.',
    );
  }

  if (endVerse == null || endVerse < 1) {
    report.error(
      '$location has an invalid endVerse.',
    );
  }

  if (displayVerseOffset == null) {
    report.error(
      '$location has an invalid '
      'displayVerseOffset.',
    );
  }

  if (bookCode == null ||
      chapter == null ||
      chapter < 1 ||
      startVerse == null ||
      startVerse < 1 ||
      endVerse == null ||
      endVerse < 1 ||
      displayVerseOffset == null) {
    return;
  }

  if (endVerse < startVerse) {
    report.error(
      '$location ends at verse $endVerse, '
      'which comes before verse $startVerse.',
    );
    return;
  }

  final String normalizedBookCode =
      _normalizeBookCode(bookCode);

  final String rangeKey = <Object>[
    normalizedBookCode,
    chapter,
    startVerse,
    endVerse,
    displayVerseOffset,
  ].join('|');

  if (!rangesInReading.add(rangeKey)) {
    report.error(
      '$location duplicates another range in '
      'the same reading: '
      '$normalizedBookCode '
      '$chapter:$startVerse-$endVerse.',
    );
  }

  if (!bibleIndex.containsBook(
    normalizedBookCode,
  )) {
    report.error(
      '$location refers to a bookCode that '
      'does not exist in the WEBC database: '
      '$normalizedBookCode.',
    );
    return;
  }

  if (!bibleIndex.containsChapter(
    normalizedBookCode,
    chapter,
  )) {
    report.error(
      '$location refers to a chapter that does '
      'not exist in the WEBC database: '
      '$normalizedBookCode $chapter.',
    );
    return;
  }

  for (int verse = startVerse;
      verse <= endVerse;
      verse++) {
    if (!bibleIndex.containsVerse(
      normalizedBookCode,
      chapter,
      verse,
    )) {
      report.error(
        '$location refers to a missing verse: '
        '$normalizedBookCode '
        '$chapter:$verse.',
      );
      continue;
    }

    if (bibleIndex.isOmittedVerse(
      normalizedBookCode,
      chapter,
      verse,
    )) {
      report.warning(
        '$location includes an omitted verse '
        'record: $normalizedBookCode '
        '$chapter:$verse.',
      );
    }
  }
}

void _printFinalReport(
  ValidationReport report,
) {
  stdout.writeln(
    'Validation Summary',
  );
  stdout.writeln(
    '==================',
  );
  stdout.writeln(
    'Files checked: ${report.fileCount}',
  );
  stdout.writeln(
    'Days checked: ${report.dayCount}',
  );
  stdout.writeln(
    'Readings checked: ${report.readingCount}',
  );
  stdout.writeln(
    'Ranges checked: ${report.rangeCount}',
  );
  stdout.writeln(
    'Warnings: ${report.warningCount}',
  );
  stdout.writeln(
    'Errors: ${report.errorCount}',
  );
  stdout.writeln();

  if (report.errorCount == 0) {
    stdout.writeln(
      'VALIDATION PASSED',
    );
  } else {
    stdout.writeln(
      'VALIDATION FAILED',
    );
  }
}

String _fileName(File file) {
  final List<String> pathSegments =
      file.uri.pathSegments;

  if (pathSegments.isEmpty) {
    return file.path;
  }

  return pathSegments.last;
}

int? _yearFromFileName(String fileName) {
  final Match? match = RegExp(
    r'^(\d{4})\.json$',
  ).firstMatch(fileName);

  if (match == null) {
    return null;
  }

  return int.tryParse(
    match.group(1)!,
  );
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

  final DateTime parsedDate = DateTime.utc(
    year,
    month,
    day,
  );

  if (parsedDate.year != year ||
      parsedDate.month != month ||
      parsedDate.day != day) {
    return null;
  }

  return parsedDate;
}

String? _nonEmptyString(Object? value) {
  if (value is! String) {
    return null;
  }

  final String trimmed = value.trim();

  if (trimmed.isEmpty) {
    return null;
  }

  return trimmed;
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

String _normalizeBookCode(String value) {
  return value.trim().toUpperCase();
}

class ValidationReport {
  int fileCount = 0;
  int dayCount = 0;
  int readingCount = 0;
  int rangeCount = 0;
  int warningCount = 0;
  int errorCount = 0;

  void warning(String message) {
    warningCount++;

    stderr.writeln(
      'WARNING: $message',
    );
  }

  void error(String message) {
    errorCount++;

    stderr.writeln(
      'ERROR: $message',
    );
  }
}

class BibleIndex {
  BibleIndex({
    required this.booksByCode,
    required this.bookCount,
    required this.verseRecordCount,
  });

  final Map<String, BibleBook> booksByCode;

  final int bookCount;

  final int verseRecordCount;

  static BibleIndex load(File databaseFile) {
    final Database database = sqlite3.open(
      databaseFile.path,
      mode: OpenMode.readOnly,
    );

    try {
      final Set<String> tableNames = database
          .select(
            '''
SELECT name
FROM sqlite_master
WHERE type = 'table'
''',
          )
          .map(
            (Row row) =>
                row['name'].toString(),
          )
          .toSet();

      if (!tableNames.contains('bible_books')) {
        throw const FormatException(
          'The database has no bible_books table.',
        );
      }

      if (!tableNames.contains('bible_verses')) {
        throw const FormatException(
          'The database has no bible_verses table.',
        );
      }

      final ResultSet rows = database.select(
        '''
SELECT
  b.usfm_code,
  v.chapter,
  v.verse_start,
  v.verse_end,
  v.is_omitted
FROM bible_verses v
INNER JOIN bible_books b
  ON b.id = v.book_id
ORDER BY
  b.canonical_order,
  v.chapter,
  v.verse_start
''',
      );

      final Map<String, BibleBook> booksByCode =
          <String, BibleBook>{};

      int verseRecordCount = 0;

      for (final Row row in rows) {
        final String bookCode =
            _normalizeBookCode(
          row['usfm_code'].toString(),
        );

        final int? chapter = _integerValue(
          row['chapter'],
        );

        final int? verseStart = _integerValue(
          row['verse_start'],
        );

        final int? verseEnd = _integerValue(
          row['verse_end'],
        );

        if (chapter == null ||
            chapter < 1 ||
            verseStart == null ||
            verseStart < 1 ||
            verseEnd == null ||
            verseEnd < verseStart) {
          throw const FormatException(
            'A Bible verse contains invalid '
            'chapter or verse numbers.',
          );
        }

        final BibleBook book =
            booksByCode.putIfAbsent(
          bookCode,
          () => BibleBook(
            bookCode: bookCode,
          ),
        );

        final bool isOmitted =
            _databaseBoolean(
          row['is_omitted'],
        );

        for (int verse = verseStart;
            verse <= verseEnd;
            verse++) {
          book.addVerse(
            chapter: chapter,
            verse: verse,
            isOmitted: isOmitted,
          );
        }

        verseRecordCount++;
      }

      if (booksByCode.isEmpty) {
        throw const FormatException(
          'The Bible database contains no books.',
        );
      }

      if (verseRecordCount == 0) {
        throw const FormatException(
          'The Bible database contains no verses.',
        );
      }

      return BibleIndex(
        booksByCode: booksByCode,
        bookCount: booksByCode.length,
        verseRecordCount: verseRecordCount,
      );
    } finally {
      database.close();
    }
  }

  bool containsBook(String bookCode) {
    return booksByCode.containsKey(
      _normalizeBookCode(bookCode),
    );
  }

  bool containsChapter(
    String bookCode,
    int chapter,
  ) {
    final BibleBook? book = booksByCode[
        _normalizeBookCode(bookCode)];

    return book?.containsChapter(chapter) ??
        false;
  }

  bool containsVerse(
    String bookCode,
    int chapter,
    int verse,
  ) {
    final BibleBook? book = booksByCode[
        _normalizeBookCode(bookCode)];

    return book?.containsVerse(
          chapter,
          verse,
        ) ??
        false;
  }

  bool isOmittedVerse(
    String bookCode,
    int chapter,
    int verse,
  ) {
    final BibleBook? book = booksByCode[
        _normalizeBookCode(bookCode)];

    return book?.isOmittedVerse(
          chapter,
          verse,
        ) ??
        false;
  }

  static bool _databaseBoolean(
    Object? value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value
        .toString()
        .trim()
        .toLowerCase();

    return text == 'true' || text == '1';
  }
}

class BibleBook {
  BibleBook({
    required this.bookCode,
  });

  final String bookCode;

  final Map<int, Set<int>> versesByChapter =
      <int, Set<int>>{};

  final Set<String> omittedVerses =
      <String>{};

  void addVerse({
    required int chapter,
    required int verse,
    required bool isOmitted,
  }) {
    final Set<int> verses =
        versesByChapter.putIfAbsent(
      chapter,
      () => <int>{},
    );

    verses.add(verse);

    if (isOmitted) {
      omittedVerses.add(
        '$chapter:$verse',
      );
    }
  }

  bool containsChapter(int chapter) {
    return versesByChapter.containsKey(
      chapter,
    );
  }

  bool containsVerse(
    int chapter,
    int verse,
  ) {
    return versesByChapter[chapter]
            ?.contains(verse) ??
        false;
  }

  bool isOmittedVerse(
    int chapter,
    int verse,
  ) {
    return omittedVerses.contains(
      '$chapter:$verse',
    );
  }
}