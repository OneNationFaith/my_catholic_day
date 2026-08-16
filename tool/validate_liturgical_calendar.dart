import 'dart:convert';
import 'dart:io';

const String _sourceDirectory = 'tool/source/liturgical_calendar';

void main(List<String> arguments) {
  try {
    if (arguments.length != 1) {
      stderr.writeln('Usage: dart run tool/validate_liturgical_calendar.dart YEAR');
      exitCode = 64;
      return;
    }

    final int? year = int.tryParse(arguments.first);
    if (year == null || year < 1970) {
      throw FormatException('Enter a valid calendar year.');
    }

    final File draftFile = File(
      '$_sourceDirectory/${year}_calendar_draft.json',
    );

    if (!draftFile.existsSync()) {
      throw FileSystemException(
        'Calendar draft was not found. Build it first.',
        draftFile.path,
      );
    }

    final Object? decoded = jsonDecode(draftFile.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Calendar draft is not a JSON object.');
    }

    final Map<String, dynamic> root = decoded;
    _expect(root['schemaVersion'] == 2, 'schemaVersion must be 2.');
    _expect(_intValue(root['year']) == year, 'Calendar year does not match.');

    final Object? daysValue = root['days'];
    _expect(daysValue is List<dynamic>, 'Calendar has no valid days list.');

    final List<Map<String, dynamic>> days = (daysValue as List<dynamic>)
        .map((dynamic value) {
          _expect(value is Map<String, dynamic>, 'A day entry is not an object.');
          return Map<String, dynamic>.from(value as Map<String, dynamic>);
        })
        .toList();

    final int expectedDays = DateTime.utc(year + 1, 1, 1)
        .difference(DateTime.utc(year, 1, 1))
        .inDays;

    _expect(
      days.length == expectedDays,
      'Expected $expectedDays civil dates, found ${days.length}.',
    );

    final Map<String, Map<String, dynamic>> daysByDate =
        <String, Map<String, dynamic>>{};

    for (final Map<String, dynamic> day in days) {
      final String date = day['date']?.toString() ?? '';
      _expect(date.isNotEmpty, 'A day entry has no date.');
      _expect(!daysByDate.containsKey(date), 'Duplicate day entry: $date');
      daysByDate[date] = day;

      final String? primaryKey = _nullableString(day['primaryEventKey']);
      if (primaryKey != null) {
        _expect(
          _effectiveEvent(day, primaryKey) != null,
          '$date primaryEventKey does not resolve: $primaryKey',
        );
      }

      for (final String key in _stringList(day['optionalMemorialKeys'])) {
        _expect(
          _effectiveEvent(day, key) != null,
          '$date optionalMemorialKey does not resolve: $key',
        );
      }

      for (final String key in _stringList(day['vigilEventKeys'])) {
        _expect(
          _effectiveEvent(day, key) != null,
          '$date vigilEventKey does not resolve: $key',
        );
      }
    }

    DateTime cursor = DateTime.utc(year, 1, 1);
    for (int index = 0; index < expectedDays; index++) {
      final String key = _dateKey(cursor);
      _expect(daysByDate.containsKey(key), 'Missing civil date: $key');
      cursor = cursor.add(const Duration(days: 1));
    }

    stdout.writeln('PASS: $expectedDays unique civil dates and event references.');

    _verifyUsHolyDayObligations(year, daysByDate);
    stdout.writeln('PASS: U.S. Saturday/Monday holy-day obligation rule.');

    _verifyAscensionVariant(root, year);
    stdout.writeln('PASS: regional Ascension Thursday variant.');

    _verifyCuratedUsccbChecks(year, daysByDate);
    stdout.writeln('PASS: curated USCCB checks for $year.');

    stdout.writeln();
    stdout.writeln('Liturgical calendar validation passed for $year.');
  } catch (error) {
    stderr.writeln();
    stderr.writeln('VALIDATION FAILED: $error');
    exitCode = 1;
  }
}

