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
  // It does not change which Bible verses are loaded.
  final int displayVerseOffset;

  bool get isSingleVerse => startVerse == endVerse;

  factory ScriptureRange.fromJson(
    Map<String, dynamic> json,
  ) {
    return ScriptureRange(
      bookCode: json['bookCode'] as String,
      chapter: (json['chapter'] as num).toInt(),
      startVerse: (json['startVerse'] as num).toInt(),
      endVerse: (json['endVerse'] as num).toInt(),
      displayVerseOffset:
          (json['displayVerseOffset'] as num?)?.toInt() ?? 0,
    );
  }
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

  factory LectionaryReadingReference.fromJson(
    Map<String, dynamic> json,
  ) {
    final String kindName = json['kind'] as String;

    final LectionaryReadingKind kind =
        LectionaryReadingKind.values.firstWhere(
      (LectionaryReadingKind value) =>
          value.name == kindName,
      orElse: () {
        throw FormatException(
          'Unknown lectionary reading kind: $kindName',
        );
      },
    );

    final List<dynamic> rangeData =
        json['ranges'] as List<dynamic>;

    return LectionaryReadingReference(
      kind: kind,
      title: json['title'] as String,
      displayReference:
          json['displayReference'] as String,
      ranges: rangeData
          .map(
            (dynamic item) => ScriptureRange.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      response: json['response'] as String?,
      choiceGroup: json['choiceGroup'] as String?,
      choiceLabel: json['choiceLabel'] as String?,
    );
  }
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

  factory LectionaryDayReferences.fromJson(
    Map<String, dynamic> json,
  ) {
    final List<dynamic> readingData =
        json['readings'] as List<dynamic>;

    return LectionaryDayReferences(
      date: DateTime.parse(json['date'] as String),
      liturgicalDay: json['liturgicalDay'] as String,
      readings: readingData
          .map(
            (dynamic item) =>
                LectionaryReadingReference.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }
}