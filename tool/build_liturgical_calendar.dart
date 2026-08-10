import 'dart:convert';
import 'dart:io';

const String _sourceDirectory = 'tool/source/liturgical_calendar';

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.length != 1) {
      _printUsage();
      exitCode = 64;
      return;
    }

    final int? year = int.tryParse(arguments.first);

    if (year == null || year < 1970) {
      throw FormatException('Enter a valid calendar year, for example 2026.');
    }

    final File inputFile = File('$_sourceDirectory/${year}_litcal_raw.json');

    final File ascensionThursdayInputFile = File(
      '$_sourceDirectory/${year}_litcal_ascension_thursday_raw.json',
    );

    if (!inputFile.existsSync()) {
      throw FileSystemException(
        'Raw LitCal file was not found.',
        inputFile.path,
      );
    }

    if (!ascensionThursdayInputFile.existsSync()) {
      throw FileSystemException(
        'Ascension Thursday LitCal file was not found.',
        ascensionThursdayInputFile.path,
      );
    }

    stdout.writeln('One Nation Faith Liturgical Calendar Builder');
    stdout.writeln('============================================');
    stdout.writeln();
    stdout.writeln('Year: $year');
    stdout.writeln('Input: ${inputFile.path}');
    stdout.writeln(
      'Ascension Thursday input: ${ascensionThursdayInputFile.path}',
    );
    stdout.writeln();

    final Object? decoded = jsonDecode(inputFile.readAsStringSync());

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Raw LitCal file is not a JSON object.');
    }

    final Map<String, dynamic> root = decoded;

    final Object? settingsValue = root['settings'];

    if (settingsValue is! Map<String, dynamic>) {
      throw const FormatException(
        'Raw LitCal file has no valid settings object.',
      );
    }

    final int? sourceYear = _integerValue(settingsValue['year']);

    if (sourceYear != year) {
      throw FormatException(
        'Raw LitCal file is for year $sourceYear, '
        'not $year.',
      );
    }

    final String yearType =
        settingsValue['year_type']?.toString().trim().toUpperCase() ?? '';

    if (yearType != 'CIVIL') {
      throw FormatException(
        'Raw LitCal file uses year_type '
        '"$yearType" instead of CIVIL.',
      );
    }

    final Object? litcalValue = root['litcal'];

    if (litcalValue is! List<dynamic>) {
      throw const FormatException(
        'Raw LitCal file has no valid litcal event list.',
      );
    }

    final Map<String, List<Map<String, dynamic>>> eventsByDate =
        <String, List<Map<String, dynamic>>>{};

    final List<Map<String, dynamic>> boundaryEvents = <Map<String, dynamic>>[];

    for (final dynamic eventValue in litcalValue) {
      if (eventValue is! Map<String, dynamic>) {
        throw const FormatException(
          'LitCal contains an event that is not '
          'a JSON object.',
        );
      }

      final Map<String, dynamic> event = Map<String, dynamic>.from(eventValue);

      final int? eventYear = _integerValue(event['year']);
      final int? month = _integerValue(event['month']);
      final int? day = _integerValue(event['day']);

      if (eventYear == null || month == null || day == null) {
        throw FormatException(
          'LitCal event ${event['event_key']} '
          'has no valid civil date.',
        );
      }

      if (eventYear != year) {
        boundaryEvents.add(event);
        continue;
      }

      final String dateKey = _dateKey(year: eventYear, month: month, day: day);

      eventsByDate.putIfAbsent(dateKey, () => <Map<String, dynamic>>[]);

      eventsByDate[dateKey]!.add(event);
    }

    final int expectedDays = DateTime.utc(
      year + 1,
      1,
      1,
    ).difference(DateTime.utc(year, 1, 1)).inDays;

    if (eventsByDate.length != expectedDays) {
      throw FormatException(
        'Expected $expectedDays calendar dates, '
        'but found ${eventsByDate.length}.',
      );
    }

    final List<String> sortedDates = eventsByDate.keys.toList()..sort();

    final List<Map<String, dynamic>> days = <Map<String, dynamic>>[];

    for (final String date in sortedDates) {
      final List<Map<String, dynamic>> events = eventsByDate[date]!;

      final List<Map<String, dynamic>> vigilEvents = events.where((
        Map<String, dynamic> event,
      ) {
        return event['is_vigil_mass'] == true;
      }).toList();

      final List<Map<String, dynamic>> nonVigilEvents = events.where((
        Map<String, dynamic> event,
      ) {
        return event['is_vigil_mass'] != true;
      }).toList();

      final Map<String, dynamic>? usccbWeekdayOverride = date == '2026-06-13'
          ? <String, dynamic>{
              'event_key': 'ONF_USCCB_2026_06_13_WEEKDAY',
              'name': 'Saturday of the Tenth Week in Ordinary Time',
              'color': <String>['green'],
              'color_lcl': <String>['green'],
              'grade': 0,
              'grade_lcl': 'weekday',
              'grade_abbr': 'w',
              'grade_display': null,
              'common': <String>[],
              'common_lcl': '',
              'type': 'generated',
              'year': 2026,
              'month': 6,
              'day': 13,
              'day_of_the_week_iso8601': 6,
              'day_of_the_week_short': 'Sat',
              'day_of_the_week_long': 'Saturday',
              'liturgical_year': 'YEAR II',
              'psalter_week': 2,
              'liturgical_season': 'ORDINARY_TIME',
              'liturgical_season_lcl': 'Ordinary Time',
              'source': 'USCCB 2026 calendar normalization',
            }
          : null;

      final Map<String, dynamic>? underlyingWeekday =
          _firstEventWhere(
            nonVigilEvents,
            (Map<String, dynamic> event) => _integerValue(event['grade']) == 0,
          ) ??
          usccbWeekdayOverride;

      final List<Map<String, dynamic>> holyDayObligationOverrides =
          <Map<String, dynamic>>[];

      if (year == 2026) {
        for (final Map<String, dynamic> event in events) {
          final String eventKey = event['event_key']?.toString() ?? '';

          final bool isAbrogatedAssumption =
              (date == '2026-08-14' && eventKey == 'Assumption_vigil') ||
              (date == '2026-08-15' && eventKey == 'Assumption');

          if (isAbrogatedAssumption) {
            final Map<String, dynamic> normalizedEvent =
                Map<String, dynamic>.from(event)
                  ..['holy_day_of_obligation'] = false
                  ..['source'] = 'USCCB Canon 1246 §2 obligation normalization';

            holyDayObligationOverrides.add(normalizedEvent);
          }
        }
      }

      final List<Map<String, dynamic>> generatedEvents =
          <Map<String, dynamic>>[];

      if (date == '2026-06-13') {
        generatedEvents.add(<String, dynamic>{
          'event_key': 'ONF_USCCB_2026_06_13_BVM',
          'name': 'Saturday Memorial of the Blessed Virgin Mary',
          'color': <String>['white'],
          'color_lcl': <String>['white'],
          'grade': 2,
          'grade_lcl': 'optional memorial',
          'grade_abbr': 'm',
          'grade_display': null,
          'common': <String>[],
          'common_lcl': '',
          'type': 'generated',
          'year': 2026,
          'month': 6,
          'day': 13,
          'day_of_the_week_iso8601': 6,
          'day_of_the_week_short': 'Sat',
          'day_of_the_week_long': 'Saturday',
          'liturgical_year': 'YEAR II',
          'psalter_week': 2,
          'liturgical_season': 'ORDINARY_TIME',
          'liturgical_season_lcl': 'Ordinary Time',
          'source': 'USCCB 2026 calendar normalization',
        });
      }

      final List<Map<String, dynamic>> optionalMemorials =
          <Map<String, dynamic>>[
            ...nonVigilEvents.where((Map<String, dynamic> event) {
              return _integerValue(event['grade']) == 2;
            }),
            ...generatedEvents,
          ];

      final List<Map<String, dynamic>> usObservances = nonVigilEvents.where((
        Map<String, dynamic> event,
      ) {
        return _isUsSpecialObservance(event['event_key']?.toString());
      }).toList();

      final List<Map<String, dynamic>> primaryCandidates = nonVigilEvents.where(
        (Map<String, dynamic> event) {
          final int grade = _integerValue(event['grade']) ?? -1;

          return grade >= 3 &&
              !_isUsSpecialObservance(event['event_key']?.toString());
        },
      ).toList();

      primaryCandidates.sort((
        Map<String, dynamic> first,
        Map<String, dynamic> second,
      ) {
        final int firstGrade = _integerValue(first['grade']) ?? -1;

        final int secondGrade = _integerValue(second['grade']) ?? -1;

        return secondGrade.compareTo(firstGrade);
      });

      final Map<String, dynamic>? primary = primaryCandidates.isNotEmpty
          ? primaryCandidates.first
          : underlyingWeekday;

      days.add(<String, dynamic>{
        'date': date,
        'primaryEventKey': primary?['event_key'],
        'underlyingWeekdayKey': underlyingWeekday?['event_key'],
        'normalizedEvents': <Map<String, dynamic>>[
          ?usccbWeekdayOverride,
          ...holyDayObligationOverrides,
          ...generatedEvents,
        ],
        'optionalMemorialKeys': optionalMemorials
            .map((Map<String, dynamic> event) => event['event_key'])
            .toList(),
        'usObservanceKeys': usObservances
            .map((Map<String, dynamic> event) => event['event_key'])
            .toList(),
        'vigilEventKeys': vigilEvents
            .map((Map<String, dynamic> event) => event['event_key'])
            .toList(),
        'events': events,
      });
    }

    final Map<String, dynamic> ascensionThursdayVariant =
        _buildAscensionThursdayVariant(
          inputFile: ascensionThursdayInputFile,
          year: year,
        );

    final Map<String, dynamic> output = <String, dynamic>{
      'schemaVersion': 2,
      'year': year,
      'source': <String, dynamic>{
        'name': 'Liturgical Calendar API',
        'calendar': 'US',
        'yearType': 'CIVIL',
      },
      'litcalSettings': settingsValue,
      'regionalVariants': <String, dynamic>{
        'ascensionThursday': ascensionThursdayVariant,
      },
      'days': days,
      'boundaryEvents': boundaryEvents,
    };

    final File outputFile = File(
      '$_sourceDirectory/${year}_calendar_draft.json',
    );

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');

    outputFile.writeAsStringSync('${encoder.convert(output)}\n');

    final int groupedEventCount = eventsByDate.values.fold<int>(0, (
      int total,
      List<Map<String, dynamic>> events,
    ) {
      return total + events.length;
    });

    stdout.writeln('Validated ${days.length} civil dates.');

    stdout.writeln(
      'Grouped $groupedEventCount events '
      'inside $year.',
    );

    stdout.writeln(
      'Preserved ${boundaryEvents.length} '
      'boundary event(s).',
    );

    stdout.writeln();
    stdout.writeln('Saved calendar draft:');
    stdout.writeln(outputFile.path);
  } catch (error) {
    stderr.writeln();
    stderr.writeln('ERROR: $error');
    exitCode = 1;
  }
}

