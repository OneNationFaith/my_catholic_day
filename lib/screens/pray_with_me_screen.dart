import 'package:flutter/material.dart';

import '../data/repositories/prayer_repository.dart';
import '../theme/app_theme.dart';
import 'prayer_detail_screen.dart';

class PrayWithMeScreen extends StatelessWidget {
  const PrayWithMeScreen({super.key});

  static const List<PrayerNeed> _needs = [
    PrayerNeed(
      prayerId: 'anxiety',
      icon: Icons.psychology_alt_outlined,
      title: 'I am anxious',
      subtitle: 'Bring your worries to God and rest in His care.',
    ),
    PrayerNeed(
      prayerId: 'fear',
      icon: Icons.shield_outlined,
      title: 'I am afraid',
      subtitle: 'Ask God for courage, protection, and peace.',
    ),
    PrayerNeed(
      prayerId: 'lonely',
      icon: Icons.person_outline,
      title: 'I feel lonely',
      subtitle: 'Remember that God is near and you are not forgotten.',
    ),
    PrayerNeed(
      prayerId: 'grief',
      icon: Icons.favorite_border,
      title: 'I am grieving',
      subtitle: 'Pray for comfort, strength, and hope.',
    ),
    PrayerNeed(
      prayerId: 'sick',
      icon: Icons.healing_outlined,
      title: 'I am sick',
      subtitle: 'Ask Christ for healing and endurance.',
    ),
    PrayerNeed(
      prayerId: 'loved-one-sick',
      icon: Icons.volunteer_activism_outlined,
      title: 'Someone I love is sick',
      subtitle: 'Place that person in God’s loving hands.',
    ),
    PrayerNeed(
      prayerId: 'anger',
      icon: Icons.sentiment_dissatisfied_outlined,
      title: 'I am angry',
      subtitle: 'Ask God to calm your heart and guide your response.',
    ),
    PrayerNeed(
      prayerId: 'forgiveness',
      icon: Icons.restart_alt,
      title: 'I need forgiveness',
      subtitle: 'Return to God with honesty and trust.',
    ),
    PrayerNeed(
      prayerId: 'thankful',
      icon: Icons.wb_sunny_outlined,
      title: 'I am thankful',
      subtitle: 'Offer God your gratitude and praise.',
    ),
    PrayerNeed(
      prayerId: 'far-from-god',
      icon: Icons.cloud_outlined,
      title: 'I feel far from God',
      subtitle: 'Ask for renewed faith and a sense of His presence.',
    ),
    PrayerNeed(
      prayerId: 'unsure',
      icon: Icons.help_outline,
      title: 'I do not know what I need',
      subtitle: 'Sit quietly and let God meet you where you are.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pray With Me'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          children: [
            Text(
              'What are you carrying today?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what best describes how you feel. You do not need the perfect words.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ..._needs.map(
              (need) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PrayerNeedCard(need: need),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerNeed {
  const PrayerNeed({
    required this.prayerId,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String prayerId;
  final IconData icon;
  final String title;
  final String subtitle;
}

class PrayerNeedCard extends StatelessWidget {
  const PrayerNeedCard({
    super.key,
    required this.need,
  });

  final PrayerNeed need;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final prayer = PrayerRepository.getById(need.prayerId);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PrayerDetailScreen(
                prayer: prayer,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  need.icon,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      need.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      need.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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