import 'package:flutter/material.dart';

import '../data/repositories/prayer_repository.dart';
import '../theme/app_theme.dart';
import 'prayer_detail_screen.dart';

class TraditionalPrayersScreen extends StatelessWidget {
  const TraditionalPrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final traditionalPrayers =
        PrayerRepository.getByCategory('Traditional Prayer');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traditional Prayers'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          children: [
            Text(
              'Prayers of the Catholic Faith',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Learn, pray, and return to these treasured prayers of the Church.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ...traditionalPrayers.map(
              (prayer) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
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
                            child: const Icon(
                              Icons.menu_book_outlined,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              prayer.title,
                              style: Theme.of(context).textTheme.titleLarge,
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