Map<String, dynamic> _buildAscensionThursdayVariant({
  required File inputFile,
  required int year,
}) {
  final Object? decoded = jsonDecode(inputFile.readAsStringSync());

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(
      'Ascension Thursday LitCal file is not a JSON object.',
    );
  }

  final Object? settingsValue = decoded['settings'];

  if (settingsValue is! Map<String, dynamic>) {
    throw const FormatException(
      'Ascension Thursday LitCal file has no valid settings object.',
    );
  }

  final int? sourceYear = _integerValue(settingsValue['year']);

  if (sourceYear != year) {
    throw FormatException(
      'Ascension Thursday LitCal file is for year $sourceYear, '
      'not $year.',
    );
  }

  final String yearType =
      settingsValue['year_type']?.toString().trim().toUpperCase() ?? '';

  if (yearType != 'CIVIL') {
    throw FormatException(
      'Ascension Thursday LitCal file uses year_type '
      '"$yearType" instead of CIVIL.',
    );
  }

  final String ascension =
      settingsValue['ascension']?.toString().trim().toUpperCase() ?? '';

  if (ascension != 'THURSDAY') {
    throw FormatException(
      'Ascension Thursday LitCal file uses ascension '
      '"$ascension" instead of THURSDAY.',
    );
  }

  final Object? litcalValue = decoded['litcal'];

  if (litcalValue is! List<dynamic>) {
    throw const FormatException(
      'Ascension Thursday LitCal file has no valid litcal event list.',
    );
  }

  final List<Map<String, dynamic>> relevantEvents = <Map<String, dynamic>>[];

  for (final dynamic eventValue in litcalValue) {
    if (eventValue is! Map<String, dynamic>) {
      throw const FormatException(
        'Ascension Thursday LitCal contains an event '
        'that is not a JSON object.',
      );
    }

    final Map<String, dynamic> event = Map<String, dynamic>.from(eventValue);

    final int? eventYear = _integerValue(event['year']);

    if (eventYear != year) {
      continue;
    }

    final String eventKey = event['event_key']?.toString() ?? '';

    final String vigilFor = event['is_vigil_for']?.toString() ?? '';

    final bool isVigil = event['is_vigil_mass'] == true;

    final bool isRegionalPrimary =
        !isVigil && (eventKey == 'Ascension' || eventKey == 'Easter7');

    final bool isRegionalVigil =
        isVigil &&
        (eventKey == 'Ascension_vigil' ||
            eventKey == 'Easter7_vigil' ||
            vigilFor == 'Ascension' ||
            vigilFor == 'Easter7');

    if (isRegionalPrimary || isRegionalVigil) {
      relevantEvents.add(event);
    }
  }

  final Map<String, dynamic>? ascensionEvent = _firstEventWhere(
    relevantEvents,
    (Map<String, dynamic> event) =>
        event['is_vigil_mass'] != true && event['event_key'] == 'Ascension',
  );

  final Map<String, dynamic>? seventhSundayEvent = _firstEventWhere(
    relevantEvents,
    (Map<String, dynamic> event) =>
        event['is_vigil_mass'] != true && event['event_key'] == 'Easter7',
  );

  if (ascensionEvent == null || seventhSundayEvent == null) {
    throw const FormatException(
      'Ascension Thursday LitCal data must contain both '
      'Ascension and the Seventh Sunday of Easter.',
    );
  }

  final Map<String, Map<String, dynamic>> overridesByDate =
      <String, Map<String, dynamic>>{};

  for (final Map<String, dynamic> event in relevantEvents) {
    final int? eventYear = _integerValue(event['year']);
    final int? month = _integerValue(event['month']);
    final int? day = _integerValue(event['day']);

    if (eventYear == null || month == null || day == null) {
      throw FormatException(
        'Ascension regional event ${event['event_key']} '
        'has no valid civil date.',
      );
    }

    final String date = _dateKey(year: eventYear, month: month, day: day);

    final Map<String, dynamic> override = overridesByDate.putIfAbsent(
      date,
      () => <String, dynamic>{'date': date},
    );

    if (event['is_vigil_mass'] == true) {
      final List<Map<String, dynamic>> vigilEvents =
          (override['vigilEvents'] as List<Map<String, dynamic>>?) ??
          <Map<String, dynamic>>[];

      vigilEvents.add(event);
      override['vigilEvents'] = vigilEvents;
    } else {
      override['primaryEvent'] = event;
    }
  }

  final List<String> sortedDates = overridesByDate.keys.toList()..sort();

  final List<Map<String, dynamic>> dayOverrides = <Map<String, dynamic>>[];

  for (final String date in sortedDates) {
    final Map<String, dynamic> override = overridesByDate[date]!;

    final Object? primaryValue = override['primaryEvent'];

    final Object? vigilValue = override['vigilEvents'];

    final Map<String, dynamic> normalizedOverride = <String, dynamic>{
      'date': date,
    };

    if (primaryValue is Map<String, dynamic>) {
      normalizedOverride['primaryEventKey'] = primaryValue['event_key'];
      normalizedOverride['primaryEvent'] = primaryValue;
    }

    if (vigilValue is List<Map<String, dynamic>>) {
      normalizedOverride['vigilEventKeys'] = vigilValue
          .map((Map<String, dynamic> event) => event['event_key'])
          .toList();
      normalizedOverride['vigilEvents'] = vigilValue;
    }

    dayOverrides.add(normalizedOverride);
  }

  return <String, dynamic>{
    'rule': 'ASCENSION_THURSDAY',
    'stateCodes': <String>[
      'CT',
      'MA',
      'ME',
      'NE',
      'NH',
      'NY',
      'PA',
      'RI',
      'VT',
    ],
    'ecclesiasticalProvinces': <String>[
      'Boston',
      'Hartford',
      'New York',
      'Omaha',
      'Philadelphia',
    ],
    'source': <String, dynamic>{
      'name': 'Liturgical Calendar API',
      'calendar': 'GENERAL',
      'yearType': 'CIVIL',
      'ascension': 'THURSDAY',
    },
    'litcalSettings': settingsValue,
    'dayOverrides': dayOverrides,
  };
}

int? _integerValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}

Map<String, dynamic>? _firstEventWhere(
  List<Map<String, dynamic>> events,
  bool Function(Map<String, dynamic> event) test,
) {
  for (final Map<String, dynamic> event in events) {
    if (test(event)) {
      return event;
    }
  }

  return null;
}

bool _isUsSpecialObservance(String? eventKey) {
  return eventKey == 'PrayerUnborn' ||
      eventKey == 'IndependenceDay' ||
      eventKey == 'ThanksgivingDay';
}

String _dateKey({required int year, required int month, required int day}) {
  return '$year-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

void _printUsage() {
  stdout.writeln('Usage:');

  stdout.writeln(
    '  dart run '
    'tool/build_liturgical_calendar.dart 2026',
  );
}
