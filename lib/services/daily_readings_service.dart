import '../data/repositories/lectionary_reference_repository.dart';
import '../data/repositories/scripture_repository.dart';
import '../models/lectionary_reference.dart';
import '../models/reading.dart';
import '../models/scripture_passage.dart';

class DailyReadingsService {
  DailyReadingsService({
    ScriptureRepository? scriptureRepository,
    LectionaryReferenceRepository? lectionaryRepository,
  })  : _scriptureRepository =
            scriptureRepository ?? ScriptureRepository(),
        _lectionaryRepository =
            lectionaryRepository ??
                const LectionaryReferenceRepository();

  final ScriptureRepository _scriptureRepository;
  final LectionaryReferenceRepository _lectionaryRepository;

  Future<DailyReadings> getToday() {
    return getForDate(DateTime.now());
  }

  Future<DailyReadings> getForDate(DateTime date) async {
    final DateTime normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final LectionaryDayReferences? references =
        await _lectionaryRepository.getForDate(
      normalizedDate,
    );

    if (references == null) {
      return DailyReadings(
        date: normalizedDate,
        liturgicalDay: 'Readings Coming Soon',
        translationName:
            'World English Bible, Catholic Edition',
        translationAbbreviation: 'WEBC',
        translationNotice:
            'The Mass reading references for this date have not '
            'yet been added. Scripture wording may differ from '
            'the official Lectionary used at Mass in the '
            'United States.',
        readings: const <DailyReading>[],
      );
    }

    final List<DailyReading> readings = <DailyReading>[];

    for (final LectionaryReadingReference reference
        in references.readings) {
      final List<String> passageSections = <String>[];

      for (final ScriptureRange range in reference.ranges) {
        final ScripturePassage passage =
            await _scriptureRepository.getScripturePassage(
          bookCode: range.bookCode,
          chapter: range.chapter,
          startVerse: range.startVerse,
          endVerse: range.endVerse,
          displayVerseOffset: range.displayVerseOffset,
        );

        if (passage.isEmpty) {
          throw StateError(
            '${reference.displayReference} could not be loaded '
            'from the WEBC database.',
          );
        }

        passageSections.add(passage.text);
      }

      readings.add(
        DailyReading(
          kind: _convertReadingKind(reference.kind),
          title: reference.title,
          reference: reference.displayReference,
          text: passageSections.join('\n\n'),
          response: reference.response,
        ),
      );
    }

    return DailyReadings(
      date: normalizedDate,
      liturgicalDay: references.liturgicalDay,
      translationName:
          'World English Bible, Catholic Edition',
      translationAbbreviation: 'WEBC',
      translationNotice:
          'The reading references follow the Catholic Mass '
          'readings for this date. Scripture text is from the '
          'World English Bible, Catholic Edition. Wording may '
          'differ from the official Lectionary used at Mass in '
          'the United States.',
      readings: readings,
    );
  }

  ReadingKind _convertReadingKind(
    LectionaryReadingKind kind,
  ) {
    switch (kind) {
      case LectionaryReadingKind.firstReading:
        return ReadingKind.firstReading;
      case LectionaryReadingKind.responsorialPsalm:
        return ReadingKind.responsorialPsalm;
      case LectionaryReadingKind.secondReading:
        return ReadingKind.secondReading;
      case LectionaryReadingKind.gospelAcclamation:
        return ReadingKind.gospelAcclamation;
      case LectionaryReadingKind.gospel:
        return ReadingKind.gospel;
    }
  }
}