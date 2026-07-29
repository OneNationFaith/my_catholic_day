import '../../models/lectionary_reference.dart';

class LectionaryReferenceRepository {
  const LectionaryReferenceRepository();

  static final Map<String, LectionaryDayReferences> _days =
      <String, LectionaryDayReferences>{
    '2026-07-29': LectionaryDayReferences(
      date: DateTime(2026, 7, 29),
      liturgicalDay:
          'Memorial of Saints Martha, Mary, and Lazarus',
      readings: const <LectionaryReadingReference>[
        LectionaryReadingReference(
          kind: LectionaryReadingKind.firstReading,
          title: 'First Reading',
          displayReference: 'Jeremiah 15:10, 16–21',
          ranges: <ScriptureRange>[
            ScriptureRange(
              bookCode: 'JER',
              chapter: 15,
              startVerse: 10,
              endVerse: 10,
            ),
            ScriptureRange(
              bookCode: 'JER',
              chapter: 15,
              startVerse: 16,
              endVerse: 21,
            ),
          ],
        ),
        LectionaryReadingReference(
          kind: LectionaryReadingKind.responsorialPsalm,
          title: 'Responsorial Psalm',
          displayReference:
              'Psalm 59:2–3, 4, 10–11, 17, 18',
          response:
              'God is my refuge on the day of distress.',
          ranges: <ScriptureRange>[
            ScriptureRange(
              bookCode: 'PSA',
              chapter: 59,
              startVerse: 1,
              endVerse: 2,
              displayVerseOffset: 1,
            ),
            ScriptureRange(
              bookCode: 'PSA',
              chapter: 59,
              startVerse: 3,
              endVerse: 3,
              displayVerseOffset: 1,
            ),
            ScriptureRange(
              bookCode: 'PSA',
              chapter: 59,
              startVerse: 9,
              endVerse: 10,
              displayVerseOffset: 1,
            ),
            ScriptureRange(
              bookCode: 'PSA',
              chapter: 59,
              startVerse: 16,
              endVerse: 17,
              displayVerseOffset: 1,
            ),
          ],
        ),
        LectionaryReadingReference(
          kind: LectionaryReadingKind.gospelAcclamation,
          title: 'Gospel Acclamation',
          displayReference: 'John 8:12',
          ranges: <ScriptureRange>[
            ScriptureRange(
              bookCode: 'JHN',
              chapter: 8,
              startVerse: 12,
              endVerse: 12,
            ),
          ],
        ),
        LectionaryReadingReference(
          kind: LectionaryReadingKind.gospel,
          title: 'Gospel — Choice One',
          displayReference: 'John 11:19–27',
          choiceGroup: 'gospel',
          choiceLabel: 'Choice One',
          ranges: <ScriptureRange>[
            ScriptureRange(
              bookCode: 'JHN',
              chapter: 11,
              startVerse: 19,
              endVerse: 27,
            ),
          ],
        ),
        LectionaryReadingReference(
          kind: LectionaryReadingKind.gospel,
          title: 'Gospel — Choice Two',
          displayReference: 'Luke 10:38–42',
          choiceGroup: 'gospel',
          choiceLabel: 'Choice Two',
          ranges: <ScriptureRange>[
            ScriptureRange(
              bookCode: 'LUK',
              chapter: 10,
              startVerse: 38,
              endVerse: 42,
            ),
          ],
        ),
      ],
    ),
  };

  Future<LectionaryDayReferences?> getToday() {
    return getForDate(DateTime.now());
  }

  Future<LectionaryDayReferences?> getForDate(
    DateTime date,
  ) async {
    return _days[_dateKey(date)];
  }

  static String _dateKey(DateTime date) {
    final String month =
        date.month.toString().padLeft(2, '0');
    final String day =
        date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}