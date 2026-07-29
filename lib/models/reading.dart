enum ReadingKind {
  firstReading,
  responsorialPsalm,
  secondReading,
  gospelAcclamation,
  gospel,
  other,
}

class DailyReading {
  const DailyReading({
    required this.kind,
    required this.title,
    required this.reference,
    required this.text,
    this.response,
  });

  final ReadingKind kind;
  final String title;
  final String reference;
  final String text;

  /// Used primarily for the repeated response in a Responsorial Psalm.
  final String? response;

  bool get hasReference => reference.trim().isNotEmpty;

  bool get hasResponse =>
      response != null && response!.trim().isNotEmpty;
}

class DailyReadings {
  const DailyReadings({
    required this.date,
    required this.liturgicalDay,
    required this.translationName,
    required this.translationAbbreviation,
    required this.translationNotice,
    required this.readings,
  });

  final DateTime date;
  final String liturgicalDay;

  final String translationName;
  final String translationAbbreviation;
  final String translationNotice;

  final List<DailyReading> readings;
}