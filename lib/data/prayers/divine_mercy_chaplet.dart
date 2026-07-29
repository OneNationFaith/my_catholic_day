import "../../models/guided_prayer.dart";

final GuidedPrayer divineMercyChaplet = GuidedPrayer(
  id: "divine-mercy-chaplet",
  title: "Divine Mercy Chaplet",
  description:
      "Pray the Divine Mercy Chaplet one prayer and one bead at a time.",
  steps: _buildDivineMercyChapletSteps(),
);

List<GuidedPrayerStep> _buildDivineMercyChapletSteps() {
  final steps = <GuidedPrayerStep>[
    const GuidedPrayerStep(
      id: "opening-sign-of-cross",
      title: "Sign of the Cross",
      subtitle: "Opening Prayer",
      body:
          "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
      type: GuidedPrayerStepType.introduction,
      sectionTitle: "Opening Prayers",
    ),
    const GuidedPrayerStep(
      id: "opening-optional-prayer",
      title: "Optional Opening Prayer",
      subtitle: "The Source of Life",
      body:
          "You expired, Jesus, but the source of life gushed forth for souls, "
          "and the ocean of mercy opened up for the whole world.\n\n"
          "O Fount of Life, unfathomable Divine Mercy, envelop the whole world "
          "and empty Yourself out upon us.",
      type: GuidedPrayerStepType.introduction,
      sectionTitle: "Opening Prayers",
    ),
    const GuidedPrayerStep(
      id: "opening-blood-and-water",
      title: "O Blood and Water",
      subtitle: "Repeat three times",
      body:
          "O Blood and Water, which gushed forth from the Heart of Jesus "
          "as a fountain of Mercy for us, I trust in You!",
      type: GuidedPrayerStepType.repeatedPrayer,
      sectionTitle: "Opening Prayers",
      repetitionNumber: 1,
      totalRepetitions: 3,
    ),
    const GuidedPrayerStep(
      id: "opening-blood-and-water-2",
      title: "O Blood and Water",
      subtitle: "Second time",
      body:
          "O Blood and Water, which gushed forth from the Heart of Jesus "
          "as a fountain of Mercy for us, I trust in You!",
      type: GuidedPrayerStepType.repeatedPrayer,
      sectionTitle: "Opening Prayers",
      repetitionNumber: 2,
      totalRepetitions: 3,
    ),
    const GuidedPrayerStep(
      id: "opening-blood-and-water-3",
      title: "O Blood and Water",
      subtitle: "Third time",
      body:
          "O Blood and Water, which gushed forth from the Heart of Jesus "
          "as a fountain of Mercy for us, I trust in You!",
      type: GuidedPrayerStepType.repeatedPrayer,
      sectionTitle: "Opening Prayers",
      repetitionNumber: 3,
      totalRepetitions: 3,
    ),
    const GuidedPrayerStep(
      id: "opening-our-father",
      title: "Our Father",
      body:
          "Our Father, who art in heaven, hallowed be thy name. "
          "Thy kingdom come. Thy will be done on earth as it is in heaven. "
          "Give us this day our daily bread. And forgive us our trespasses, "
          "as we forgive those who trespass against us. "
          "And lead us not into temptation, but deliver us from evil. Amen.",
      type: GuidedPrayerStepType.ourFather,
      sectionTitle: "Opening Prayers",
    ),
    const GuidedPrayerStep(
      id: "opening-hail-mary",
      title: "Hail Mary",
      body:
          "Hail Mary, full of grace, the Lord is with thee. "
          "Blessed art thou among women and blessed is the fruit "
          "of thy womb, Jesus.\n\n"
          "Holy Mary, Mother of God, pray for us sinners, "
          "now and at the hour of our death. Amen.",
      type: GuidedPrayerStepType.hailMary,
      sectionTitle: "Opening Prayers",
    ),
    const GuidedPrayerStep(
      id: "opening-apostles-creed",
      title: "The Apostles’ Creed",
      body:
          "I believe in God, the Father almighty, Creator of heaven and earth, "
          "and in Jesus Christ, his only Son, our Lord, who was conceived "
          "by the Holy Spirit, born of the Virgin Mary, suffered under "
          "Pontius Pilate, was crucified, died and was buried; "
          "he descended into hell; on the third day he rose again from the dead; "
          "he ascended into heaven, and is seated at the right hand of God "
          "the Father almighty; from there he will come to judge the living "
          "and the dead.\n\n"
          "I believe in the Holy Spirit, the holy catholic Church, "
          "the communion of saints, the forgiveness of sins, "
          "the resurrection of the body, and life everlasting. Amen.",
      type: GuidedPrayerStepType.creed,
      sectionTitle: "Opening Prayers",
    ),
  ];

  for (var decadeIndex = 0; decadeIndex < 5; decadeIndex++) {
    final decadeNumber = decadeIndex + 1;
    final decadeName = _ordinalName(decadeNumber);
    final sectionTitle = "$decadeName Decade";

    steps.add(
      GuidedPrayerStep(
        id: "decade-$decadeNumber-eternal-father",
        title: "Eternal Father",
        subtitle: "On the large bead",
        body:
            "Eternal Father, I offer You the Body and Blood, Soul and Divinity "
            "of Your dearly beloved Son, our Lord Jesus Christ, "
            "in atonement for our sins and those of the whole world.",
        type: GuidedPrayerStepType.repeatedPrayer,
        sectionTitle: sectionTitle,
        sectionNumber: decadeNumber,
        totalSections: 5,
      ),
    );

    for (var beadIndex = 0; beadIndex < 10; beadIndex++) {
      final beadNumber = beadIndex + 1;

      steps.add(
        GuidedPrayerStep(
          id: "decade-$decadeNumber-small-bead-$beadNumber",
          title: "For the Sake of His Sorrowful Passion",
          subtitle: "Small bead $beadNumber of 10",
          body:
              "For the sake of His sorrowful Passion, "
              "have mercy on us and on the whole world.",
          type: GuidedPrayerStepType.repeatedPrayer,
          sectionTitle: sectionTitle,
          sectionNumber: decadeNumber,
          totalSections: 5,
          repetitionNumber: beadNumber,
          totalRepetitions: 10,
        ),
      );
    }
  }

  for (var repetitionIndex = 0;
      repetitionIndex < 3;
      repetitionIndex++) {
    final repetitionNumber = repetitionIndex + 1;

    steps.add(
      GuidedPrayerStep(
        id: "closing-holy-god-$repetitionNumber",
        title: "Holy God",
        subtitle: "Repetition $repetitionNumber of 3",
        body:
            "Holy God, Holy Mighty One, Holy Immortal One, "
            "have mercy on us and on the whole world.",
        type: GuidedPrayerStepType.repeatedPrayer,
        sectionTitle: "Closing Prayers",
        repetitionNumber: repetitionNumber,
        totalRepetitions: 3,
      ),
    );
  }

  steps.addAll(
    const [
      GuidedPrayerStep(
        id: "closing-eternal-god",
        title: "Eternal God",
        body:
            "Eternal God, in whom mercy is endless and the treasury "
            "of compassion inexhaustible, look kindly upon us and increase "
            "Your mercy in us, that in difficult moments we might not despair "
            "nor become despondent, but with great confidence submit ourselves "
            "to Your holy will, which is Love and Mercy itself. Amen.",
        type: GuidedPrayerStepType.closingPrayer,
        sectionTitle: "Closing Prayers",
      ),
      GuidedPrayerStep(
        id: "closing-sign-of-cross",
        title: "Sign of the Cross",
        body:
            "In the name of the Father, and of the Son, "
            "and of the Holy Spirit. Amen.",
        type: GuidedPrayerStepType.closingPrayer,
        sectionTitle: "Closing Prayers",
      ),
    ],
  );

  return steps;
}

String _ordinalName(int number) {
  switch (number) {
    case 1:
      return "First";
    case 2:
      return "Second";
    case 3:
      return "Third";
    case 4:
      return "Fourth";
    case 5:
      return "Fifth";
    default:
      return number.toString();
  }
}