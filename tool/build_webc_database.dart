import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const int webcTranslationId = 1;

const Set<String> deuterocanonicalBookCodes = {
  'TOB',
  'JDT',
  'ESG',
  'WIS',
  'SIR',
  'BAR',
  '1MA',
  '2MA',
  'DAG',
};

const Set<String> continuationMarkers = {
  'p',
  'm',
  'mi',
  'nb',
  'pc',
  'pi1',
  'q1',
  'q2',
  'q3',
  'li1',
  'qs',
  'bk',
  'wj',
  'w',
  '+bk',
  '+w',
  '+wh',
};

Future<void> main() async {
  sqfliteFfiInit();

  final String projectRoot = Directory.current.path;

  final Directory sourceDirectory = Directory(
    path.join(projectRoot, 'tool', 'source', 'webc', 'usfm_extracted'),
  );

  final String outputDatabasePath = path.join(
    projectRoot,
    'assets',
    'databases',
    'webc.db',
  );

  if (!await sourceDirectory.exists()) {
    stderr.writeln(
      'The WEBC source folder was not found:\n'
      '${sourceDirectory.path}',
    );
    exitCode = 1;
    return;
  }

  final List<File> usfmFiles =
      sourceDirectory
          .listSync()
          .whereType<File>()
          .where(
            (File file) => path.extension(file.path).toLowerCase() == '.usfm',
          )
          .toList()
        ..sort(
          (File first, File second) =>
              path.basename(first.path).compareTo(path.basename(second.path)),
        );

  if (usfmFiles.length != 73) {
    stderr.writeln(
      'Expected 73 Catholic Bible book files, '
      'but found ${usfmFiles.length}.',
    );
    exitCode = 1;
    return;
  }

  await Directory(path.dirname(outputDatabasePath)).create(recursive: true);

  await _deleteExistingDatabase(outputDatabasePath);

  stdout.writeln('Building the WEBC offline Bible database...');
  stdout.writeln('Source: ${sourceDirectory.path}');
  stdout.writeln('Output: $outputDatabasePath');
  stdout.writeln('');

  final Database database = await databaseFactoryFfi.openDatabase(
    outputDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (Database database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database database, int version) async {
        await _createSchema(database);
      },
    ),
  );

  try {
    await database.transaction((Transaction transaction) async {
      await _insertTranslation(transaction);
      await _insertMetadata(transaction);

      int canonicalOrder = 0;
      int totalVerseCount = 0;

      for (final File file in usfmFiles) {
        canonicalOrder++;

        final ParsedBook book = await _parseUsfmBook(file, canonicalOrder);

        final int bookId = await transaction
            .insert('bible_books', <String, Object?>{
              'translation_id': webcTranslationId,
              'canonical_order': book.canonicalOrder,
              'usfm_code': book.code,
              'name': book.name,
              'full_name': book.fullName,
              'short_name': book.shortName,
              'testament': book.testament,
              'is_deuterocanonical': book.isDeuterocanonical ? 1 : 0,
            });

        final Batch batch = transaction.batch();

        for (final ParsedVerse verse in book.verses) {
          batch.insert('bible_verses', <String, Object?>{
            'translation_id': webcTranslationId,
            'book_id': bookId,
            'chapter': verse.chapter,
            'verse_label': verse.label,
            'verse_start': verse.startVerse,
            'verse_end': verse.endVerse,
            'text': verse.text,
            'is_omitted': verse.isOmitted ? 1 : 0,
          });
        }

        await batch.commit(noResult: true);

        totalVerseCount += book.verses.length;

        stdout.writeln(
          '${book.canonicalOrder.toString().padLeft(2)}. '
          '${book.name.padRight(24)} '
          '${book.verses.length} verses',
        );
      }

      await transaction.insert('database_metadata', <String, Object?>{
        'metadata_key': 'book_count',
        'metadata_value': canonicalOrder.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await transaction.insert('database_metadata', <String, Object?>{
        'metadata_key': 'verse_count',
        'metadata_value': totalVerseCount.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    await _verifyDatabase(database);

    stdout.writeln('');
    stdout.writeln('WEBC database created successfully.');
    stdout.writeln(outputDatabasePath);
  } catch (error, stackTrace) {
    stderr.writeln('');
    stderr.writeln('The database could not be created.');
    stderr.writeln(error);
    stderr.writeln(stackTrace);

    exitCode = 1;
  } finally {
    await database.close();
  }
}

Future<void> _createSchema(Database database) async {
  await database.execute('''
    CREATE TABLE database_metadata (
      metadata_key TEXT NOT NULL PRIMARY KEY,
      metadata_value TEXT NOT NULL
    )
  ''');

  await database.execute('''
    CREATE TABLE bible_translations (
      id INTEGER NOT NULL PRIMARY KEY,
      abbreviation TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      language_code TEXT NOT NULL,
      source_format TEXT NOT NULL,
      source_url TEXT NOT NULL,
      display_notice TEXT NOT NULL
    )
  ''');

  await database.execute('''
    CREATE TABLE bible_books (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      translation_id INTEGER NOT NULL,
      canonical_order INTEGER NOT NULL,
      usfm_code TEXT NOT NULL,
      name TEXT NOT NULL,
      full_name TEXT NOT NULL,
      short_name TEXT NOT NULL,
      testament TEXT NOT NULL,
      is_deuterocanonical INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (translation_id)
        REFERENCES bible_translations (id),
      UNIQUE (translation_id, canonical_order),
      UNIQUE (translation_id, usfm_code)
    )
  ''');

  await database.execute('''
    CREATE TABLE bible_verses (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      translation_id INTEGER NOT NULL,
      book_id INTEGER NOT NULL,
      chapter INTEGER NOT NULL,
      verse_label TEXT NOT NULL,
      verse_start INTEGER NOT NULL,
      verse_end INTEGER NOT NULL,
      text TEXT NOT NULL,
      is_omitted INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (translation_id)
        REFERENCES bible_translations (id),
      FOREIGN KEY (book_id)
        REFERENCES bible_books (id),
      UNIQUE (
        translation_id,
        book_id,
        chapter,
        verse_label
      )
    )
  ''');

  await database.execute('''
    CREATE INDEX bible_books_order_index
    ON bible_books (
      translation_id,
      canonical_order
    )
  ''');

  await database.execute('''
    CREATE INDEX bible_verses_reference_index
    ON bible_verses (
      translation_id,
      book_id,
      chapter,
      verse_start,
      verse_end
    )
  ''');
}

Future<void> _insertTranslation(Transaction transaction) async {
  await transaction.insert('bible_translations', <String, Object?>{
    'id': webcTranslationId,
    'abbreviation': 'WEBC',
    'name': 'World English Bible, Catholic Edition',
    'language_code': 'en',
    'source_format': 'USFM',
    'source_url': 'https://ebible.org/eng-web-c/',
    'display_notice':
        'Scripture text is from the World English Bible, '
        'Catholic Edition. Wording may differ from the '
        'official Lectionary used at Mass in the United States.',
  });
}

Future<void> _insertMetadata(Transaction transaction) async {
  final String createdAt = DateTime.now().toUtc().toIso8601String();

  final Map<String, String> metadata = {
    'database_name': 'My Catholic Day WEBC Bible',
    'database_version': '1',
    'translation': 'WEBC',
    'source_format': 'USFM',
    'created_at_utc': createdAt,
  };

  for (final MapEntry<String, String> entry in metadata.entries) {
    await transaction.insert('database_metadata', <String, Object?>{
      'metadata_key': entry.key,
      'metadata_value': entry.value,
    });
  }
}

Future<ParsedBook> _parseUsfmBook(File file, int canonicalOrder) async {
  String source = await file.readAsString();

  source = source.replaceAll('\r\n', '\n');
  source = source.replaceAll('\r', '\n');

  source = source.replaceAll(RegExp(r'\\f\b.*?\\f\*', dotAll: true), '');

  source = source.replaceAll(RegExp(r'\\x\b.*?\\x\*', dotAll: true), '');

  final List<String> lines = source.split('\n');

  final String code =
      _readHeaderMarker(lines, 'id')?.split(' ').first ??
      _codeFromFilename(file.path);

  final String name =
      _readHeaderMarker(lines, 'toc2') ?? _readHeaderMarker(lines, 'h') ?? code;

  final String fullName = _readHeaderMarker(lines, 'toc1') ?? name;

  final String shortName = _readHeaderMarker(lines, 'toc3') ?? name;

  final List<ParsedVerse> verses = [];

  int currentChapter = 0;
  ParsedVerseBuilder? currentVerse;

  for (final String originalLine in lines) {
    final String line = originalLine.trim();

    if (line.isEmpty) {
      continue;
    }

    final RegExpMatch? chapterMatch = RegExp(r'^\\c\s+(\d+)').firstMatch(line);

    if (chapterMatch != null) {
      _finishVerse(currentVerse, verses);
      currentVerse = null;

      currentChapter = int.parse(chapterMatch.group(1)!);

      continue;
    }

    final RegExpMatch? verseMatch = RegExp(
      r'^\\v\s+([0-9]+(?:[-–][0-9]+)?[a-z]?)\s*(.*)$',
    ).firstMatch(line);

    if (verseMatch != null) {
      _finishVerse(currentVerse, verses);

      if (currentChapter == 0) {
        throw FormatException(
          'A verse appeared before a chapter marker '
          'in ${path.basename(file.path)}.',
        );
      }

      final String label = verseMatch.group(1)!;
      final VerseRange range = _parseVerseRange(label);
      final String verseText = _cleanInlineText(verseMatch.group(2) ?? '');

      currentVerse = ParsedVerseBuilder(
        chapter: currentChapter,
        label: label,
        startVerse: range.start,
        endVerse: range.end,
      );

      currentVerse.append(verseText);
      continue;
    }

    if (currentVerse == null) {
      continue;
    }

    final RegExpMatch? markerMatch = RegExp(
      r'^\\(\+?[A-Za-z][A-Za-z0-9]*)(?:\*)?\s*(.*)$',
    ).firstMatch(line);

    if (markerMatch != null) {
      final String marker = markerMatch.group(1)!;

      if (continuationMarkers.contains(marker)) {
        currentVerse.append(_cleanInlineText(markerMatch.group(2) ?? ''));
      }

      continue;
    }

    if (!line.startsWith(r'\')) {
      currentVerse.append(_cleanInlineText(line));
    }
  }

  _finishVerse(currentVerse, verses);

  if (verses.isEmpty) {
    throw FormatException(
      'No verses were found in '
      '${path.basename(file.path)}.',
    );
  }

  return ParsedBook(
    code: code,
    name: name,
    fullName: fullName,
    shortName: shortName,
    canonicalOrder: canonicalOrder,
    testament: canonicalOrder <= 46 ? 'Old Testament' : 'New Testament',
    isDeuterocanonical: deuterocanonicalBookCodes.contains(code),
    verses: verses,
  );
}

void _finishVerse(ParsedVerseBuilder? builder, List<ParsedVerse> verses) {
  if (builder == null) {
    return;
  }

  final String finalText = builder.text.trim();

  verses.add(
    ParsedVerse(
      chapter: builder.chapter,
      label: builder.label,
      startVerse: builder.startVerse,
      endVerse: builder.endVerse,
      text: finalText,
      isOmitted: finalText.isEmpty,
    ),
  );
}

String _cleanInlineText(String input) {
  String text = input;

  text = text.replaceAll(
    RegExp(
      r'\|[A-Za-z][A-Za-z0-9_-]*="[^"]*"'
      r'(?:\s+[A-Za-z][A-Za-z0-9_-]*="[^"]*")*',
    ),
    '',
  );

  text = text.replaceAll(RegExp(r'\\\+?[A-Za-z][A-Za-z0-9]*\*?'), '');

  text = text.replaceAll('\u00A0', ' ');
  text = text.replaceAll('\u200B', '');

  text = text.replaceAll(RegExp(r'[ \t\n]+'), ' ');
  text = text.replaceAllMapped(
    RegExp(r"([’'])\s+([A-Za-z])"),
    (Match match) => '${match.group(1)}${match.group(2)}',
  );
  text = text.replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1');

  return text.trim();
}

String? _readHeaderMarker(List<String> lines, String marker) {
  final RegExp expression = RegExp('^\\\\$marker\\s+(.+)\$');

  for (final String originalLine in lines) {
    final String line = originalLine.trim();
    final RegExpMatch? match = expression.firstMatch(line);

    if (match != null) {
      return _cleanInlineText(match.group(1)!.trim());
    }
  }

  return null;
}

String _codeFromFilename(String filePath) {
  final String filename = path.basename(filePath);

  final RegExpMatch? match = RegExp(r'^\d+-([A-Z0-9]{3})').firstMatch(filename);

  if (match == null) {
    throw FormatException('Could not determine the book code from $filename.');
  }

  return match.group(1)!;
}

VerseRange _parseVerseRange(String label) {
  final String normalized = label.replaceAll('–', '-');

  final RegExpMatch? match = RegExp(
    r'^(\d+)(?:-(\d+))?',
  ).firstMatch(normalized);

  if (match == null) {
    throw FormatException('Unsupported verse label: $label');
  }

  final int start = int.parse(match.group(1)!);
  final int end = match.group(2) == null ? start : int.parse(match.group(2)!);

  return VerseRange(start: start, end: end);
}

Future<void> _verifyDatabase(Database database) async {
  final List<Map<String, Object?>> bookCountRows = await database.rawQuery(
    'SELECT COUNT(*) AS count FROM bible_books',
  );

  final int bookCount = (bookCountRows.first['count'] as num?)?.toInt() ?? 0;

  final List<Map<String, Object?>> verseCountRows = await database.rawQuery(
    'SELECT COUNT(*) AS count FROM bible_verses',
  );

  final int verseCount = (verseCountRows.first['count'] as num?)?.toInt() ?? 0;

  if (bookCount != 73) {
    throw StateError(
      'Database verification failed. '
      'Expected 73 books but found $bookCount.',
    );
  }

  if (verseCount < 30000) {
    throw StateError(
      'Database verification failed. '
      'Only $verseCount verses were imported.',
    );
  }

  final List<Map<String, Object?>> genesis = await database.rawQuery(
    '''
        SELECT bible_verses.text
        FROM bible_verses
        INNER JOIN bible_books
          ON bible_books.id = bible_verses.book_id
        WHERE bible_books.usfm_code = ?
          AND bible_verses.chapter = ?
          AND bible_verses.verse_start = ?
        LIMIT 1
      ''',
    <Object?>['GEN', 1, 1],
  );

  if (genesis.isEmpty) {
    throw StateError(
      'Database verification failed. '
      'Genesis 1:1 was not found.',
    );
  }

  stdout.writeln('');
  stdout.writeln('Verification complete:');
  stdout.writeln('Books: $bookCount');
  stdout.writeln('Verses: $verseCount');
  stdout.writeln('Genesis 1:1: ${genesis.first['text']}');
}

Future<void> _deleteExistingDatabase(String databasePath) async {
  final List<String> possibleFiles = [
    databasePath,
    '$databasePath-shm',
    '$databasePath-wal',
    '$databasePath-journal',
  ];

  for (final String filePath in possibleFiles) {
    final File file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}

class ParsedBook {
  const ParsedBook({
    required this.code,
    required this.name,
    required this.fullName,
    required this.shortName,
    required this.canonicalOrder,
    required this.testament,
    required this.isDeuterocanonical,
    required this.verses,
  });

  final String code;
  final String name;
  final String fullName;
  final String shortName;
  final int canonicalOrder;
  final String testament;
  final bool isDeuterocanonical;
  final List<ParsedVerse> verses;
}

class ParsedVerse {
  const ParsedVerse({
    required this.chapter,
    required this.label,
    required this.startVerse,
    required this.endVerse,
    required this.text,
    required this.isOmitted,
  });

  final int chapter;
  final String label;
  final int startVerse;
  final int endVerse;
  final String text;
  final bool isOmitted;
}

class ParsedVerseBuilder {
  ParsedVerseBuilder({
    required this.chapter,
    required this.label,
    required this.startVerse,
    required this.endVerse,
  });

  final int chapter;
  final String label;
  final int startVerse;
  final int endVerse;

  final StringBuffer _buffer = StringBuffer();

  String get text => _buffer.toString();

  void append(String value) {
    final String cleaned = value.trim();

    if (cleaned.isEmpty) {
      return;
    }

    if (_buffer.isNotEmpty) {
      _buffer.write(' ');
    }

    _buffer.write(cleaned);
  }
}

class VerseRange {
  const VerseRange({required this.start, required this.end});

  final int start;
  final int end;
}
