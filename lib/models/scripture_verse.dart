class ScriptureVerse {
  const ScriptureVerse({
    required this.bookCode,
    required this.bookName,
    required this.chapter,
    required this.verseLabel,
    required this.verseStart,
    required this.verseEnd,
    required this.text,
    required this.isOmitted,
  });

  final String bookCode;
  final String bookName;
  final int chapter;
  final String verseLabel;
  final int verseStart;
  final int verseEnd;
  final String text;
  final bool isOmitted;

  String get reference {
    return '$bookName $chapter:$verseLabel';
  }

  factory ScriptureVerse.fromDatabaseRow(
    Map<String, Object?> row,
  ) {
    return ScriptureVerse(
      bookCode: row['book_code'] as String,
      bookName: row['book_name'] as String,
      chapter: (row['chapter'] as num).toInt(),
      verseLabel: row['verse_label'] as String,
      verseStart: (row['verse_start'] as num).toInt(),
      verseEnd: (row['verse_end'] as num).toInt(),
      text: row['text'] as String,
      isOmitted: (row['is_omitted'] as num).toInt() == 1,
    );
  }
}