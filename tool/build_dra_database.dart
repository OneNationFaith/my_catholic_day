import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

const Map<String, String> sourceCodeByAppCode = {
  'SNG': 'SOL',
  'EZK': 'EZE',
  'JOL': 'JOE',
  'NAM': 'NAH',
  'ESG': 'EST',
  'DAG': 'DAN',
  'MRK': 'MAR',
  'JHN': 'JOH',
  'PHP': 'PHI',
  'JAS': 'JAM',
  '1JN': '1JO',
  '2JN': '2JO',
  '3JN': '3JO',
};

void main() {
  final String projectRoot = Directory.current.path;

  final String sourcePath = path.join(
    projectRoot,
    'tool',
    'data',
    'douay_rheims',
    'source',
    'engDRA_vpl.txt',
  );

  final String oldDatabasePath = path.join(
    projectRoot,
    'assets',
    'databases',
    'webc.db',
  );

  final String outputPath = path.join(
    projectRoot,
    'assets',
    'databases',
    'dra.db',
  );

  final File sourceFile = File(sourcePath);

  if (!sourceFile.existsSync()) {
    stderr.writeln('Douay-Rheims source file not found.');
    exitCode = 1;
    return;
  }

  final Map<String, List<VerseRecord>> sourceBooks = {};

  for (final String originalLine in sourceFile.readAsLinesSync()) {
    final String line = originalLine.trim();

    if (line.isEmpty) {
      continue;
    }

    final RegExpMatch? match = RegExp(
      r'^([A-Z0-9]+)\s+(\d+):(\d+(?:-\d+)?)\s+(.*)$',
    ).firstMatch(line);

    if (match == null) {
      throw FormatException(
        'Could not parse source line:\n$line',
      );
    }

    final String bookCode = match.group(1)!;
    final int chapter = int.parse(match.group(2)!);
    final String verseLabel = match.group(3)!;
    final String text = match.group(4)!.trim();

    final List<String> verseParts = verseLabel.split('-');

    final int verseStart = int.parse(verseParts.first);
    final int verseEnd = verseParts.length == 1
        ? verseStart
        : int.parse(verseParts.last);

    sourceBooks.putIfAbsent(
      bookCode,
      () => <VerseRecord>[],
    );

    sourceBooks[bookCode]!.add(
      VerseRecord(
        chapter: chapter,
        label: verseLabel,
        startVerse: verseStart,
        endVerse: verseEnd,
        text: text,
      ),
    );
  }

  final int sourceVerseCount = sourceBooks.values
      .fold<int>(
        0,
        (int total, List<VerseRecord> verses) =>
            total + verses.length,
      );

  stdout.writeln(
    'Douay-Rheims source verses: $sourceVerseCount',
  );

  if (sourceBooks.length != 73) {
    throw StateError(
      'Expected 73 source books but found '
      '${sourceBooks.length}.',
    );
  }

  if (File(outputPath).existsSync()) {
    File(outputPath).deleteSync();
  }

  final Database oldDatabase = sqlite3.open(
    oldDatabasePath,
    mode: OpenMode.readOnly,
  );

  final Database database = sqlite3.open(outputPath);

  try {
    _createSchema(database);

    database.execute('BEGIN TRANSACTION');

    database.execute(
      '''
      INSERT INTO bible_translations (
        id,
        abbreviation,
        name,
        language_code,
        source_format,
        source_url,
        display_notice
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        1,
        'DRA',
        'Douay-Rheims 1899 American Edition',
        'en',
        'VPL',
        'https://ebible.org/engDRA/',
        'Scripture text is from the public-domain '
            'Douay-Rheims 1899 American Edition. '
            'Wording may differ from the official Lectionary '
            'used at Mass in the United States.',
      ],
    );

    final List<Row> oldBooks = oldDatabase.select(
      '''
      SELECT
        canonical_order,
        usfm_code,
        name,
        full_name,
        short_name,
        testament,
        is_deuterocanonical
      FROM bible_books
      ORDER BY canonical_order
      ''',
    );

    if (oldBooks.length != 73) {
      throw StateError(
        'Expected 73 template books but found '
        '${oldBooks.length}.',
      );
    }

    int insertedVerseCount = 0;

    for (final Row oldBook in oldBooks) {
      final String appCode =
          oldBook['usfm_code'] as String;

      final String sourceCode =
          sourceCodeByAppCode[appCode] ?? appCode;

      final List<VerseRecord>? verses =
          sourceBooks[sourceCode];

      if (verses == null) {
        throw StateError(
          'No Douay-Rheims source found for '
          '$appCode -> $sourceCode.',
        );
      }

      database.execute(
        '''
        INSERT INTO bible_books (
          translation_id,
          canonical_order,
          usfm_code,
          name,
          full_name,
          short_name,
          testament,
          is_deuterocanonical
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          1,
          oldBook['canonical_order'],
          appCode,
          oldBook['name'],
          oldBook['full_name'],
          oldBook['short_name'],
          oldBook['testament'],
          oldBook['is_deuterocanonical'],
        ],
      );

      final int bookId = database.lastInsertRowId;

      for (final VerseRecord verse in verses) {
        database.execute(
          '''
          INSERT INTO bible_verses (
            translation_id,
            book_id,
            chapter,
            verse_label,
            verse_start,
            verse_end,
            text,
            is_omitted
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, 0)
          ''',
          <Object?>[
            1,
            bookId,
            verse.chapter,
            verse.label,
            verse.startVerse,
            verse.endVerse,
            verse.text,
          ],
        );

        insertedVerseCount++;
      }

      // The existing lectionary represents Esther's
      // Catholic addition as ESG 4:29-42.
      // Douay-Rheims places the same passage at Esther 14:1-14.
      if (appCode == 'ESG') {
        final List<VerseRecord> estherPrayer = verses
            .where(
              (VerseRecord verse) =>
                  verse.chapter == 14 &&
                  verse.startVerse >= 1 &&
                  verse.startVerse <= 14,
            )
            .toList();

        if (estherPrayer.length != 14) {
          throw StateError(
            'Expected Esther 14:1-14 for '
            'the lectionary compatibility mapping.',
          );
        }

        for (final VerseRecord verse in estherPrayer) {
          final int aliasVerse = verse.startVerse + 28;

          database.execute(
            '''
            INSERT INTO bible_verses (
              translation_id,
              book_id,
              chapter,
              verse_label,
              verse_start,
              verse_end,
              text,
              is_omitted
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, 0)
            ''',
            <Object?>[
              1,
              bookId,
              4,
              aliasVerse.toString(),
              aliasVerse,
              aliasVerse,
              verse.text,
            ],
          );

          insertedVerseCount++;
        }
      }

      stdout.writeln(
        '${oldBook['canonical_order']}. '
        '$appCode <- $sourceCode '
        '(${verses.length} verses)',
      );
    }

    final Map<String, String> metadata = {
      'database_name': 'One Nation Faith Douay-Rheims Bible',
      'database_version': '1',
      'translation': 'DRA',
      'source_format': 'VPL',
      'created_at_utc':
          DateTime.now().toUtc().toIso8601String(),
      'book_count': '73',
      'verse_count': insertedVerseCount.toString(),
    };

    for (final MapEntry<String, String> entry
        in metadata.entries) {
      database.execute(
        '''
        INSERT INTO database_metadata (
          metadata_key,
          metadata_value
        )
        VALUES (?, ?)
        ''',
        <Object?>[
          entry.key,
          entry.value,
        ],
      );
    }

    database.execute('COMMIT');

    _verifyDatabase(database);

    stdout.writeln('');
    stdout.writeln(
      'Douay-Rheims database created successfully.',
    );
    stdout.writeln(outputPath);
  } catch (error, stackTrace) {
    try {
      database.execute('ROLLBACK');
    } catch (_) {}

    stderr.writeln('');
    stderr.writeln('Database build failed.');
    stderr.writeln(error);
    stderr.writeln(stackTrace);

    exitCode = 1;
  } finally {
    oldDatabase.close();
    database.close();
  }
}

