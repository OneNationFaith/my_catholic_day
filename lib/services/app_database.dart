import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'my_catholic_day.db';
  static const int _databaseVersion = 1;

  sqflite.Database? _database;
  bool _desktopFactoryInitialized = false;

  Future<sqflite.Database> get database async {
    final existingDatabase = _database;

    if (existingDatabase != null && existingDatabase.isOpen) {
      return existingDatabase;
    }

    final openedDatabase = await _openDatabase();
    _database = openedDatabase;

    return openedDatabase;
  }

  Future<String> get databasePath async {
    final db = await database;
    return db.path;
  }

  Future<sqflite.Database> _openDatabase() async {
    _configureDatabaseFactory();

    final supportDirectory =
        await getApplicationSupportDirectory();

    final databaseDirectory = Directory(
      path.join(
        supportDirectory.path,
        'databases',
      ),
    );

    await databaseDirectory.create(
      recursive: true,
    );

    final fullDatabasePath = path.join(
      databaseDirectory.path,
      _databaseName,
    );

    return sqflite.openDatabase(
      fullDatabasePath,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON;',
        );
      },
      onCreate: _createSchema,
    );
  }

  void _configureDatabaseFactory() {
    final isDesktop =
        Platform.isWindows || Platform.isLinux;

    if (!isDesktop || _desktopFactoryInitialized) {
      return;
    }

    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;

    _desktopFactoryInitialized = true;
  }

  Future<void> _createSchema(
    sqflite.Database db,
    int version,
  ) async {
    final batch = db.batch();

    batch.execute(
      '''
      CREATE TABLE app_metadata (
        metadata_key TEXT PRIMARY KEY,
        metadata_value TEXT NOT NULL
      )
      ''',
    );

    batch.execute(
      '''
      CREATE TABLE bible_translations (
        translation_id TEXT PRIMARY KEY,
        abbreviation TEXT NOT NULL,
        name TEXT NOT NULL,
        language TEXT NOT NULL,
        license_name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
      ''',
    );

    batch.execute(
      '''
      CREATE TABLE bible_books (
        book_id INTEGER PRIMARY KEY AUTOINCREMENT,
        translation_id TEXT NOT NULL,
        book_number INTEGER NOT NULL,
        book_code TEXT NOT NULL,
        book_name TEXT NOT NULL,
        testament TEXT NOT NULL,
        chapter_count INTEGER NOT NULL DEFAULT 0,

        UNIQUE (
          translation_id,
          book_number
        ),

        UNIQUE (
          translation_id,
          book_code
        ),

        FOREIGN KEY (translation_id)
          REFERENCES bible_translations (
            translation_id
          )
          ON DELETE CASCADE
      )
      ''',
    );

    batch.execute(
      '''
      CREATE TABLE bible_verses (
        verse_id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter_number INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        verse_text TEXT NOT NULL,

        UNIQUE (
          book_id,
          chapter_number,
          verse_number
        ),

        FOREIGN KEY (book_id)
          REFERENCES bible_books (
            book_id
          )
          ON DELETE CASCADE
      )
      ''',
    );

    batch.execute(
      '''
      CREATE INDEX bible_verse_lookup
      ON bible_verses (
        book_id,
        chapter_number,
        verse_number
      )
      ''',
    );

    batch.execute(
      '''
      CREATE TABLE lectionary_days (
        date_key TEXT PRIMARY KEY,
        liturgical_day TEXT NOT NULL,
        cycle_name TEXT,
        liturgical_season TEXT,
        liturgical_color TEXT
      )
      ''',
    );

    batch.execute(
      '''
      CREATE TABLE lectionary_readings (
        reading_id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key TEXT NOT NULL,
        reading_kind TEXT NOT NULL,
        reading_title TEXT NOT NULL,
        reference_label TEXT NOT NULL,
        response_text TEXT,
        sort_order INTEGER NOT NULL,

        FOREIGN KEY (date_key)
          REFERENCES lectionary_days (
            date_key
          )
          ON DELETE CASCADE
      )
      ''',
    );

    batch.execute(
      '''
      CREATE INDEX lectionary_reading_lookup
      ON lectionary_readings (
        date_key,
        sort_order
      )
      ''',
    );

    batch.execute(
      '''
      CREATE TABLE lectionary_passages (
        passage_id INTEGER PRIMARY KEY AUTOINCREMENT,
        reading_id INTEGER NOT NULL,
        book_code TEXT NOT NULL,
        start_chapter INTEGER NOT NULL,
        start_verse INTEGER NOT NULL,
        end_chapter INTEGER NOT NULL,
        end_verse INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,

        FOREIGN KEY (reading_id)
          REFERENCES lectionary_readings (
            reading_id
          )
          ON DELETE CASCADE
      )
      ''',
    );

    batch.execute(
      '''
      CREATE INDEX lectionary_passage_lookup
      ON lectionary_passages (
        reading_id,
        sort_order
      )
      ''',
    );

    await batch.commit(
      noResult: true,
    );

    await db.insert(
      'app_metadata',
      {
        'metadata_key': 'schema_version',
        'metadata_value': version.toString(),
      },
    );

    await db.insert(
      'bible_translations',
      {
        'translation_id': 'webc',
        'abbreviation': 'WEBC',
        'name':
            'World English Bible, Catholic Edition',
        'language': 'English',
        'license_name': 'Public Domain',
        'is_active': 1,
      },
    );
  }

  Future<String?> getMetadata(
    String key,
  ) async {
    final db = await database;

    final results = await db.query(
      'app_metadata',
      columns: [
        'metadata_value',
      ],
      where: 'metadata_key = ?',
      whereArgs: [
        key,
      ],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first['metadata_value']
        as String?;
  }

  Future<void> setMetadata({
    required String key,
    required String value,
  }) async {
    final db = await database;

    await db.insert(
      'app_metadata',
      {
        'metadata_key': key,
        'metadata_value': value,
      },
      conflictAlgorithm:
          sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = _database;

    if (db != null && db.isOpen) {
      await db.close();
    }

    _database = null;
  }
}