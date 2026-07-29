import 'scripture_verse.dart';

class ScripturePassage {
  const ScripturePassage({
    required this.bookCode,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.verses,
    this.displayVerseOffset = 0,
  });

  final String bookCode;
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final List<ScriptureVerse> verses;

  // Used when a displayed Catholic reference numbers verses
  // differently from the Bible translation stored in the database.
  final int displayVerseOffset;

  bool get isEmpty => verses.isEmpty;

  String get reference {
    final int displayedStartVerse =
        startVerse + displayVerseOffset;
    final int displayedEndVerse =
        endVerse + displayVerseOffset;

    if (displayedStartVerse == displayedEndVerse) {
      return '$bookName $chapter:$displayedStartVerse';
    }

    return '$bookName $chapter:'
        '$displayedStartVerse–$displayedEndVerse';
  }

  String get text {
    return verses.map((ScriptureVerse verse) {
      final String displayedVerseLabel =
          _shiftVerseLabel(verse.verseLabel);

      if (verse.isOmitted) {
        return '$displayedVerseLabel '
            '[Verse omitted in this edition]';
      }

      return '$displayedVerseLabel ${verse.text}';
    }).join('\n\n');
  }

  String _shiftVerseLabel(String originalLabel) {
    if (displayVerseOffset == 0) {
      return originalLabel;
    }

    return originalLabel.replaceAllMapped(
      RegExp(r'\d+'),
      (Match match) {
        final int originalNumber =
            int.parse(match.group(0)!);

        return (
          originalNumber + displayVerseOffset
        ).toString();
      },
    );
  }

  factory ScripturePassage.fromVerses({
    required String bookCode,
    required int chapter,
    required int startVerse,
    required int endVerse,
    required List<ScriptureVerse> verses,
    int displayVerseOffset = 0,
  }) {
    final String bookName =
        verses.isEmpty ? bookCode : verses.first.bookName;

    return ScripturePassage(
      bookCode: bookCode,
      bookName: bookName,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
      verses: List<ScriptureVerse>.unmodifiable(verses),
      displayVerseOffset: displayVerseOffset,
    );
  }
}