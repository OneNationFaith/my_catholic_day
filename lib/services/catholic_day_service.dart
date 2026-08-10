import '../data/fixed_liturgical_celebrations.dart';
import '../data/liturgical_calendar_repository.dart';
import '../models/catholic_day.dart';

class CatholicDayService {
  const CatholicDayService({
    this.calendarRepository = const LiturgicalCalendarRepository(),
    this.stateCode,
  });

  final LiturgicalCalendarRepository calendarRepository;
  final String? stateCode;

  static const Set<int> _bundledCalendarYears = <int>{2026};

  Future<CatholicDay> getToday() async {
    return getForDate(DateTime.now());
  }

  Future<CatholicDay> getForDate(DateTime date) async {
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);

    if (_bundledCalendarYears.contains(normalizedDate.year)) {
      final ResolvedLiturgicalCalendarDay resolved = await calendarRepository
          .getForDate(normalizedDate, stateCode: stateCode);

      return _fromResolvedDay(resolved);
    }

    return _legacyDayFor(normalizedDate);
  }

  CatholicDay _fromResolvedDay(ResolvedLiturgicalCalendarDay resolved) {
    final Map<String, dynamic> event = resolved.primaryEvent;

    return CatholicDay(
      date: resolved.date,
      season: _seasonFromEvent(event),
      color: _colorFromEvent(event),
      celebration: _displayName(event['name']?.toString()),
      rank: _rankFromEvent(event),
      rosaryMysteries: _rosaryFor(resolved.date),
      saintName: _saintNameFor(resolved),
      isHolyDayOfObligation: event['holy_day_of_obligation'] == true,
    );
  }

  LiturgicalSeason _seasonFromEvent(Map<String, dynamic> event) {
    final String season =
        event['liturgical_season']?.toString().trim().toUpperCase() ?? '';

    switch (season) {
      case 'ADVENT':
        return LiturgicalSeason.advent;
      case 'CHRISTMAS':
        return LiturgicalSeason.christmas;
      case 'ORDINARY_TIME':
        return LiturgicalSeason.ordinaryTime;
      case 'LENT':
        return LiturgicalSeason.lent;
      case 'EASTER_TRIDUUM':
        return LiturgicalSeason.triduum;
      case 'EASTER':
        return LiturgicalSeason.easter;
      default:
        throw FormatException(
          'Unsupported liturgical season "$season" '
          'for ${event['event_key']}.',
        );
    }
  }

  LiturgicalColor _colorFromEvent(Map<String, dynamic> event) {
    final Object? colorValue = event['color'];

    final List<String> colors;

    if (colorValue is List) {
      colors = colorValue
          .map((Object? value) => value?.toString().trim().toLowerCase() ?? '')
          .where((String value) => value.isNotEmpty)
          .toList();
    } else {
      final String color = colorValue?.toString().trim().toLowerCase() ?? '';

      colors = color.isEmpty ? <String>[] : <String>[color];
    }

    final String eventName = event['name']?.toString().toLowerCase() ?? '';

    final String color;

    if (colors.contains('rose')) {
      color = 'rose';
    } else if (colors.contains('red') && eventName.contains('martyr')) {
      color = 'red';
    } else {
      color = colors.isEmpty ? '' : colors.first;
    }

    switch (color) {
      case 'green':
        return LiturgicalColor.green;
      case 'white':
        return LiturgicalColor.white;
      case 'red':
        return LiturgicalColor.red;
      case 'purple':
      case 'violet':
        return LiturgicalColor.violet;
      case 'rose':
        return LiturgicalColor.rose;
      default:
        throw FormatException(
          'Unsupported liturgical color "$color" '
          'for ${event['event_key']}.',
        );
    }
  }

  CelebrationRank _rankFromEvent(Map<String, dynamic> event) {
    final int grade = _integerValue(event['grade']) ?? 0;

    if (grade <= 1) {
      return CelebrationRank.weekday;
    }

    if (grade == 2) {
      return CelebrationRank.optionalMemorial;
    }

    if (grade == 3) {
      return CelebrationRank.memorial;
    }

    if (grade == 4 || grade == 5) {
      return CelebrationRank.feast;
    }

    return CelebrationRank.solemnity;
  }

  String? _saintNameFor(ResolvedLiturgicalCalendarDay resolved) {
    final String? primaryName = _saintLikeName(resolved.primaryEvent);

    if (primaryName != null) {
      return primaryName;
    }

    for (final Map<String, dynamic> event in resolved.optionalMemorials) {
      final String? name = _saintLikeName(event);

      if (name != null) {
        return name;
      }
    }

    return null;
  }

  String? _saintLikeName(Map<String, dynamic> event) {
    final String name = _displayName(event['name']?.toString());

    final bool isSaintLike =
        name.startsWith('Saint ') ||
        name.startsWith('Saints ') ||
        name.startsWith('Our Lady ') ||
        name.startsWith('Blessed Virgin Mary');

    return isSaintLike ? name : null;
  }

  String _displayName(String? rawName) {
    final String name = rawName?.trim() ?? '';

    if (name.isEmpty) {
      return 'Liturgical Day';
    }

    return name.replaceFirst(RegExp(r'^\[\s*USA?\s*\]\s*'), '').trim();
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

  CatholicDay _legacyDayFor(DateTime normalizedDate) {
    final LiturgicalSeason season = _seasonFor(normalizedDate);

    final celebration = fixedCelebrationFor(normalizedDate);

    return CatholicDay(
      date: normalizedDate,
      season: season,
      color: celebration?.color ?? _colorFor(normalizedDate, season),
      celebration: celebration?.name ?? _celebrationFor(normalizedDate, season),
      rank: celebration?.rank ?? CelebrationRank.weekday,
      rosaryMysteries: _rosaryFor(normalizedDate),
      saintName: celebration?.saintName,
      isHolyDayOfObligation: celebration?.isHolyDayOfObligation ?? false,
    );
  }

  LiturgicalSeason _seasonFor(DateTime date) {
    final DateTime easter = _easterSunday(date.year);
    final DateTime ashWednesday = easter.subtract(const Duration(days: 46));
    final DateTime holyThursday = easter.subtract(const Duration(days: 3));
    final DateTime pentecost = easter.add(const Duration(days: 49));

    final DateTime adventStart = _firstSundayOfAdvent(date.year);

    final DateTime baptismOfTheLord = _baptismOfTheLord(date.year);

    if (_isSameDay(date, holyThursday) ||
        _isSameDay(date, holyThursday.add(const Duration(days: 1))) ||
        _isSameDay(date, holyThursday.add(const Duration(days: 2)))) {
      return LiturgicalSeason.triduum;
    }

    if (!date.isBefore(easter) && !date.isAfter(pentecost)) {
      return LiturgicalSeason.easter;
    }

    if (!date.isBefore(ashWednesday) && date.isBefore(holyThursday)) {
      return LiturgicalSeason.lent;
    }

    if (!date.isBefore(adventStart) &&
        date.isBefore(DateTime(date.year, 12, 25))) {
      return LiturgicalSeason.advent;
    }

    if (!date.isBefore(DateTime(date.year, 12, 25))) {
      return LiturgicalSeason.christmas;
    }

    if (!date.isAfter(baptismOfTheLord)) {
      return LiturgicalSeason.christmas;
    }

    return LiturgicalSeason.ordinaryTime;
  }

  LiturgicalColor _colorFor(DateTime date, LiturgicalSeason season) {
    final DateTime easter = _easterSunday(date.year);
    final DateTime palmSunday = easter.subtract(const Duration(days: 7));
    final DateTime goodFriday = easter.subtract(const Duration(days: 2));
    final DateTime pentecost = easter.add(const Duration(days: 49));

    if (_isSameDay(date, palmSunday) ||
        _isSameDay(date, goodFriday) ||
        _isSameDay(date, pentecost)) {
      return LiturgicalColor.red;
    }

    if (_isGaudeteSunday(date) || _isLaetareSunday(date)) {
      return LiturgicalColor.rose;
    }

    switch (season) {
      case LiturgicalSeason.advent:
      case LiturgicalSeason.lent:
        return LiturgicalColor.violet;

      case LiturgicalSeason.triduum:
        return _isSameDay(date, goodFriday)
            ? LiturgicalColor.red
            : LiturgicalColor.white;

      case LiturgicalSeason.christmas:
      case LiturgicalSeason.easter:
        return LiturgicalColor.white;

      case LiturgicalSeason.ordinaryTime:
        return LiturgicalColor.green;
    }
  }

  RosaryMysteries _rosaryFor(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
      case DateTime.saturday:
        return RosaryMysteries.joyful;

      case DateTime.tuesday:
      case DateTime.friday:
        return RosaryMysteries.sorrowful;

      case DateTime.wednesday:
      case DateTime.sunday:
        return RosaryMysteries.glorious;

      case DateTime.thursday:
        return RosaryMysteries.luminous;

      default:
        return RosaryMysteries.joyful;
    }
  }

  String _celebrationFor(DateTime date, LiturgicalSeason season) {
    final DateTime easter = _easterSunday(date.year);
    final DateTime ashWednesday = easter.subtract(const Duration(days: 46));
    final DateTime palmSunday = easter.subtract(const Duration(days: 7));
    final DateTime holyThursday = easter.subtract(const Duration(days: 3));
    final DateTime goodFriday = easter.subtract(const Duration(days: 2));
    final DateTime holySaturday = easter.subtract(const Duration(days: 1));
    final DateTime pentecost = easter.add(const Duration(days: 49));

    if (_isSameDay(date, DateTime(date.year, 12, 25))) {
      return 'The Nativity of the Lord';
    }

    if (_isSameDay(date, ashWednesday)) {
      return 'Ash Wednesday';
    }

    if (_isSameDay(date, palmSunday)) {
      return 'Palm Sunday of the Passion of the Lord';
    }

    if (_isSameDay(date, holyThursday)) {
      return 'Holy Thursday';
    }

    if (_isSameDay(date, goodFriday)) {
      return 'Good Friday of the Passion of the Lord';
    }

    if (_isSameDay(date, holySaturday)) {
      return 'Holy Saturday';
    }

    if (_isSameDay(date, easter)) {
      return 'Easter Sunday of the Resurrection of the Lord';
    }

    if (_isSameDay(date, pentecost)) {
      return 'Pentecost Sunday';
    }

    final String weekday = _weekdayName(date.weekday);

    switch (season) {
      case LiturgicalSeason.advent:
        return '$weekday of Advent';

      case LiturgicalSeason.christmas:
        return '$weekday of Christmas Time';

      case LiturgicalSeason.lent:
        return '$weekday of Lent';

      case LiturgicalSeason.triduum:
        return 'Sacred Paschal Triduum';

      case LiturgicalSeason.easter:
        return '$weekday of Easter Time';

      case LiturgicalSeason.ordinaryTime:
        return '$weekday in Ordinary Time';
    }
  }

  DateTime _firstSundayOfAdvent(int year) {
    final DateTime november27 = DateTime(year, 11, 27);

    final int daysUntilSunday = (DateTime.sunday - november27.weekday + 7) % 7;

    return november27.add(Duration(days: daysUntilSunday));
  }

  DateTime _baptismOfTheLord(int year) {
    final DateTime epiphanySunday = _sundayBetweenJanuary2And8(year);

    return epiphanySunday.add(const Duration(days: 1));
  }

  DateTime _sundayBetweenJanuary2And8(int year) {
    final DateTime january2 = DateTime(year, 1, 2);

    final int daysUntilSunday = (DateTime.sunday - january2.weekday + 7) % 7;

    return january2.add(Duration(days: daysUntilSunday));
  }

  bool _isGaudeteSunday(DateTime date) {
    final DateTime adventStart = _firstSundayOfAdvent(date.year);

    final DateTime thirdSunday = adventStart.add(const Duration(days: 14));

    return _isSameDay(date, thirdSunday);
  }

  bool _isLaetareSunday(DateTime date) {
    final DateTime easter = _easterSunday(date.year);

    final DateTime fourthSundayOfLent = easter.subtract(
      const Duration(days: 21),
    );

    return _isSameDay(date, fourthSundayOfLent);
  }

  DateTime _easterSunday(int year) {
    final int a = year % 19;
    final int b = year ~/ 100;
    final int c = year % 100;
    final int d = b ~/ 4;
    final int e = b % 4;
    final int f = (b + 8) ~/ 25;
    final int g = (b - f + 1) ~/ 3;
    final int h = (19 * a + b - d - g + 15) % 30;
    final int i = c ~/ 4;
    final int k = c % 4;
    final int l = (32 + 2 * e + 2 * i - h - k) % 7;
    final int m = (a + 11 * h + 22 * l) ~/ 451;
    final int month = (h + l - 7 * m + 114) ~/ 31;
    final int day = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(year, month, day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }
}