void _verifyUsHolyDayObligations(
  int year,
  Map<String, Map<String, dynamic>> daysByDate,
) {
  const List<({String key, int month, int day})> solemnities =
      <({String key, int month, int day})>[
        (key: 'MaryMotherOfGod', month: 1, day: 1),
        (key: 'Assumption', month: 8, day: 15),
        (key: 'AllSaints', month: 11, day: 1),
      ];

  for (final ({String key, int month, int day}) solemnity in solemnities) {
    final DateTime date = DateTime.utc(year, solemnity.month, solemnity.day);
    final String dateKey = _dateKey(date);
    final Map<String, dynamic>? day = daysByDate[dateKey];
    _expect(day != null, 'Missing $dateKey.');

    final Map<String, dynamic>? event = _effectiveEvent(day!, solemnity.key);
    if (event == null) {
      continue;
    }

    final bool shouldBeAbrogated =
        date.weekday == DateTime.saturday || date.weekday == DateTime.monday;

    final bool? hdo = _boolValue(event['holy_day_of_obligation']);
    _expect(
      hdo == !shouldBeAbrogated,
      '$dateKey ${solemnity.key} effective HDO should be '
      '${!shouldBeAbrogated}, found $hdo.',
    );

    final DateTime vigilDate = date.subtract(const Duration(days: 1));
    if (vigilDate.year != year) {
      continue;
    }

    final Map<String, dynamic>? vigilDay = daysByDate[_dateKey(vigilDate)];
    if (vigilDay == null) {
      continue;
    }

    final Map<String, dynamic>? vigilEvent = _effectiveEvent(
      vigilDay,
      '${solemnity.key}_vigil',
    );

    if (vigilEvent != null) {
      final bool? vigilHdo = _boolValue(vigilEvent['holy_day_of_obligation']);
      _expect(
        vigilHdo == !shouldBeAbrogated,
        '${_dateKey(vigilDate)} ${solemnity.key}_vigil effective HDO should be '
        '${!shouldBeAbrogated}, found $vigilHdo.',
      );
    }
  }
}

void _verifyAscensionVariant(Map<String, dynamic> root, int year) {
  final Object? regionalValue = root['regionalVariants'];
  _expect(
    regionalValue is Map<String, dynamic>,
    'regionalVariants is missing.',
  );

  final Object? ascensionValue =
      (regionalValue as Map<String, dynamic>)['ascensionThursday'];
  _expect(
    ascensionValue is Map<String, dynamic>,
    'ascensionThursday regional variant is missing.',
  );

  final Map<String, dynamic> ascension =
      ascensionValue as Map<String, dynamic>;

  _expect(
    ascension['rule']?.toString() == 'ASCENSION_THURSDAY',
    'Ascension regional rule is invalid.',
  );

  const List<String> expectedStates = <String>[
    'CT',
    'MA',
    'ME',
    'NE',
    'NH',
    'NY',
    'PA',
    'RI',
    'VT',
  ];

  final List<String> states = _stringList(ascension['stateCodes']);
  _expect(
    states.join(',') == expectedStates.join(','),
    'Ascension Thursday state list changed: ${states.join(',')}',
  );

  final Object? overridesValue = ascension['dayOverrides'];
  _expect(
    overridesValue is List<dynamic>,
    'Ascension dayOverrides is missing.',
  );

  Map<String, dynamic>? ascensionOverride;
  Map<String, dynamic>? easter7Override;

  for (final dynamic value in overridesValue as List<dynamic>) {
    if (value is! Map<String, dynamic>) {
      continue;
    }

    final String? primaryKey = _nullableString(value['primaryEventKey']);
    if (primaryKey == 'Ascension') {
      ascensionOverride = value;
    } else if (primaryKey == 'Easter7') {
      easter7Override = value;
    }
  }

  _expect(ascensionOverride != null, 'Regional Ascension override is missing.');
  _expect(easter7Override != null, 'Regional Easter7 override is missing.');

  final DateTime ascensionDate =
      DateTime.parse(ascensionOverride!['date'].toString());
  final DateTime easter7Date =
      DateTime.parse(easter7Override!['date'].toString());

  _expect(
    ascensionDate.year == year && ascensionDate.weekday == DateTime.thursday,
    'Regional Ascension is not on a Thursday in $year.',
  );
  _expect(
    easter7Date.year == year && easter7Date.weekday == DateTime.sunday,
    'Regional Easter7 is not on a Sunday in $year.',
  );

  final Object? primaryEventValue = ascensionOverride['primaryEvent'];
  _expect(
    primaryEventValue is Map<String, dynamic>,
    'Regional Ascension primary event is missing.',
  );

  final bool? hdo = _boolValue(
    (primaryEventValue as Map<String, dynamic>)['holy_day_of_obligation'],
  );
  _expect(hdo == true, 'Regional Ascension must be marked HDO.');
}

