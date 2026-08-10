import 'dart:convert';

import 'package:flutter/services.dart';

class LiturgicalCalendarRepository {
  const LiturgicalCalendarRepository({
    this.assetDirectory = 'assets/data/liturgical_calendar',
  });

  final String assetDirectory;

  static final Map<String, Future<Map<String, dynamic>>> _calendarCache =
      <String, Future<Map<String, dynamic>>>{};

  Future<ResolvedLiturgicalCalendarDay> getForDate(
    DateTime date, {
    String? stateCode,
  }) async {
    final DateTime normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final String dateKey = _dateKey(normalizedDate);
    final Map<String, dynamic> calendar =
        await _loadCalendar(normalizedDate.year);

    final Map<String, dynamic> day = _findDay(
      calendar,
      dateKey,
    );

    final Map<String, dynamic>? ascensionVariant =
        _ascensionThursdayVariant(
      calendar: calendar,
      stateCode: stateCode,
    );

    final Map<String, dynamic>? dayOverride =
        _findDayOverride(
      variant: ascensionVariant,
      dateKey: dateKey,
    );

    final String? primaryEventKey =
        dayOverride?['primaryEventKey']?.toString() ??
        day['primaryEventKey']?.toString();

    final Map<String, dynamic>? primaryEvent =
        _mapValue(dayOverride?['primaryEvent']) ??
        _findEventByKey(
          day,
          primaryEventKey,
        );

    if (primaryEvent == null) {
      throw StateError(
        'No primary liturgical event could be resolved for $dateKey.',
      );
    }

    final String? underlyingWeekdayKey =
        day['underlyingWeekdayKey']?.toString();

    final Map<String, dynamic>? underlyingWeekday =
        _findEventByKey(
      day,
      underlyingWeekdayKey,
    );

    final List<Map<String, dynamic>> optionalMemorials =
        _resolveEventKeys(
      day,
      _stringList(day['optionalMemorialKeys']),
    );

    final List<Map<String, dynamic>> usObservances =
        _resolveEventKeys(
      day,
      _stringList(day['usObservanceKeys']),
    );

    final List<Map<String, dynamic>> vigilEvents;
    final Object? overrideVigilEvents =
        dayOverride?['vigilEvents'];

    if (overrideVigilEvents is List) {
      vigilEvents = _mapList(overrideVigilEvents);
    } else {
      vigilEvents = _resolveEventKeys(
        day,
        _stringList(day['vigilEventKeys']),
      );
    }

    return ResolvedLiturgicalCalendarDay(
      date: normalizedDate,
      primaryEvent: primaryEvent,
      underlyingWeekday: underlyingWeekday,
      optionalMemorials: optionalMemorials,
      usObservances: usObservances,
      vigilEvents: vigilEvents,
      usedAscensionThursdayVariant:
          ascensionVariant != null && dayOverride != null,
    );
  }

  Future<Map<String, dynamic>> _loadCalendar(
    int year,
  ) {
    final String assetPath = '$assetDirectory/$year.json';

    return _calendarCache.putIfAbsent(
      assetPath,
      () async {
        final String jsonText =
            await rootBundle.loadString(assetPath);

        final Object? decoded = jsonDecode(jsonText);

        if (decoded is! Map<String, dynamic>) {
          throw FormatException(
            '$assetPath is not a JSON object.',
          );
        }

        final int? schemaVersion =
            _integerValue(decoded['schemaVersion']);

        if (schemaVersion != 2) {
          throw FormatException(
            '$assetPath uses unsupported schemaVersion '
            '$schemaVersion.',
          );
        }

        final int? calendarYear =
            _integerValue(decoded['year']);

        if (calendarYear != year) {
          throw FormatException(
            '$assetPath contains year $calendarYear '
            'instead of $year.',
          );
        }

        final Object? days = decoded['days'];

        if (days is! List) {
          throw FormatException(
            '$assetPath has no valid days list.',
          );
        }

        return decoded;
      },
    );
  }

