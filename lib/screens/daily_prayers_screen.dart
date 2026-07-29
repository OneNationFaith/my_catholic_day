import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'prayer_detail_screen.dart';
import '../data/repositories/prayer_repository.dart';

class DailyPrayersScreen extends StatelessWidget {
  const DailyPrayersScreen({super.key});

  static const List<_DailyPrayerItem> _items = [
    _DailyPrayerItem(
      prayerId: 'morning-offering',
      icon: Icons.wb_sunny_outlined,
      title: 'Morning Offering',
      subtitle: 'Begin the day by offering everything to God.',
    ),
    _DailyPrayerItem(
      prayerId: 'before-meals',
      icon: Icons.restaurant_outlined,
      title: 'Grace Before Meals',
      subtitle: 'Thank God for the food you are about to receive.',
    ),
    _DailyPrayerItem(
      prayerId: 'after-meals',
      icon: Icons.local_dining_outlined,
      title: 'Grace After Meals',
      subtitle: 'Give thanks after eating.',
    ),
    _DailyPrayerItem(
      prayerId: 'before-work',
      icon: Icons.work_outline,
      title: 'Prayer Before Work',
      subtitle: 'Ask God to guide your work and service.',
    ),
    _DailyPrayerItem(
      prayerId: 'before-travel',
      icon: Icons.directions_car_outlined,
      title: 'Prayer Before Traveling',
      subtitle: 'Ask for protection on your journey.',
    ),
    _DailyPrayerItem(
      prayerId: 'before-study',
      icon: Icons.school_outlined,
      title: 'Prayer Before Study',
      subtitle: 'Ask the Holy Spirit for wisdom and understanding.',
    ),
    _DailyPrayerItem(
      prayerId: 'family-prayer',
      icon: Icons.family_restroom_outlined,
      title: 'Family Prayer',
      subtitle: 'Place your household in God’s care.',
    ),
    _DailyPrayerItem(
      prayerId: 'night-prayer',
      icon: Icons.nightlight_outlined,
      title: 'Night Prayer',
      subtitle: 'End the day with gratitude and trust.',
    ),
    _DailyPrayerItem(
      prayerId: 'act-of-contrition',
      icon: Icons.favorite_border,
      title: 'Act of Contrition',
      subtitle: 'Express sorrow for sin and trust in God’s mercy.',
    ),
    _DailyPrayerItem(
      prayerId: 'spiritual-communion',
      icon: Icons.church_outlined,
      title: 'Spiritual Communion',
      subtitle: 'Express your desire to receive Jesus spiritually.',
    ),
    _DailyPrayerItem(
      prayerId: 'saint-michael',
      icon: Icons.shield_outlined,
      title: 'Prayer to Saint Michael',
      subtitle: 'Ask Saint Michael for protection against evil.',
    ),
    _DailyPrayerItem(
      prayerId: 'angelus',
      icon: Icons.notifications_none_outlined,
      title: 'The Angelus',
      subtitle: 'Remember the Incarnation of Jesus.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Prayers'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          children: [
            Text(
              'Prayer for Every Part of the Day',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a prayer for the moment you are in.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      final prayer =
                          PrayerRepository.getById(item.prayerId);

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PrayerDetailScreen(
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
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.burgundy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyPrayerItem {
  const _DailyPrayerItem({
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