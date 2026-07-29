import '../../models/scripture_passage.dart';
import '../../models/scripture_verse.dart';
import '../../services/scripture_database.dart';

class ScriptureRepository {
  ScriptureRepository({
    ScriptureDatabase? database,
  }) : _database = database ?? ScriptureDatabase.instance;

  final ScriptureDatabase _database;

  Future<List<ScriptureVerse>> getPassage({
    required String bookCode,
    required int chapter,
    required int startVerse,
    required int endVerse,
  }) async {
    final database = await _database.database;

    final List<Map<String, Object?>> rows =
        await database.rawQuery(
      '''
      SELECT
        bible_books.usfm_code AS book_code,
        bible_books.name AS book_name,
        bible_verses.chapter AS chapter,
        bible_verses.verse_label AS verse_label,
        bible_verses.verse_start AS verse_start,
        bible_verses.verse_end AS verse_end,
        bible_verses.text AS text,
        bible_verses.is_omitted AS is_omitted
      FROM bible_verses
      INNER JOIN bible_books
        ON bible_books.id = bible_verses.book_id
      WHERE bible_books.usfm_code = ?
        AND bible_verses.chapter = ?
        AND bible_verses.verse_end >= ?
        AND bible_verses.verse_start <= ?
      ORDER BY
        bible_verses.verse_start,
        bible_verses.verse_end
      ''',
      <Object?>[
        bookCode.toUpperCase(),
        chapter,
        startVerse,
        endVerse,
      ],
    );

    return rows
        .map(ScriptureVerse.fromDatabaseRow)
        .toList(growable: false);
  }

  Future<ScripturePassage> getScripturePassage({
    required String bookCode,
    required int chapter,
    required int startVerse,
    required int endVerse,
    int displayVerseOffset = 0,
  }) async {
    final List<ScriptureVerse> verses = await getPassage(
      bookCode: bookCode,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
    );

    return ScripturePassage.fromVerses(
      bookCode: bookCode.toUpperCase(),
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
      verses: verses,
      displayVerseOffset: displayVerseOffset,
    );
  }

  Future<ScriptureVerse?> getVerse({
    required String bookCode,
    required int chapter,
    required int verse,
  }) async {
    final List<ScriptureVerse> results = await getPassage(
      bookCode: bookCode,
      chapter: chapter,
      startVerse: verse,
      endVerse: verse,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  Future<List<String>> getBookCodes() async {
    final database = await _database.database;

    final List<Map<String, Object?>> rows =
        await database.rawQuery(
      '''
      SELECT usfm_code
      FROM bible_books
      ORDER BY canonical_order
      ''',
    );

    return rows
        .map((row) => row['usfm_code'] as String)
        .toList(growable: false);
  }

  Future<int> getBookCount() async {
    final database = await _database.database;

    final List<Map<String, Object?>> rows =
        await database.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM bible_books
      ''',
    );

    return (rows.first['count'] as num).toInt();
  }

  Future<int> getVerseCount() async {
    final database = await _database.database;

    final List<Map<String, Object?>> rows =
        await database.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM bible_verses
      ''',
    );

    return (rows.first['count'] as num).toInt();
  }
}