void _createSchema(Database database) {
  database.execute('''
    CREATE TABLE database_metadata (
      metadata_key TEXT NOT NULL PRIMARY KEY,
      metadata_value TEXT NOT NULL
    )
  ''');

  database.execute('''
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

  database.execute('''
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

  database.execute('''
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

  database.execute('''
    CREATE INDEX bible_books_order_index
    ON bible_books (
      translation_id,
      canonical_order
    )
  ''');

  database.execute('''
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

void _verifyDatabase(Database database) {
  final int bookCount =
      database.select(
        'SELECT COUNT(*) AS count FROM bible_books',
      ).first['count'] as int;

  final int verseCount =
      database.select(
        'SELECT COUNT(*) AS count FROM bible_verses',
      ).first['count'] as int;

  if (bookCount != 73) {
    throw StateError(
      'Verification failed: $bookCount books.',
    );
  }

  if (verseCount < 35000) {
    throw StateError(
      'Verification failed: only $verseCount verses.',
    );
  }

  final Row genesis = database.select(
    '''
    SELECT bible_verses.text
    FROM bible_verses
    INNER JOIN bible_books
      ON bible_books.id = bible_verses.book_id
    WHERE bible_books.usfm_code = 'GEN'
      AND bible_verses.chapter = 1
      AND bible_verses.verse_start = 1
    LIMIT 1
    ''',
  ).first;

  final Row esther = database.select(
    '''
    SELECT bible_verses.text
    FROM bible_verses
    INNER JOIN bible_books
      ON bible_books.id = bible_verses.book_id
    WHERE bible_books.usfm_code = 'ESG'
      AND bible_verses.chapter = 4
      AND bible_verses.verse_start = 29
    LIMIT 1
    ''',
  ).first;

  final Row daniel = database.select(
    '''
    SELECT bible_verses.text
    FROM bible_verses
    INNER JOIN bible_books
      ON bible_books.id = bible_verses.book_id
    WHERE bible_books.usfm_code = 'DAG'
      AND bible_verses.chapter = 13
      AND bible_verses.verse_start = 62
    LIMIT 1
    ''',
  ).first;

  stdout.writeln('');
  stdout.writeln('Verification complete:');
  stdout.writeln('Books: $bookCount');
  stdout.writeln('Verses: $verseCount');
  stdout.writeln('Genesis 1:1: ${genesis['text']}');
  stdout.writeln('ESG 4:29: ${esther['text']}');
  stdout.writeln('DAG 13:62: ${daniel['text']}');
}

class VerseRecord {
  const VerseRecord({
    required this.chapter,
    required this.label,
    required this.startVerse,
    required this.endVerse,
    required this.text,
  });

  final int chapter;
  final String label;
  final int startVerse;
  final int endVerse;
  final String text;
}

