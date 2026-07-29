import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/lectionary_reference.dart';

class LectionaryReferenceRepository {
  const LectionaryReferenceRepository();

  static final Map<
    int,
    Map<String, LectionaryDayReferences>
  >
  _yearCache = {};

  Future<LectionaryDayReferences?> getToday() {
    return getForDate(DateTime.now());
  }

  Future<LectionaryDayReferences?> getForDate(
    DateTime date,
  ) async {
    final Map<String, LectionaryDayReferences> yearData =
        await _loadYear(date.year);

    return yearData[_dateKey(date)];
  }

  Future<
    Map<String, LectionaryDayReferences>
  >
  _loadYear(int year) async {
    final Map<String, LectionaryDayReferences>? cachedYear =
        _yearCache[year];

    if (cachedYear != null) {
      return cachedYear;
    }

    final String assetPath =
        'assets/data/lectionary/$year.json';

    late final String jsonText;

    try {
      jsonText = await rootBundle.loadString(assetPath);
    } on FlutterError {
      final Map<String, LectionaryDayReferences> emptyYear =
          <String, LectionaryDayReferences>{};

      _yearCache[year] = emptyYear;
      return emptyYear;
    }

    final Object? decodedJson = jsonDecode(jsonText);

    if (decodedJson is! Map<String, dynamic>) {
      throw FormatException(
        'The lectionary file for $year is not valid JSON data.',
      );
    }

    final int schemaVersion =
        (decodedJson['schemaVersion'] as num?)?.toInt() ?? 0;

    if (schemaVersion != 1) {
      throw FormatException(
        'Unsupported lectionary schema version: '
        '$schemaVersion',
      );
    }

    final int fileYear =
        (decodedJson['year'] as num?)?.toInt() ?? 0;

    if (fileYear != year) {
      throw FormatException(
        'The lectionary file says it is for $fileYear, '
        'but the app requested $year.',
      );
    }

    final Object? daysValue = decodedJson['days'];

    if (daysValue is! List<dynamic>) {
      throw FormatException(
        'The lectionary file for $year has no valid days list.',
      );
    }

    final Map<String, LectionaryDayReferences> yearData =
        <String, LectionaryDayReferences>{};

    for (final dynamic dayValue in daysValue) {
      if (dayValue is! Map<String, dynamic>) {
        throw FormatException(
          'A lectionary day in $year is not valid.',
        );
      }

      final LectionaryDayReferences day =
          LectionaryDayReferences.fromJson(dayValue);

      yearData[_dateKey(day.date)] = day;
    }

    _yearCache[year] = yearData;

    return yearData;
  }

  static String _dateKey(DateTime date) {
    final String month =
        date.month.toString().padLeft(2, '0');

    final String day =
        date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  static void clearCache() {
    _yearCache.clear();
  }
}