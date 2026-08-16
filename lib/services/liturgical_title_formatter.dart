class LiturgicalTitleFormatter {
  LiturgicalTitleFormatter._();

  static const Map<String, String> _weekdays = <String, String>{
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
  };

  static String formatEvent(Map<String, dynamic> event) {
    return format(
      event['name']?.toString(),
      liturgicalSeason: event['liturgical_season']?.toString(),
    );
  }

  static String format(String? rawName, {String? liturgicalSeason}) {
    String name = rawName?.trim() ?? '';

    if (name.isEmpty) {
      return 'Liturgical Day';
    }

    name = name
        .replaceFirst(RegExp(r'^\[\s*USA?\s*\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final RegExpMatch? weekdayMatch = RegExp(
      r'^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)\s*-\s*.*Weekday$',
      caseSensitive: false,
    ).firstMatch(name);

    if (weekdayMatch == null) {
      return name;
    }

    final String? weekday = _weekdays[weekdayMatch.group(1)?.toLowerCase()];

    if (weekday == null) {
      return name;
    }

    switch (liturgicalSeason?.trim().toUpperCase()) {
      case 'ADVENT':
        return '$weekday of Advent';
      case 'CHRISTMAS':
        return '$weekday of Christmas Time';
      case 'ORDINARY_TIME':
        return '$weekday in Ordinary Time';
      case 'LENT':
        return '$weekday of Lent';
      case 'EASTER':
        return '$weekday of Easter Time';
      default:
        return name;
    }
  }
}
