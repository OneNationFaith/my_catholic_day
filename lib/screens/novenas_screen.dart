import "package:flutter/material.dart";

import "../data/novenas/divine_mercy_novena.dart";
import "../data/novenas/holy_spirit_novena.dart";
import "../data/novenas/our_lady_perpetual_help_novena.dart";
import "../data/novenas/saint_joseph_novena.dart";
import "../data/novenas/saint_jude_novena.dart";
import "../data/novenas/sacred_heart_novena.dart";
import "../theme/app_theme.dart";
import "guided_novena_screen.dart";

class NovenasScreen extends StatelessWidget {
  const NovenasScreen({super.key});

  static const List<_NovenaItem> _novenas = [
    _NovenaItem(
      id: "divine-mercy-novena",
      title: "Divine Mercy Novena",
      subtitle:
          "Nine days of prayer asking for the mercy of Jesus for the whole world.",
      icon: Icons.water_drop_outlined,
      isAvailable: true,
    ),
    _NovenaItem(
      id: "holy-spirit-novena",
      title: "Novena to the Holy Spirit",
      subtitle:
          "Ask the Holy Spirit for wisdom, strength, and renewed faith.",
      icon: Icons.local_fire_department_outlined,
      isAvailable: true,
    ),
    _NovenaItem(
      id: "saint-joseph-novena",
      title: "Novena to Saint Joseph",
      subtitle:
          "Seek the intercession of Saint Joseph for family, work, and protection.",
      icon: Icons.home_outlined,
      isAvailable: true,
    ),
    _NovenaItem(
      id: "our-lady-perpetual-help",
      title: "Our Lady of Perpetual Help",
      subtitle:
          "Ask the Blessed Mother for help in times of difficulty and need.",
      icon: Icons.favorite_outline,
      isAvailable: true,
    ),
    _NovenaItem(
      id: "sacred-heart-novena",
      title: "Sacred Heart Novena",
      subtitle:
          "Entrust your intentions to the loving Heart of Jesus.",
      icon: Icons.volunteer_activism_outlined,
      isAvailable: true,
    ),
    _NovenaItem(
      id: "saint-jude-novena",
      title: "Novena to Saint Jude",
      subtitle:
          "Pray for hope and help in difficult or desperate situations.",
      icon: Icons.anchor_outlined,
      isAvailable: true,
    ),
  ];

  void _openNovena(
    BuildContext context,
    _NovenaItem novena,
  ) {
    switch (novena.id) {
      case "divine-mercy-novena":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GuidedNovenaScreen(
              novenaId: "divine-mercy-novena",
              title: "Divine Mercy Novena",
              description: divineMercyNovenaDescription,
              days: divineMercyNovenaDays,
            ),
          ),
        );
        return;

      case "holy-spirit-novena":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GuidedNovenaScreen(
              novenaId: "holy-spirit-novena",
              title: "Novena to the Holy Spirit",
              description:
                  "Pray for the gifts and fruits of the Holy Spirit over nine days.",
              days: holySpiritNovenaDays,
            ),
          ),
        );
        return;

      case "saint-joseph-novena":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GuidedNovenaScreen(
              novenaId: "saint-joseph-novena",
              title: "Novena to Saint Joseph",
              description:
                  "Pray for Saint Joseph's intercession for family, work, protection, holiness, and a faithful life.",
              days: saintJosephNovenaDays,
            ),
          ),
        );
        return;

      case "our-lady-perpetual-help":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GuidedNovenaScreen(
              novenaId: "our-lady-perpetual-help",
              title: "Our Lady of Perpetual Help",
              description:
                  "Seek the loving intercession of Mary, Our Lady of Perpetual Help, and entrust every need to her care.",
              days: ourLadyPerpetualHelpNovenaDays,
            ),
          ),
        );
        return;

      case "sacred-heart-novena":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GuidedNovenaScreen(
              novenaId: "sacred-heart-novena",
              title: "Sacred Heart Novena",
              description:
                  "Entrust your life and intentions to the loving and merciful Heart of Jesus.",
              days: sacredHeartNovenaDays,
            ),
          ),
        );
        return;

      case "saint-jude-novena":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GuidedNovenaScreen(
              novenaId: "saint-jude-novena",
              title: "Novena to Saint Jude",
              description:
                  "Pray with Saint Jude, patron of difficult and desperate causes, for hope, strength, and trust in God.",
              days: saintJudeNovenaDays,
            ),
          ),
        );
        return;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${novena.title} will be added next."),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Novenas"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          children: [
            Text(
              "Nine Days of Prayer",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Choose a novena and pray one day at a time.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ..._novenas.map(
              (novena) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openNovena(context, novena),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(
                                alpha: novena.isAvailable ? 0.18 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              novena.icon,
                              color: novena.isAvailable
                                  ? AppColors.navy
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  novena.title,
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  novena.subtitle,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
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

class _NovenaItem {
  const _NovenaItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isAvailable = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAvailable;
}