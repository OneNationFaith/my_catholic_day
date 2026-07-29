import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'guided_rosary_screen.dart';

class RosaryScreen extends StatelessWidget {
  const RosaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestedMystery = _mysteryForToday();

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Holy Rosary'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          children: [
            _RosaryHeader(
              suggestedMystery: suggestedMystery,
            ),
            const SizedBox(height: 24),
            Text(
              'Choose the Mysteries',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Meditate on the life, death, and resurrection of Jesus with Mary.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 22),
            _MysteryCard(
              title: 'Joyful Mysteries',
              days: 'Monday and Saturday',
              description:
                  'The Annunciation, Visitation, Nativity, Presentation, and Finding of Jesus in the Temple.',
              icon: Icons.child_care_outlined,
              isSuggested: suggestedMystery == 'Joyful Mysteries',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuidedRosaryScreen(
                      title: 'Joyful Mysteries',
                      mysteries: joyfulMysteries,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _MysteryCard(
              title: 'Luminous Mysteries',
              days: 'Thursday',
              description:
                  'The Baptism of Jesus, Wedding at Cana, Proclamation of the Kingdom, Transfiguration, and Institution of the Eucharist.',
              icon: Icons.light_mode_outlined,
              isSuggested: suggestedMystery == 'Luminous Mysteries',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuidedRosaryScreen(
                      title: 'Luminous Mysteries',
                      mysteries: luminousMysteries,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _MysteryCard(
              title: 'Sorrowful Mysteries',
              days: 'Tuesday and Friday',
              description:
                  'The Agony in the Garden, Scourging, Crowning with Thorns, Carrying of the Cross, and Crucifixion.',
              icon: Icons.favorite_border,
              isSuggested: suggestedMystery == 'Sorrowful Mysteries',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuidedRosaryScreen(
                      title: 'Sorrowful Mysteries',
                      mysteries: sorrowfulMysteries,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _MysteryCard(
              title: 'Glorious Mysteries',
              days: 'Wednesday and Sunday',
              description:
                  'The Resurrection, Ascension, Descent of the Holy Spirit, Assumption, and Coronation of Mary.',
              icon: Icons.auto_awesome_outlined,
              isSuggested: suggestedMystery == 'Glorious Mysteries',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuidedRosaryScreen(
                      title: 'Glorious Mysteries',
                      mysteries: gloriousMysteries,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const _HowToPrayCard(),
          ],
        ),
      ),
    );
  }

  String _mysteryForToday() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
      case DateTime.saturday:
        return 'Joyful Mysteries';
      case DateTime.tuesday:
      case DateTime.friday:
        return 'Sorrowful Mysteries';
      case DateTime.thursday:
        return 'Luminous Mysteries';
      case DateTime.wednesday:
      case DateTime.sunday:
      default:
        return 'Glorious Mysteries';
    }
  }
}

const List<RosaryMystery> joyfulMysteries = [
  RosaryMystery(
    title: 'The Annunciation',
    scriptureReference: 'Luke 1:26–38',
    reflection:
        'The Angel Gabriel announces that Mary will become the Mother of Jesus. Mary responds with trust and gives herself completely to God’s will.',
    fruit: 'Humility',
  ),
  RosaryMystery(
    title: 'The Visitation',
    scriptureReference: 'Luke 1:39–56',
    reflection:
        'Mary travels to help Elizabeth. Filled with the Holy Spirit, Elizabeth recognizes the presence of Christ, and Mary praises God.',
    fruit: 'Love of Neighbor',
  ),
  RosaryMystery(
    title: 'The Nativity',
    scriptureReference: 'Luke 2:1–20',
    reflection:
        'Jesus is born in Bethlehem and laid in a manger. The Son of God enters the world in poverty, humility, and peace.',
    fruit: 'Poverty of Spirit',
  ),
  RosaryMystery(
    title: 'The Presentation',
    scriptureReference: 'Luke 2:22–38',
    reflection:
        'Mary and Joseph present Jesus in the Temple. Simeon recognizes Him as the light of the nations and the salvation of God’s people.',
    fruit: 'Purity and Obedience',
  ),
  RosaryMystery(
    title: 'The Finding of Jesus in the Temple',
    scriptureReference: 'Luke 2:41–52',
    reflection:
        'After three days of searching, Mary and Joseph find Jesus in the Temple. Jesus reveals His devotion to His Father’s work.',
    fruit: 'Joy in Finding Jesus',
  ),
];

const List<RosaryMystery> luminousMysteries = [
  RosaryMystery(
    title: 'The Baptism of Jesus',
    scriptureReference: 'Matthew 3:13–17',
    reflection:
        'Jesus is baptized in the Jordan. The Father declares His love, and the Holy Spirit descends upon Him.',
    fruit: 'Openness to the Holy Spirit',
  ),
  RosaryMystery(
    title: 'The Wedding at Cana',
    scriptureReference: 'John 2:1–11',
    reflection:
        'At Mary’s request, Jesus changes water into wine. Mary directs the servants, and all disciples, to do whatever Jesus tells them.',
    fruit: 'Trust in Mary’s Intercession',
  ),
  RosaryMystery(
    title: 'The Proclamation of the Kingdom',
    scriptureReference: 'Mark 1:14–15',
    reflection:
        'Jesus proclaims the Kingdom of God and calls everyone to repentance, faith, mercy, and a transformed life.',
    fruit: 'Conversion of Heart',
  ),
  RosaryMystery(
    title: 'The Transfiguration',
    scriptureReference: 'Matthew 17:1–8',
    reflection:
        'Jesus reveals His divine glory to Peter, James, and John. The Father commands the disciples to listen to His beloved Son.',
    fruit: 'Desire for Holiness',
  ),
  RosaryMystery(
    title: 'The Institution of the Eucharist',
    scriptureReference: 'Luke 22:14–20',
    reflection:
        'At the Last Supper, Jesus gives His Body and Blood to His disciples and commands them to continue this memorial.',
    fruit: 'Love of the Eucharist',
  ),
];

const List<RosaryMystery> sorrowfulMysteries = [
  RosaryMystery(
    title: 'The Agony in the Garden',
    scriptureReference: 'Matthew 26:36–46',
    reflection:
        'Jesus prays in deep sorrow before His arrest. Though He feels anguish, He completely surrenders Himself to the Father’s will.',
    fruit: 'Sorrow for Sin',
  ),
  RosaryMystery(
    title: 'The Scourging at the Pillar',
    scriptureReference: 'John 19:1',
    reflection:
        'Jesus is cruelly scourged. He willingly bears physical suffering for the salvation of humanity.',
    fruit: 'Purity and Self-Control',
  ),
  RosaryMystery(
    title: 'The Crowning with Thorns',
    scriptureReference: 'Matthew 27:27–31',
    reflection:
        'The soldiers mock Jesus and crown Him with thorns. The true King accepts humiliation without hatred.',
    fruit: 'Moral Courage',
  ),
  RosaryMystery(
    title: 'The Carrying of the Cross',
    scriptureReference: 'Luke 23:26–32',
    reflection:
        'Jesus carries the Cross toward Calvary. Simon of Cyrene is called to help Him bear its weight.',
    fruit: 'Patience in Suffering',
  ),
  RosaryMystery(
    title: 'The Crucifixion',
    scriptureReference: 'John 19:17–30',
    reflection:
        'Jesus is crucified and gives His life for the world. From the Cross, He offers forgiveness, mercy, and salvation.',
    fruit: 'Perseverance and Love',
  ),
];

const List<RosaryMystery> gloriousMysteries = [
  RosaryMystery(
    title: 'The Resurrection',
    scriptureReference: 'Matthew 28:1–10',
    reflection:
        'Jesus rises from the dead, conquering sin and death. The empty tomb becomes the source of Christian hope.',
    fruit: 'Faith',
  ),
  RosaryMystery(
    title: 'The Ascension',
    scriptureReference: 'Acts 1:6–11',
    reflection:
        'Jesus ascends into heaven and entrusts His disciples with the mission of carrying the Gospel to the world.',
    fruit: 'Hope',
  ),
  RosaryMystery(
    title: 'The Descent of the Holy Spirit',
    scriptureReference: 'Acts 2:1–13',
    reflection:
        'The Holy Spirit descends upon Mary and the apostles at Pentecost, giving them courage and power to proclaim Christ.',
    fruit: 'Wisdom and Courage',
  ),
  RosaryMystery(
    title: 'The Assumption of Mary',
    scriptureReference: 'Revelation 12:1',
    reflection:
        'Mary is taken body and soul into heavenly glory. Her Assumption points toward the resurrection promised to all the faithful.',
    fruit: 'Grace of a Holy Death',
  ),
  RosaryMystery(
    title: 'The Coronation of Mary',
    scriptureReference: 'Revelation 12:1; Psalm 45:10–16',
    reflection:
        'Mary is honored as Queen of Heaven and Earth. She continues to pray for the Church and lead her children toward Jesus.',
    fruit: 'Trust in Mary’s Intercession',
  ),
];

class _RosaryHeader extends StatelessWidget {
  const _RosaryHeader({
    required this.suggestedMystery,
  });

  final String suggestedMystery;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 28,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.church_outlined,
              color: AppColors.gold,
              size: 46,
            ),
            const SizedBox(height: 14),
            Text(
              'Pray the Rosary',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Walk with Mary as she leads you more deeply into the life of Christ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Suggested today: $suggestedMystery',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MysteryCard extends StatelessWidget {
  const _MysteryCard({
    required this.title,
    required this.days,
    required this.description,
    required this.icon,
    required this.isSuggested,
    required this.onTap,
  });

  final String title;
  final String days;
  final String description;
  final IconData icon;
  final bool isSuggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (isSuggested)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                color: AppColors.burgundy,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      days,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.burgundy,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.burgundy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowToPrayCard extends StatelessWidget {
  const _HowToPrayCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'New to the Rosary?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'The guided Rosary leads you through each mystery and every prayer one step at a time. You do not need to memorize anything.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}