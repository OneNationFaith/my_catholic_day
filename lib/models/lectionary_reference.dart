enum LectionaryReadingKind {
  firstReading,
  responsorialPsalm,
  secondReading,
  gospelAcclamation,
  gospel,
}

class ScriptureRange {
  const ScriptureRange({
    required this.bookCode,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    this.displayVerseOffset = 0,
  });

  final String bookCode;
  final int chapter;
  final int startVerse;
  final int endVerse;

  // Changes only the verse numbers displayed in the app.
  // It does not change which verses are loaded.
  final int displayVerseOffset;

  bool get isSingleVerse => startVerse == endVerse;
}

class LectionaryReadingReference {
  const LectionaryReadingReference({
    required this.kind,
    required this.title,
    required this.displayReference,
    required this.ranges,
    this.response,
    this.choiceGroup,
    this.choiceLabel,
  });

  final LectionaryReadingKind kind;
  final String title;

  final String displayReference;
  final List<ScriptureRange> ranges;

  final String? response;

  final String? choiceGroup;
  final String? choiceLabel;

  bool get hasResponse =>
      response != null && response!.trim().isNotEmpty;

  bool get isChoice =>
      choiceGroup != null && choiceGroup!.trim().isNotEmpty;
}

class LectionaryDayReferences {
  const LectionaryDayReferences({
    required this.date,
    required this.liturgicalDay,
    required this.readings,
  });

  final DateTime date;
  final String liturgicalDay;
  final List<LectionaryReadingReference> readings;
}