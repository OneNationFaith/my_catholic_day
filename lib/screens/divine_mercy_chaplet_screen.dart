import "package:flutter/material.dart";

import "../data/prayers/divine_mercy_chaplet.dart";
import "guided_prayer_screen.dart";

class DivineMercyChapletScreen extends StatelessWidget {
  const DivineMercyChapletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GuidedPrayerScreen(
      prayer: divineMercyChaplet,
    );
  }
}