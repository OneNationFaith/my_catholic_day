import 'package:flutter/material.dart';

import '../models/reading.dart';
import '../services/daily_readings_service.dart';
import '../theme/app_theme.dart';

class TodaysReadingsScreen extends StatefulWidget {
  const TodaysReadingsScreen({super.key});

  @override
  State<TodaysReadingsScreen> createState() =>
      _TodaysReadingsScreenState();
}

class _TodaysReadingsScreenState
    extends State<TodaysReadingsScreen> {
  final DailyReadingsService _service =
      DailyReadingsService();

  late Future<DailyReadings> _future;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  void _loadReadings() {
    _future = _service.getToday();
  }

  Future<void> _refreshReadings() async {
    setState(_loadReadings);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Readings"),
      ),
      body: FutureBuilder<DailyReadings>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _ReadingsErrorView(
              onRetry: () {
                setState(_loadReadings);
              },
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshReadings,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                32,
              ),
              children: [
                _ReadingsHeader(data: data),
                const SizedBox(height: 22),

                ...data.readings.map(
                  (reading) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 16),
                    child: _ReadingCard(
                      reading: reading,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                _TranslationNotice(data: data),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReadingsHeader extends StatelessWidget {
  const _ReadingsHeader({
    required this.data,
  });

  final DailyReadings data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.liturgicalDay,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatDate(data.date),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.burgundy.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${data.translationAbbreviation} • '
            '${data.translationName}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
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

    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.reading,
  });

  final DailyReading reading;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconForReading(reading.kind),
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        reading.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color:
                                  AppColors.burgundy,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),
                      if (reading.hasReference) ...[
                        const SizedBox(height: 4),
                        Text(
                          reading.reference,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (reading.hasResponse) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.burgundy.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  reading.response!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: AppColors.burgundy,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                ),
              ),
            ],

            const SizedBox(height: 18),

            SelectableText(
              reading.text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                    height: 1.7,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForReading(ReadingKind kind) {
    switch (kind) {
      case ReadingKind.firstReading:
        return Icons.looks_one_outlined;

      case ReadingKind.responsorialPsalm:
        return Icons.music_note_outlined;

      case ReadingKind.secondReading:
        return Icons.looks_two_outlined;

      case ReadingKind.gospelAcclamation:
        return Icons.campaign_outlined;

      case ReadingKind.gospel:
        return Icons.auto_stories_outlined;

      case ReadingKind.other:
        return Icons.menu_book_outlined;
    }
  }
}

class _TranslationNotice extends StatelessWidget {
  const _TranslationNotice({
    required this.data,
  });

  final DailyReadings data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.navy.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.navy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.translationNotice,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: AppColors.navy,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingsErrorView extends StatelessWidget {
  const _ReadingsErrorView({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 54,
              color: AppColors.burgundy,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load today’s readings.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}