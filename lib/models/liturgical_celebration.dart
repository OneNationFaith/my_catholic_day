import 'catholic_day.dart';

class LiturgicalCelebration {
  const LiturgicalCelebration({
    required this.name,
    required this.month,
    required this.day,
    required this.rank,
    required this.color,
    this.saintName,
    this.isHolyDayOfObligation = false,
  });

  /// Full liturgical title.
  ///
  /// Example:
  /// "Solemnity of Saints Peter and Paul, Apostles"
  final String name;

  /// Calendar month from 1 through 12.
  final int month;

  /// Calendar day from 1 through 31.
  final int day;

  final CelebrationRank rank;
  final LiturgicalColor color;

  /// The saint’s shorter display name, when applicable.
  ///
  /// Example:
  /// "Saint Joseph"
  final String? saintName;

  final bool isHolyDayOfObligation;

  bool occursOn(DateTime date) {
    return date.month == month && date.day == day;
  }

  LiturgicalCelebration copyWith({
    String? name,
    int? month,
    int? day,
    CelebrationRank? rank,
    LiturgicalColor? color,
    String? saintName,
    bool clearSaintName = false,
    bool? isHolyDayOfObligation,
  }) {
    return LiturgicalCelebration(
      name: name ?? this.name,
      month: month ?? this.month,
      day: day ?? this.day,
      rank: rank ?? this.rank,
      color: color ?? this.color,
      saintName: clearSaintName ? null : saintName ?? this.saintName,
      isHolyDayOfObligation:
          isHolyDayOfObligation ?? this.isHolyDayOfObligation,
    );
  }

  factory LiturgicalCelebration.fromJson(
    Map<String, dynamic> json,
  ) {
    return LiturgicalCelebration(
      name: json['name'] as String,
      month: json['month'] as int,
      day: json['day'] as int,
      rank: _rankFromString(json['rank'] as String),
      color: _colorFromString(json['color'] as String),
      saintName: json['saintName'] as String?,
      isHolyDayOfObligation:
          json['isHolyDayOfObligation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'month': month,
      'day': day,
      'rank': _rankToString(rank),
      'color': _colorToString(color),
      'saintName': saintName,
      'isHolyDayOfObligation': isHolyDayOfObligation,
    };
  }

  static CelebrationRank _rankFromString(String value) {
    switch (value) {
      case 'optionalMemorial':
        return CelebrationRank.optionalMemorial;
      case 'memorial':
        return CelebrationRank.memorial;
      case 'feast':
        return CelebrationRank.feast;
      case 'solemnity':
        return CelebrationRank.solemnity;
      case 'weekday':
      default:
        return CelebrationRank.weekday;
    }
  }

  static LiturgicalColor _colorFromString(String value) {
    switch (value) {
      case 'white':
        return LiturgicalColor.white;
      case 'red':
        return LiturgicalColor.red;
      case 'violet':
        return LiturgicalColor.violet;
      case 'rose':
        return LiturgicalColor.rose;
      case 'green':
      default:
        return LiturgicalColor.green;
    }
  }

  static String _rankToString(CelebrationRank rank) {
    switch (rank) {
      case CelebrationRank.weekday:
        return 'weekday';
      case CelebrationRank.optionalMemorial:
        return 'optionalMemorial';
      case CelebrationRank.memorial:
        return 'memorial';
      case CelebrationRank.feast:
        return 'feast';
      case CelebrationRank.solemnity:
        return 'solemnity';
    }
  }

  static String _colorToString(LiturgicalColor color) {
    switch (color) {
      case LiturgicalColor.green:
        return 'green';
      case LiturgicalColor.white:
        return 'white';
      case LiturgicalColor.red:
        return 'red';
      case LiturgicalColor.violet:
        return 'violet';
      case LiturgicalColor.rose:
        return 'rose';
    }
  }
}