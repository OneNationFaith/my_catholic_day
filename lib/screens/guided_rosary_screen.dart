import "package:flutter/material.dart";

import "../models/guided_prayer.dart";
import "guided_prayer_screen.dart";

class RosaryMystery {
  const RosaryMystery({
    required this.title,
    required this.scriptureReference,
    required this.reflection,
    required this.fruit,
  });

  final String title;
  final String scriptureReference;
  final String reflection;
  final String fruit;
}

class GuidedRosaryScreen extends StatelessWidget {
  const GuidedRosaryScreen({
    super.key,
    required this.title,
    required this.mysteries,
  });

  final String title;
  final List<RosaryMystery> mysteries;

  @override
  Widget build(BuildContext context) {
    final rosary = GuidedPrayer(
      id: _createPrayerId(title),
      title: title,
      description:
          "Pray the Holy Rosary one prayer and one bead at a time.",
      steps: _buildRosarySteps(mysteries),
    );

    return GuidedPrayerScreen(
      prayer: rosary,
    );
  }
}

String _createPrayerId(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), "-")
      .replaceAll(RegExp(r"^-|-$"), "");
}

List<GuidedPrayerStep> _buildRosarySteps(
  List<RosaryMystery> mysteries,
) {
  final steps = <GuidedPrayerStep>[
    const GuidedPrayerStep(
      id: "opening-sign-of-cross",
      title: "Sign of the Cross",
      body:
          "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
      type: GuidedPrayerStepType.introduction,
      sectionTitle: "Opening Prayers",
    ),
    const GuidedPrayerStep(
      id: "opening-apostles-creed",
      title: "The Apostles’ Creed",
      body:
          "I believe in God, the Father almighty, Creator of heaven and earth, and in Jesus Christ, his only Son, our Lord, who was conceived by the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, died and was buried; he descended into hell; on the third day he rose again from the dead; he ascended into heaven, and is seated at the right hand of God the Father almighty; from there he will come to judge the living and the dead.\n\nI believe in the Holy Spirit, the holy catholic Church, the communion of saints, the forgiveness of sins, the resurrection of the body, and life everlasting. Amen.",
      type: GuidedPrayerStepType.creed,
      sectionTitle: "Opening Prayers",
    ),
    const GuidedPrayerStep(
      id: "opening-our-father",
      title: "Our Father",
      body:
          "Our Father, who art in heaven, hallowed be thy name. Thy kingdom come. Thy will be done on earth as it is in heaven. Give us this day our daily bread. And forgive us our trespasses, as we forgive those who trespass against us. And lead us not into temptation, but deliver us from evil. Amen.",
      type: GuidedPrayerStepType.ourFather,
      sectionTitle: "Opening Prayers",
    ),
    ...List.generate(
      3,
      (index) {
        final number = index + 1;

        return GuidedPrayerStep(
          id: "opening-hail-mary-$number",
          title: "Hail Mary",
          subtitle: "For an increase in faith, hope, and charity",
          body:
              "Hail Mary, full of grace, the Lord is with thee. Blessed art thou among women and blessed is the fruit of thy womb, Jesus.\n\nHoly Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.",
          type: GuidedPrayerStepType.hailMary,
          sectionTitle: "Opening Prayers",
          repetitionNumber: number,
          totalRepetitions: 3,
        );
      },
    ),
    const GuidedPrayerStep(
      id: "opening-glory-be",
      title: "Glory Be",
      body:
          "Glory be to the Father, and to the Son, and to the Holy Spirit. As it was in the beginning, is now, and ever shall be, world without end. Amen.",
      type: GuidedPrayerStepType.gloryBe,
      sectionTitle: "Opening Prayers",
    ),
  ];

  for (
    var mysteryIndex = 0;
    mysteryIndex < mysteries.length;
    mysteryIndex++
  ) {
    final mystery = mysteries[mysteryIndex];
    final mysteryNumber = mysteryIndex + 1;
    final sectionTitle =
        "Mystery $mysteryNumber: ${mystery.title}";

    steps.add(
      GuidedPrayerStep(
        id: "mystery-$mysteryNumber-announcement",
        title: mystery.title,
        subtitle: "Fruit of the Mystery: ${mystery.fruit}",
        body:
            "Announce the ${_ordinalName(mysteryNumber)} Mystery and take a moment to place yourself in the presence of God.",
        type: GuidedPrayerStepType.mystery,
        sectionTitle: sectionTitle,
        sectionNumber: mysteryNumber,
        totalSections: mysteries.length,
      ),
    );

    steps.add(
      GuidedPrayerStep(
        id: "mystery-$mysteryNumber-scripture",
        title: "Scripture",
        subtitle: mystery.title,
        body: mystery.scriptureReference,
        type: GuidedPrayerStepType.scripture,
        sectionTitle: sectionTitle,
        sectionNumber: mysteryNumber,
        totalSections: mysteries.length,
      ),
    );

    steps.add(
      GuidedPrayerStep(
        id: "mystery-$mysteryNumber-reflection",
        title: "Meditation",
        subtitle: "Fruit: ${mystery.fruit}",
        body: mystery.reflection,
        type: GuidedPrayerStepType.reflection,
        sectionTitle: sectionTitle,
        sectionNumber: mysteryNumber,
        totalSections: mysteries.length,
      ),
    );

    steps.add(
      GuidedPrayerStep(
        id: "mystery-$mysteryNumber-our-father",
        title: "Our Father",
        body:
            "Our Father, who art in heaven, hallowed be thy name. Thy kingdom come. Thy will be done on earth as it is in heaven. Give us this day our daily bread. And forgive us our trespasses, as we forgive those who trespass against us. And lead us not into temptation, but deliver us from evil. Amen.",
        type: GuidedPrayerStepType.ourFather,
        sectionTitle: sectionTitle,
        sectionNumber: mysteryNumber,
        totalSections: mysteries.length,
      ),
    );

    for (var hailMaryIndex = 0;
        hailMaryIndex < 10;
        hailMaryIndex++) {
      final hailMaryNumber = hailMaryIndex + 1;

      steps.add(
        GuidedPrayerStep(
          id:
              "mystery-$mysteryNumber-hail-mary-$hailMaryNumber",
          title: "Hail Mary",
          subtitle:
              "Continue meditating on ${mystery.title}",
          body:
              "Hail Mary, full of grace, the Lord is with thee. Blessed art thou among women and blessed is the fruit of thy womb, Jesus.\n\nHoly Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.",
          type: GuidedPrayerStepType.hailMary,
          sectionTitle: sectionTitle,
          sectionNumber: mysteryNumber,
          totalSections: mysteries.length,
          repetitionNumber: hailMaryNumber,
          totalRepetitions: 10,
        ),
      );
    }

    steps.add(
      GuidedPrayerStep(
        id: "mystery-$mysteryNumber-glory-be",
        title: "Glory Be",
        body:
            "Glory be to the Father, and to the Son, and to the Holy Spirit. As it was in the beginning, is now, and ever shall be, world without end. Amen.",
        type: GuidedPrayerStepType.gloryBe,
        sectionTitle: sectionTitle,
        sectionNumber: mysteryNumber,
        totalSections: mysteries.length,
      ),
    );

    steps.add(
      GuidedPrayerStep(
        id: "mystery-$mysteryNumber-fatima-prayer",
        title: "Fatima Prayer",
        body:
            "O my Jesus, forgive us our sins, save us from the fires of hell, lead all souls to Heaven, especially those in most need of Thy mercy. Amen.",
        type: GuidedPrayerStepType.fatimaPrayer,
        sectionTitle: sectionTitle,
        sectionNumber: mysteryNumber,
        totalSections: mysteries.length,
      ),
    );
  }

  steps.addAll(
    const [
      GuidedPrayerStep(
        id: "closing-hail-holy-queen",
        title: "Hail, Holy Queen",
        body:
            "Hail, Holy Queen, Mother of mercy, our life, our sweetness and our hope. To thee do we cry, poor banished children of Eve. To thee do we send up our sighs, mourning and weeping in this valley of tears.\n\nTurn then, most gracious advocate, thine eyes of mercy toward us, and after this our exile show unto us the blessed fruit of thy womb, Jesus.\n\nO clement, O loving, O sweet Virgin Mary.\n\nPray for us, O holy Mother of God, that we may be made worthy of the promises of Christ.",
        type: GuidedPrayerStepType.closingPrayer,
        sectionTitle: "Closing Prayers",
      ),
      GuidedPrayerStep(
        id: "closing-rosary-prayer",
        title: "Closing Prayer",
        body:
            "O God, whose only-begotten Son, by his life, death and resurrection, has purchased for us the rewards of eternal life, grant, we beseech thee, that meditating upon these mysteries of the most holy Rosary of the Blessed Virgin Mary, we may imitate what they contain and obtain what they promise, through the same Christ our Lord. Amen.",
        type: GuidedPrayerStepType.closingPrayer,
        sectionTitle: "Closing Prayers",
      ),
      GuidedPrayerStep(
        id: "closing-sign-of-cross",
        title: "Sign of the Cross",
        body:
            "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
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