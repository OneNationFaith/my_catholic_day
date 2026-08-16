import 'package:flutter/material.dart';

import '../models/saint.dart';
import '../theme/app_theme.dart';

class SaintDetailScreen extends StatelessWidget {
  const SaintDetailScreen({super.key, required this.saint});

  final Saint saint;

  @override
  Widget build(BuildContext context) {
    final bool hasSaintType = _hasText(saint.saintType);
    final bool hasPatronages = saint.patronages.isNotEmpty;
    final bool hasBirthInformation = _hasLifeInformation(
      saint.birthInformation,
    );
    final bool hasDeathInformation = _hasLifeInformation(
      saint.deathInformation,
    );
    final bool hasReflection = _hasText(saint.shortReflection);
    final bool hasPrayer = _hasText(saint.prayer);

    return Scaffold(
      appBar: AppBar(title: const Text('Saint of the Day')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          40 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SaintHeader(saint: saint, showSaintType: hasSaintType),
            const SizedBox(height: 20),
            _DetailSection(
              icon: Icons.auto_stories_outlined,
              title: 'Biography',
              child: Text(
                saint.shortBiography,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (hasPatronages) ...[
              const SizedBox(height: 20),
              _DetailSection(
                icon: Icons.favorite_outline,
                title: 'Patronages',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: saint.patronages
                      .map((String patronage) => Chip(label: Text(patronage)))
                      .toList(),
                ),
              ),
            ],
            if (hasBirthInformation) ...[
              const SizedBox(height: 20),
              _DetailSection(
                icon: Icons.cake_outlined,
                title: 'Birth',
                child: _LifeInformationDetails(
                  information: saint.birthInformation!,
                ),
              ),
            ],
            if (hasDeathInformation) ...[
              const SizedBox(height: 20),
              _DetailSection(
                icon: Icons.church_outlined,
                title: 'Death',
                child: _LifeInformationDetails(
                  information: saint.deathInformation!,
                ),
              ),
            ],
            if (hasReflection) ...[
              const SizedBox(height: 20),
              _DetailSection(
                icon: Icons.lightbulb_outline,
                title: 'Reflection',
                child: Text(
                  saint.shortReflection!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
            if (hasPrayer) ...[
              const SizedBox(height: 20),
              _DetailSection(
                icon: Icons.volunteer_activism_outlined,
                title: 'Prayer',
                child: Text(
                  saint.prayer!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SaintHeader extends StatelessWidget {
  const _SaintHeader({required this.saint, required this.showSaintType});

  final Saint saint;
  final bool showSaintType;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.person_outline, color: AppColors.gold, size: 48),
            const SizedBox(height: 16),
            Text(
              saint.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppColors.white),
            ),
            if (showSaintType) ...[
              const SizedBox(height: 8),
              Text(
                saint.saintType!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.gold),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Feast Day • ${_formatFeastDate(saint)}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

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
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _LifeInformationDetails extends StatelessWidget {
  const _LifeInformationDetails({required this.information});

  final SaintLifeInformation information;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasText(information.date))
          Text(
            'Date: ${information.date}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        if (_hasText(information.place)) ...[
          if (_hasText(information.date)) const SizedBox(height: 8),
          Text(
            'Place: ${information.place}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        if (_hasText(information.notes)) ...[
          if (_hasText(information.date) || _hasText(information.place))
            const SizedBox(height: 8),
          Text(
            information.notes!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ],
    );
  }
}

bool _hasLifeInformation(SaintLifeInformation? information) {
  return information != null &&
      (_hasText(information.date) ||
          _hasText(information.place) ||
          _hasText(information.notes));
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _formatFeastDate(Saint saint) {
  const List<String> months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[saint.feastMonth - 1]} ${saint.feastDay}';
}
