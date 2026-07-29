enum GuidedPrayerStepType {
  introduction,
  mystery,
  scripture,
  reflection,
  ourFather,
  hailMary,
  gloryBe,
  fatimaPrayer,
  creed,
  repeatedPrayer,
  closingPrayer,
}

class GuidedPrayerStep {
  const GuidedPrayerStep({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.subtitle,
    this.sectionTitle,
    this.sectionNumber,
    this.totalSections,
    this.repetitionNumber,
    this.totalRepetitions,
  });

  final String id;
  final String title;
  final String body;
  final GuidedPrayerStepType type;

  final String? subtitle;

  /// Examples:
  /// "The Annunciation"
  /// "First Decade"
  /// "Opening Prayers"
  final String? sectionTitle;

  /// The current mystery, decade, station, or other major section.
  final int? sectionNumber;

  /// Total number of mysteries, decades, stations, or major sections.
  final int? totalSections;

  /// Current repeated prayer or bead number.
  final int? repetitionNumber;

  /// Total number of repeated prayers or beads.
  final int? totalRepetitions;

  bool get hasSectionProgress =>
      sectionNumber != null && totalSections != null;

  bool get hasRepetitionProgress =>
      repetitionNumber != null && totalRepetitions != null;
}

class GuidedPrayer {
  const GuidedPrayer({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final List<GuidedPrayerStep> steps;
}