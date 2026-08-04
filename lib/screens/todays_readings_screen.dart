import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reading.dart';
import '../services/daily_readings_service.dart';

class TodaysReadingsScreen extends StatefulWidget {
  const TodaysReadingsScreen({super.key});

  @override
  State<TodaysReadingsScreen> createState() =>
      _TodaysReadingsScreenState();
}

class _TodaysReadingsScreenState
    extends State<TodaysReadingsScreen> {
  static const Color _navy = Color(0xFF17324D);
  static const Color _burgundy = Color(0xFF7A263A);
  static const Color _cream = Color(0xFFF7F2E8);

  final DailyReadingsService _readingsService =
      DailyReadingsService();

  late DateTime _selectedDate;
  late Future<DailyReadings> _readingsFuture;

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();

    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    _readingsFuture =
        _readingsService.getForDate(_selectedDate);
  }

  void _loadDate(DateTime date) {
    final DateTime normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    setState(() {
      _selectedDate = normalizedDate;
      _readingsFuture =
          _readingsService.getForDate(normalizedDate);
    });
  }

  void _goToPreviousDay() {
    _loadDate(
      _selectedDate.subtract(
        const Duration(days: 1),
      ),
    );
  }

  void _goToNextDay() {
    _loadDate(
      _selectedDate.add(
        const Duration(days: 1),
      ),
    );
  }

  void _goToToday() {
    _loadDate(DateTime.now());
  }

  Future<void> _chooseDate() async {
    final DateTime? chosenDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Choose a date',
      cancelText: 'Cancel',
      confirmText: 'View Readings',
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(
                  primary: _navy,
                  secondary: _burgundy,
                ),
          ),
          child: child!,
        );
      },
    );

    if (chosenDate != null) {
      _loadDate(chosenDate);
    }
  }

  Future<void> _refresh() async {
    final Future<DailyReadings> refreshedReadings =
        _readingsService.getForDate(_selectedDate);

    setState(() {
      _readingsFuture = refreshedReadings;
    });

    await refreshedReadings;
  }

  bool get _isViewingToday {
    final DateTime now = DateTime.now();

    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text("Mass Readings"),
        actions: <Widget>[
          IconButton(
            tooltip: 'Choose a date',
            onPressed: _chooseDate,
            icon: const Icon(
              Icons.calendar_month_outlined,
            ),
          ),
        ],
      ),
      body: FutureBuilder<DailyReadings>(
        future: _readingsFuture,
        builder: (
          BuildContext context,
          AsyncSnapshot<DailyReadings> snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return _LoadingView(
              selectedDate: _selectedDate,
              onPreviousDay: _goToPreviousDay,
              onNextDay: _goToNextDay,
              onChooseDate: _chooseDate,
            );
          }

          if (snapshot.hasError) {
            return _ReadingsErrorView(
              selectedDate: _selectedDate,
              error: snapshot.error,
              onPreviousDay: _goToPreviousDay,
              onNextDay: _goToNextDay,
              onChooseDate: _chooseDate,
              onRetry: _refresh,
            );
          }

          final DailyReadings readings = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                56,
              ),
              children: <Widget>[
                _DateNavigationCard(
                  selectedDate: _selectedDate,
                  isViewingToday: _isViewingToday,
                  onPreviousDay: _goToPreviousDay,
                  onNextDay: _goToNextDay,
                  onChooseDate: _chooseDate,
                  onToday: _goToToday,
                ),
                if (readings.readings.isNotEmpty) ...<Widget>[
  const SizedBox(height: 18),
  _ReadingsHeader(readings: readings),
  const SizedBox(height: 18),
],
if (readings.readings.isEmpty)
                  _NoReadingsCard(
                    selectedDate: _selectedDate,
                    onChooseDate: _chooseDate,
                    onToday: _goToToday,
                  )
                else
                  ...readings.readings.map(
                    (DailyReading reading) =>
                        Padding(
                      padding:
                          const EdgeInsets.only(bottom: 16),
                      child: _ReadingCard(
                        reading: reading,
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                _TranslationNotice(readings: readings),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateNavigationCard extends StatelessWidget {
  const _DateNavigationCard({
    required this.selectedDate,
    required this.isViewingToday,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onChooseDate,
    required this.onToday,
  });

  final DateTime selectedDate;
  final bool isViewingToday;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onChooseDate;
  final VoidCallback onToday;

  static const Color _navy = Color(0xFF17324D);
  static const Color _gold = Color(0xFFC69A45);

  @override
  Widget build(BuildContext context) {
    final String dateText = DateFormat(
      'EEEE, MMMM d, y',
    ).format(selectedDate);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          8,
          12,
          8,
          12,
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: onPreviousDay,
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 32,
                    color: _navy,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(12),
                    onTap: onChooseDate,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Column(
                        children: <Widget>[
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: _navy,
                            size: 22,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            dateText,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: _navy,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Tap to choose another date',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.black54,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next day',
                  onPressed: onNextDay,
                  icon: const Icon(
                    Icons.chevron_right,
                    size: 32,
                    color: _navy,
                  ),
                ),
              ],
            ),
            if (!isViewingToday) ...<Widget>[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: onToday,
                icon: const Icon(Icons.today_outlined),
                label: const Text('Return to Today'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadingsHeader extends StatelessWidget {
  const _ReadingsHeader({
    required this.readings,
  });

  final DailyReadings readings;

  static const Color _navy = Color(0xFF17324D);
  static const Color _burgundy = Color(0xFF7A263A);
  static const Color _gold = Color(0xFFC69A45);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            _navy,
            Color(0xFF244A6B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: _gold,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      readings.liturgicalDay,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(
                        'MMMM d, y',
                      ).format(readings.date),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _burgundy,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: _gold.withValues(alpha: 0.75),
              ),
            ),
            child: Text(
              readings.translationAbbreviation,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.reading,
  });

  final DailyReading reading;

  static const Color _navy = Color(0xFF17324D);
  static const Color _burgundy = Color(0xFF7A263A);
  static const Color _gold = Color(0xFFC69A45);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _borderColor.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _icon,
                    color: _iconColor,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        reading.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: _navy,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (reading.hasReference) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          reading.reference,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: _burgundy,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (reading.hasResponse) ...<Widget>[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  'Response: ${reading.response}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: _navy,
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
                    color: const Color(0xFF252525),
                    height: 1.65,
                    fontSize: 17,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    switch (reading.kind) {
      case ReadingKind.firstReading:
        return Icons.menu_book_outlined;
      case ReadingKind.responsorialPsalm:
        return Icons.music_note_outlined;
      case ReadingKind.secondReading:
        return Icons.library_books_outlined;
      case ReadingKind.gospelAcclamation:
        return Icons.campaign_outlined;
      case ReadingKind.gospel:
        return Icons.auto_stories_outlined;
      case ReadingKind.other:
        return Icons.book_outlined;
    }
  }

  Color get _iconColor {
    switch (reading.kind) {
      case ReadingKind.gospel:
        return _burgundy;
      case ReadingKind.responsorialPsalm:
        return const Color(0xFF926C1A);
      default:
        return _navy;
    }
  }

  Color get _backgroundColor {
    switch (reading.kind) {
      case ReadingKind.gospel:
        return const Color(0xFFF7E9ED);
      case ReadingKind.responsorialPsalm:
        return const Color(0xFFFFF4D8);
      default:
        return const Color(0xFFEAF1F7);
    }
  }

  Color get _borderColor {
    switch (reading.kind) {
      case ReadingKind.gospel:
        return _burgundy;
      case ReadingKind.responsorialPsalm:
        return _gold;
      default:
        return _navy;
    }
  }
}

class _NoReadingsCard extends StatelessWidget {
  const _NoReadingsCard({
    required this.selectedDate,
    required this.onChooseDate,
    required this.onToday,
  });

  final DateTime selectedDate;
  final VoidCallback onChooseDate;
  final VoidCallback onToday;

  static const Color _navy = Color(0xFF17324D);
  static const Color _gold = Color(0xFFC69A45);

  @override
  Widget build(BuildContext context) {
    final String dateText = DateFormat(
      'MMMM d, y',
    ).format(selectedDate);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _gold.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.event_note_outlined,
              size: 52,
              color: _navy,
            ),
            const SizedBox(height: 16),
            Text(
              'Readings Coming Soon',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'The Mass reading references for '
              '$dateText have not been added yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                    height: 1.5,
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onChooseDate,
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                  ),
                  label: const Text('Choose Date'),
                ),
                FilledButton.icon(
                  onPressed: onToday,
                  icon: const Icon(Icons.today_outlined),
                  label: const Text('Go to Today'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslationNotice extends StatelessWidget {
  const _TranslationNotice({
    required this.readings,
  });

  final DailyReadings readings;

  static const Color _navy = Color(0xFF17324D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline,
            color: _navy,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              readings.translationNotice,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: _navy,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({
    required this.selectedDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onChooseDate,
  });

  final DateTime selectedDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onChooseDate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        _DateNavigationCard(
          selectedDate: selectedDate,
          isViewingToday: true,
          onPreviousDay: onPreviousDay,
          onNextDay: onNextDay,
          onChooseDate: onChooseDate,
          onToday: onChooseDate,
        ),
        const SizedBox(height: 80),
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }
}

class _ReadingsErrorView extends StatelessWidget {
  const _ReadingsErrorView({
    required this.selectedDate,
    required this.error,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onChooseDate,
    required this.onRetry,
  });

  final DateTime selectedDate;
  final Object? error;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onChooseDate;
  final Future<void> Function() onRetry;

  static const Color _burgundy = Color(0xFF7A263A);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        _DateNavigationCard(
          selectedDate: selectedDate,
          isViewingToday: true,
          onPreviousDay: onPreviousDay,
          onNextDay: onNextDay,
          onChooseDate: onChooseDate,
          onToday: onChooseDate,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.error_outline,
                  size: 52,
                  color: _burgundy,
                ),
                const SizedBox(height: 15),
                Text(
                  'The readings could not be loaded.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        color: _burgundy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}