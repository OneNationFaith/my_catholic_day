enum LiturgicalSeason {
  advent,
  christmas,
  ordinaryTime,
  lent,
  triduum,
  easter,
}

enum LiturgicalColor {
  green,
  white,
  red,
  violet,
  rose,
}

enum CelebrationRank {
  weekday,
  optionalMemorial,
  memorial,
  feast,
  solemnity,
}

enum RosaryMysteries {
  joyful,
  sorrowful,
  glorious,
  luminous,
}

class CatholicDay {
  const CatholicDay({
    required this.date,
    required this.season,
    required this.color,
    required this.celebration,
    required this.rank,
    required this.rosaryMysteries,
    this.saintName,
    this.isHolyDayOfObligation = false,
  });

  final DateTime date;
  final LiturgicalSeason season;
  final LiturgicalColor color;

  /// Examples:
  /// "Monday of the Seventeenth Week in Ordinary Time"
  /// "Memorial of Saint Martha"
  final String celebration;

  final CelebrationRank rank;
  final RosaryMysteries rosaryMysteries;

  final String? saintName;
  final bool isHolyDayOfObligation;

  String get seasonName {
    switch (season) {
      case LiturgicalSeason.advent:
        return 'Advent';
      case LiturgicalSeason.christmas:
        return 'Christmas';
      case LiturgicalSeason.ordinaryTime:
        return 'Ordinary Time';
      case LiturgicalSeason.lent:
        return 'Lent';
      case LiturgicalSeason.triduum:
        return 'Sacred Paschal Triduum';
      case LiturgicalSeason.easter:
        return 'Easter';
    }
  }

  String get colorName {
    switch (color) {
      case LiturgicalColor.green:
        return 'Green';
      case LiturgicalColor.white:
        return 'White';
      case LiturgicalColor.red:
        return 'Red';
      case LiturgicalColor.violet:
        return 'Violet';
      case LiturgicalColor.rose:
        return 'Rose';
    }
  }

  String get rankName {
    switch (rank) {
      case CelebrationRank.weekday:
        return 'Weekday';
      case CelebrationRank.optionalMemorial:
        return 'Optional Memorial';
      case CelebrationRank.memorial:
        return 'Memorial';
      case CelebrationRank.feast:
        return 'Feast';
      case CelebrationRank.solemnity:
        return 'Solemnity';
    }
  }

  String get rosaryMysteriesName {
    switch (rosaryMysteries) {
      case RosaryMysteries.joyful:
        return 'Joyful Mysteries';
      case RosaryMysteries.sorrowful:
        return 'Sorrowful Mysteries';
      case RosaryMysteries.glorious:
        return 'Glorious Mysteries';
      case RosaryMysteries.luminous:
        return 'Luminous Mysteries';
    }
  }
}