import 'package:flutter/material.dart';

import '../models/catholic_day.dart';
import '../theme/app_theme.dart';

class LiturgicalDaySummary extends StatelessWidget {
  const LiturgicalDaySummary({super.key, required this.day});

  final CatholicDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day.celebration,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.burgundy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${day.seasonName} • '
          '${day.colorName} • '
          '${day.rosaryMysteriesName}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        if (day.isHolyDayOfObligation) ...[
          const SizedBox(height: 6),
          Text(
            'Holy Day of Obligation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.burgundy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
