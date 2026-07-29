import "package:flutter/material.dart";

import "../models/guided_prayer.dart";
import "../services/progress_service.dart";
import "../theme/app_theme.dart";

class GuidedPrayerScreen extends StatefulWidget {
  const GuidedPrayerScreen({
    super.key,
    required this.prayer,
  });

  final GuidedPrayer prayer;

  @override
  State<GuidedPrayerScreen> createState() =>
      _GuidedPrayerScreenState();
}

class _GuidedPrayerScreenState
    extends State<GuidedPrayerScreen> {
  int _currentStepIndex = 0;
  bool _isLoading = true;

  String get _progressKey =>
      "guided_prayer_progress_${widget.prayer.id}";

  GuidedPrayerStep get _currentStep =>
      widget.prayer.steps[_currentStepIndex];

  bool get _isFirstStep => _currentStepIndex == 0;

  bool get _isLastStep =>
      _currentStepIndex == widget.prayer.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final savedStepIndex =
        await ProgressService.getProgress(_progressKey);

    if (!mounted) {
      return;
    }

    setState(() {
      if (savedStepIndex >= 0 &&
          savedStepIndex < widget.prayer.steps.length) {
        _currentStepIndex = savedStepIndex;
      } else {
        _currentStepIndex = 0;
      }

      _isLoading = false;
    });
  }

  Future<void> _saveProgress() async {
    await ProgressService.saveProgress(
      _progressKey,
      _currentStepIndex,
    );
  }

  Future<void> _goToPreviousStep() async {
    if (_isFirstStep) {
      return;
    }

    setState(() {
      _currentStepIndex--;
    });

    await _saveProgress();
  }

  Future<void> _goToNextStep() async {
    if (_isLastStep) {
      await _showCompletionDialog();
      return;
    }

    setState(() {
      _currentStepIndex++;
    });

    await _saveProgress();
  }

  Future<void> _startOver() async {
    await ProgressService.clearProgress(_progressKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentStepIndex = 0;
    });
  }

  Future<void> _showStartOverDialog() async {
    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Start Over?"),
        content: Text(
          "This will return ${widget.prayer.title} "
          "to the beginning.",
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
        title: const Text("Prayer Complete"),
        content: Text(
          "You have completed ${widget.prayer.title}. "
          "Take a moment to remain with God in silence.",
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
          title: Text(widget.prayer.title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final overallProgress =
        (_currentStepIndex + 1) /
        widget.prayer.steps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prayer.title),
        actions: [
          IconButton(
            tooltip: "Start Over",
            onPressed: _showStartOverDialog,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(
              currentStep: _currentStepIndex + 1,
              totalSteps: widget.prayer.steps.length,
              progress: overallProgress,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: 250),
                child: SingleChildScrollView(
                  key: ValueKey(_currentStep.id),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    30,
                  ),
                  child: _PrayerStepCard(
                    step: _currentStep,
                  ),
                ),
              ),
            ),
            _NavigationBar(
              isFirstStep: _isFirstStep,
              isLastStep: _isLastStep,
              onPrevious: _goToPreviousStep,
              onNext: _goToNextStep,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.progress,
  });

  final int currentStep;
  final int totalSteps;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Step $currentStep of $totalSteps",
                style:
                    Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                "${(progress * 100).round()}%",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(20),
            backgroundColor:
                AppColors.gold.withValues(alpha: 0.18),
            valueColor:
                const AlwaysStoppedAnimation<Color>(
              AppColors.burgundy,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerStepCard extends StatelessWidget {
  const _PrayerStepCard({
    required this.step,
  });

  final GuidedPrayerStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        if (step.hasSectionProgress)
          _SectionProgressCard(step: step),
        if (step.hasSectionProgress)
          const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconForStep(step.type),
                  size: 38,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 18),
                Text(
                  step.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
                if (step.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    step.subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color:
                              AppColors.textSecondary,
                        ),
                  ),
                ],
                if (step.hasRepetitionProgress) ...[
                  const SizedBox(height: 14),
                  _RepetitionIndicator(step: step),
                ],
                const SizedBox(height: 22),
                SelectableText(
                  step.body,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        height: 1.65,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForStep(
    GuidedPrayerStepType type,
  ) {
    switch (type) {
      case GuidedPrayerStepType.introduction:
        return Icons.auto_awesome_outlined;
      case GuidedPrayerStepType.mystery:
        return Icons.church_outlined;
      case GuidedPrayerStepType.scripture:
        return Icons.menu_book_outlined;
      case GuidedPrayerStepType.reflection:
        return Icons.lightbulb_outline;
      case GuidedPrayerStepType.ourFather:
        return Icons.church_outlined;
      case GuidedPrayerStepType.hailMary:
        return Icons.favorite_outline;
      case GuidedPrayerStepType.gloryBe:
        return Icons.auto_awesome_outlined;
      case GuidedPrayerStepType.fatimaPrayer:
        return Icons.volunteer_activism_outlined;
      case GuidedPrayerStepType.creed:
        return Icons.shield_outlined;
      case GuidedPrayerStepType.repeatedPrayer:
        return Icons.radio_button_checked;
      case GuidedPrayerStepType.closingPrayer:
        return Icons.wb_twilight_outlined;
    }
  }
}

class _SectionProgressCard extends StatelessWidget {
  const _SectionProgressCard({
    required this.step,
  });

  final GuidedPrayerStep step;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 22,
        ),
        child: Column(
          children: [
            Text(
              step.sectionTitle ?? "",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "${step.sectionNumber} of "
              "${step.totalSections}",
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepetitionIndicator extends StatelessWidget {
  const _RepetitionIndicator({
    required this.step,
  });

  final GuidedPrayerStep step;

  @override
  Widget build(BuildContext context) {
    final total = step.totalRepetitions!;
    final current = step.repetitionNumber!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        total,
        (index) {
          final beadNumber = index + 1;
          final isComplete =
              beadNumber <= current;

          return AnimatedContainer(
            duration:
                const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete
                  ? AppColors.burgundy
                  : AppColors.gold.withValues(
                      alpha: 0.18,
                    ),
              border: Border.all(
                color: isComplete
                    ? AppColors.burgundy
                    : AppColors.gold,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.isFirstStep,
    required this.isLastStep,
    required this.onPrevious,
    required this.onNext,
  });

  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  isFirstStep ? null : onPrevious,
              icon:
                  const Icon(Icons.arrow_back),
              label: const Text("Previous"),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton.icon(
              onPressed: onNext,
              icon: Icon(
                isLastStep
                    ? Icons.check_circle_outline
                    : Icons.arrow_forward,
              ),
              label: Text(
                isLastStep
                    ? "Complete"
                    : "Next",
              ),
            ),
          ),
        ],
      ),
    );
  }
}