void _verifyCuratedUsccbChecks(
  int year,
  Map<String, Map<String, dynamic>> daysByDate,
) {
  switch (year) {
    case 2026:
      final Map<String, dynamic> june13 = _day(daysByDate, '2026-06-13');
      _expect(
        june13['primaryEventKey'] == 'ONF_USCCB_2026_06_13_WEEKDAY',
        '2026-06-13 weekday normalization is missing.',
      );
      _expectKeysContain(
        june13,
        'optionalMemorialKeys',
        <String>[
          'ImmaculateHeart',
          'StAnthonyPadua',
          'ONF_USCCB_2026_06_13_BVM',
        ],
        '2026-06-13 optional memorials',
      );

      final Map<String, dynamic> assumption =
          _day(daysByDate, '2026-08-15');
      _expect(
        _boolValue(
              _effectiveEvent(assumption, 'Assumption')
                  ?['holy_day_of_obligation'],
            ) ==
            false,
        '2026 Assumption obligation normalization is missing.',
      );

    case 2027:
      final Map<String, dynamic> april5 = _day(daysByDate, '2027-04-05');
      _expect(
        april5['primaryEventKey'] == 'Annunciation',
        '2027 Annunciation transfer to April 5 is missing.',
      );

      final Map<String, dynamic> may6 = _day(daysByDate, '2027-05-06');
      _expect(
        may6['primaryEventKey'] == 'EasterWeekday6Thursday',
        '2027 national May 6 should remain an Easter weekday.',
      );

      final Map<String, dynamic> may9 = _day(daysByDate, '2027-05-09');
      _expect(
        may9['primaryEventKey'] == 'Ascension',
        '2027 national Ascension should be May 9.',
      );

      final Map<String, dynamic> june5 = _day(daysByDate, '2027-06-05');
      _expect(
        june5['primaryEventKey'] == 'ONF_USCCB_2027_06_05_WEEKDAY',
        '2027-06-05 weekday normalization is missing.',
      );
      _expectKeysContain(
        june5,
        'optionalMemorialKeys',
        <String>[
          'ImmaculateHeart',
          'StBoniface',
          'ONF_USCCB_2027_06_05_BVM',
        ],
        '2027-06-05 optional memorials',
      );

      final Map<String, dynamic> october9 = _day(daysByDate, '2027-10-09');
      _expectKeysContain(
        october9,
        'optionalMemorialKeys',
        <String>['ONF_USCCB_2027_10_09_ST_JOHN_HENRY_NEWMAN'],
        '2027-10-09 optional memorials',
      );

      final Map<String, dynamic> november1 = _day(daysByDate, '2027-11-01');
      _expect(
        _boolValue(
              _effectiveEvent(november1, 'AllSaints')
                  ?['holy_day_of_obligation'],
            ) ==
            false,
        '2027 All Saints Monday obligation should be abrogated.',
      );

      final Map<String, dynamic> december12 = _day(daysByDate, '2027-12-12');
      _expect(
        december12['primaryEventKey'] == 'Advent3',
        '2027-12-12 should be the Third Sunday of Advent.',
      );

    default:
      throw StateError(
        'No curated USCCB verification checks are defined for $year. '
        'Add the new year before promoting its calendar.',
      );
  }
}

Map<String, dynamic> _day(
  Map<String, Map<String, dynamic>> daysByDate,
  String date,
) {
  final Map<String, dynamic>? day = daysByDate[date];
  _expect(day != null, 'Missing curated verification date: $date');
  return day!;
}

void _expectKeysContain(
  Map<String, dynamic> day,
  String field,
  List<String> requiredKeys,
  String label,
) {
  final List<String> keys = _stringList(day[field]);
  for (final String requiredKey in requiredKeys) {
    _expect(keys.contains(requiredKey), '$label is missing $requiredKey.');
  }
}

Map<String, dynamic>? _effectiveEvent(
  Map<String, dynamic> day,
  String eventKey,
) {
  for (final Map<String, dynamic> event in _eventList(day['normalizedEvents'])) {
    if (event['event_key']?.toString() == eventKey) {
      return event;
    }
  }

  for (final Map<String, dynamic> event in _eventList(day['events'])) {
    if (event['event_key']?.toString() == eventKey) {
      return event;
    }
  }

  return null;
}

List<Map<String, dynamic>> _eventList(Object? value) {
  if (value is! List<dynamic>) {
    return <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(Map<String, dynamic>.from)
      .toList();
}

List<String> _stringList(Object? value) {
  if (value is! List<dynamic>) {
    return <String>[];
  }

  return value
      .map((dynamic item) => item?.toString() ?? '')
      .where((String item) => item.isNotEmpty)
      .toList();
}

String? _nullableString(Object? value) {
  final String text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

bool? _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value?.toString().toLowerCase() == 'true') {
    return true;
  }
  if (value?.toString().toLowerCase() == 'false') {
    return false;
  }
  return null;
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}
