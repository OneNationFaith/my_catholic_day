import "package:flutter/material.dart";

import "../models/novena.dart";
import "../services/progress_service.dart";
import "../theme/app_theme.dart";

class GuidedNovenaScreen extends StatefulWidget {
  const GuidedNovenaScreen({
    super.key,
    required this.novenaId,
    required this.title,
    required this.description,
    required this.days,
  });

  final String novenaId;
  final String title;
  final String description;
  final List<NovenaDay> days;

  @override
  State<GuidedNovenaScreen> createState() =>
      _GuidedNovenaScreenState();
}

class _GuidedNovenaScreenState
    extends State<GuidedNovenaScreen> {
  int _currentDayIndex = 0;
  bool _isLoading = true;

  String get _progressKey =>
      "novena_progress_${widget.novenaId}";

  NovenaDay get _currentDay =>
      widget.days[_currentDayIndex];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final savedDayIndex =
        await ProgressService.getProgress(_progressKey);

    if (!mounted) {
      return;
    }

    setState(() {
      if (savedDayIndex >= 0 &&
          savedDayIndex < widget.days.length) {
        _currentDayIndex = savedDayIndex;
      } else {
        _currentDayIndex = 0;
      }

      _isLoading = false;
    });
  }

  Future<void> _saveProgress() async {
    await ProgressService.saveProgress(
      _progressKey,
      _currentDayIndex,
    );
  }

  Future<void> _goToPreviousDay() async {
    if (_currentDayIndex == 0) {
      return;
    }

    setState(() {
      _currentDayIndex--;
    });

    await _saveProgress();
  }

  Future<void> _goToNextDay() async {
    if (_currentDayIndex < widget.days.length - 1) {
      setState(() {
        _currentDayIndex++;
      });

      await _saveProgress();
      return;
    }

    await _showCompletionDialog();
  }

  Future<void> _startOver() async {
    await ProgressService.clearProgress(_progressKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentDayIndex = 0;
    });
  }

  Future<void> _showStartOverDialog() async {
    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Start Over?"),
        content: Text(
          "This will return ${widget.title} to Day 1.",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(true),
            child: const Text("Start Over"),
          ),
        ],
      ),
    );

    if (shouldRestart == true) {
      await _startOver();
    }
  }

  Future<void> _showCompletionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novena Complete"),
        content: Text(
          "You have completed ${widget.title}. "
          "May God receive your prayer and strengthen your faith.",
        ),
        actions: [
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(),
            child: const Text("Amen"),
          ),
        ],
      ),
    );

    await _startOver();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final progress =
        (_currentDayIndex + 1) / widget.days.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: "Start Over",
            onPressed: _showStartOverDialog,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(20, 22, 20, 30),
          children: [
            Text(
              widget.description,
              style:
                  Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 10),
            Text(
              "Day ${_currentDay.day} of ${widget.days.length}",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentDay.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      "Today's Intention",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: AppColors.burgundy,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentDay.intention,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Prayer",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: AppColors.burgundy,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _currentDay.prayer,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentDayIndex == 0
                        ? null
                        : _goToPreviousDay,
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                    label: const Text("Previous"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _goToNextDay,
                    icon: Icon(
                      _currentDayIndex ==
                              widget.days.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _currentDayIndex ==
                              widget.days.length - 1
                          ? "Complete"
                          : "Next Day",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}