  Map<String, dynamic> _findDay(
    Map<String, dynamic> calendar,
    String dateKey,
  ) {
    final Object? daysValue = calendar['days'];

    if (daysValue is! List) {
      throw const FormatException(
        'Calendar has no valid days list.',
      );
    }

    for (final Object? dayValue in daysValue) {
      final Map<String, dynamic>? day =
          _mapValue(dayValue);

      if (day?['date']?.toString() == dateKey) {
        return day!;
      }
    }

    throw StateError(
      'Calendar contains no entry for $dateKey.',
    );
  }

  Map<String, dynamic>? _ascensionThursdayVariant({
    required Map<String, dynamic> calendar,
    required String? stateCode,
  }) {
    final String normalizedState =
        stateCode?.trim().toUpperCase() ?? '';

    if (normalizedState.isEmpty) {
      return null;
    }

    final Map<String, dynamic>? regionalVariants =
        _mapValue(calendar['regionalVariants']);

    final Map<String, dynamic>? variant =
        _mapValue(
      regionalVariants?['ascensionThursday'],
    );

    if (variant == null) {
      return null;
    }

    final Set<String> stateCodes =
        _stringList(variant['stateCodes'])
            .map((String value) => value.toUpperCase())
            .toSet();

    if (!stateCodes.contains(normalizedState)) {
      return null;
    }

    return variant;
  }

  Map<String, dynamic>? _findDayOverride({
    required Map<String, dynamic>? variant,
    required String dateKey,
  }) {
    if (variant == null) {
      return null;
    }

    final Object? overridesValue =
        variant['dayOverrides'];

    if (overridesValue is! List) {
      return null;
    }

    for (final Object? overrideValue in overridesValue) {
      final Map<String, dynamic>? dayOverride =
          _mapValue(overrideValue);

      if (dayOverride?['date']?.toString() == dateKey) {
        return dayOverride;
      }
    }

    return null;
  }

  Map<String, dynamic>? _findEventByKey(
    Map<String, dynamic> day,
    String? eventKey,
  ) {
    if (eventKey == null || eventKey.isEmpty) {
      return null;
    }

    for (final String collectionName in <String>[
      'normalizedEvents',
      'events',
    ]) {
      final Object? eventsValue = day[collectionName];

      if (eventsValue is! List) {
        continue;
      }

      for (final Object? eventValue in eventsValue) {
        final Map<String, dynamic>? event =
            _mapValue(eventValue);

        if (event?['event_key']?.toString() ==
            eventKey) {
          return event;
        }
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _resolveEventKeys(
    Map<String, dynamic> day,
    List<String> eventKeys,
  ) {
    final List<Map<String, dynamic>> result =
        <Map<String, dynamic>>[];

    for (final String eventKey in eventKeys) {
      final Map<String, dynamic>? event =
          _findEventByKey(
        day,
        eventKey,
      );

      if (event != null) {
        result.add(event);
      }
    }

    return result;
  }

  List<Map<String, dynamic>> _mapList(
    List<dynamic> values,
  ) {
    final List<Map<String, dynamic>> result =
        <Map<String, dynamic>>[];

    for (final Object? value in values) {
      final Map<String, dynamic>? map =
          _mapValue(value);

      if (map != null) {
        result.add(map);
      }
    }

    return result;
  }

  List<String> _stringList(Object? value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((Object? item) => item?.toString() ?? '')
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _mapValue(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
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

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class ResolvedLiturgicalCalendarDay {
  const ResolvedLiturgicalCalendarDay({
    required this.date,
    required this.primaryEvent,
    required this.underlyingWeekday,
    required this.optionalMemorials,
    required this.usObservances,
    required this.vigilEvents,
    required this.usedAscensionThursdayVariant,
  });

  final DateTime date;
  final Map<String, dynamic> primaryEvent;
  final Map<String, dynamic>? underlyingWeekday;
  final List<Map<String, dynamic>> optionalMemorials;
  final List<Map<String, dynamic>> usObservances;
  final List<Map<String, dynamic>> vigilEvents;
  final bool usedAscensionThursdayVariant;
}
