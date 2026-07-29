import "package:flutter/material.dart";

import "../theme/app_theme.dart";
import "daily_prayers_screen.dart";
import "divine_mercy_chaplet_screen.dart";
import "novenas_screen.dart";
import "pray_with_me_screen.dart";
import "rosary_screen.dart";
import "traditional_prayers_screen.dart";

class PrayScreen extends StatelessWidget {
  const PrayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        children: [
          Text(
            "How would you like to pray?",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "Choose a prayer experience below.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          _MenuCard(
            icon: Icons.favorite_outline,
            title: "Pray With Me",
            subtitle: "Prayers for how you are feeling today.",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrayWithMeScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _MenuCard(
            icon: Icons.menu_book_outlined,
            title: "Traditional Prayers",
            subtitle: "The most common Catholic prayers.",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TraditionalPrayersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _MenuCard(
            icon: Icons.auto_stories_outlined,
            title: "Rosary",
            subtitle: "Pray the mysteries of Christ with Mary.",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RosaryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _MenuCard(
            icon: Icons.water_drop_outlined,
            title: "Divine Mercy Chaplet",
            subtitle: "Pray the Chaplet of Divine Mercy.",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DivineMercyChapletScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _MenuCard(
            icon: Icons.calendar_month_outlined,
            title: "Daily Prayers",
            subtitle:
                "Prayers for morning, meals, work, travel, and night.",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DailyPrayersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _MenuCard(
            icon: Icons.groups_outlined,
            title: "Novenas",
            subtitle:
                "Pray with the Church for nine consecutive days.",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NovenasScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }
}