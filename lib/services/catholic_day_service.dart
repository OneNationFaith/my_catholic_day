import '../models/catholic_day.dart';
import '../data/fixed_liturgical_celebrations.dart';
class CatholicDayService {
  const CatholicDayService();

  Future<CatholicDay> getToday() async {
    return getForDate(DateTime.now());
  }

 Future<CatholicDay> getForDate(DateTime date) async {
  final normalizedDate = DateTime(date.year, date.month, date.day);

  final season = _seasonFor(normalizedDate);

  final celebration = fixedCelebrationFor(normalizedDate);

  return CatholicDay(
    date: normalizedDate,
    season: season,
    color: celebration?.color ??
        _colorFor(normalizedDate, season),
    celebration: celebration?.name ??
        _celebrationFor(normalizedDate, season),
    rank: celebration?.rank ??
        CelebrationRank.weekday,
    rosaryMysteries: _rosaryFor(normalizedDate),
    saintName: celebration?.saintName,
    isHolyDayOfObligation:
        celebration?.isHolyDayOfObligation ?? false,
  );
}

  LiturgicalSeason _seasonFor(DateTime date) {
    final easter = _easterSunday(date.year);
    final ashWednesday = easter.subtract(const Duration(days: 46));
    final holyThursday = easter.subtract(const Duration(days: 3));
    final pentecost = easter.add(const Duration(days: 49));

    final adventStart = _firstSundayOfAdvent(date.year);
    final baptismOfTheLord = _baptismOfTheLord(date.year);

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

  LiturgicalColor _colorFor(
    DateTime date,
    LiturgicalSeason season,
  ) {
    final easter = _easterSunday(date.year);
    final palmSunday = easter.subtract(const Duration(days: 7));
    final goodFriday = easter.subtract(const Duration(days: 2));
    final pentecost = easter.add(const Duration(days: 49));

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

  String _celebrationFor(
    DateTime date,
    LiturgicalSeason season,
  ) {
    final easter = _easterSunday(date.year);
    final ashWednesday = easter.subtract(const Duration(days: 46));
    final palmSunday = easter.subtract(const Duration(days: 7));
    final holyThursday = easter.subtract(const Duration(days: 3));
    final goodFriday = easter.subtract(const Duration(days: 2));
    final holySaturday = easter.subtract(const Duration(days: 1));
    final pentecost = easter.add(const Duration(days: 49));

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

    final weekday = _weekdayName(date.weekday);

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
    final november27 = DateTime(year, 11, 27);
    final daysUntilSunday =
        (DateTime.sunday - november27.weekday + 7) % 7;

    return november27.add(Duration(days: daysUntilSunday));
  }

  DateTime _baptismOfTheLord(int year) {
    final epiphanySunday = _sundayBetweenJanuary2And8(year);
    return epiphanySunday.add(const Duration(days: 1));
  }

  DateTime _sundayBetweenJanuary2And8(int year) {
    final january2 = DateTime(year, 1, 2);
    final daysUntilSunday =
        (DateTime.sunday - january2.weekday + 7) % 7;

    return january2.add(Duration(days: daysUntilSunday));
  }

  bool _isGaudeteSunday(DateTime date) {
    final adventStart = _firstSundayOfAdvent(date.year);
    final thirdSunday =
        adventStart.add(const Duration(days: 14));

    return _isSameDay(date, thirdSunday);
  }

  bool _isLaetareSunday(DateTime date) {
    final easter = _easterSunday(date.year);
    final fourthSundayOfLent =
        easter.subtract(const Duration(days: 21));

    return _isSameDay(date, fourthSundayOfLent);
  }

  DateTime _easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;

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