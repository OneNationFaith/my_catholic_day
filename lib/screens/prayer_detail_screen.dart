import 'package:flutter/material.dart';

import '../models/prayer.dart';
import '../theme/app_theme.dart';

class PrayerDetailScreen extends StatelessWidget {
  const PrayerDetailScreen({
    super.key,
    required this.prayer,
  });

  final Prayer prayer;

  bool get hasScripture =>
      prayer.scripture.trim().isNotEmpty;

  bool get hasReflection =>
      prayer.reflection.trim().isNotEmpty;

  bool get hasAction =>
      prayer.action.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(prayer.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(prayer: prayer),

            const SizedBox(height: 20),

            if (hasScripture)
              _SectionCard(
                icon: Icons.menu_book_outlined,
                title: 'Scripture',
                content: prayer.scripture,
                footer: prayer.scriptureReference,
              ),

            if (hasScripture)
              const SizedBox(height: 20),

            if (hasReflection)
              _SectionCard(
                icon: Icons.lightbulb_outline,
                title: 'Reflection',
                content: prayer.reflection,
              ),

            if (hasReflection)
              const SizedBox(height: 20),

            _SectionCard(
              icon: Icons.volunteer_activism_outlined,
              title: 'Prayer',
              content: prayer.prayer,
            ),

            if (hasAction)
              const SizedBox(height: 20),

            if (hasAction)
              _SectionCard(
                icon: Icons.check_circle_outline,
                title: 'Take a Small Step',
                content: prayer.action,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 28,
          horizontal: 20,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.church_outlined,
              color: AppColors.gold,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              prayer.title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a slow breath. God is here with you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.content,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String content;
  final String? footer;

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
                Icon(icon, color: AppColors.navy),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (footer != null && footer!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                footer!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.burgundy,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}