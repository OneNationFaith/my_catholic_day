import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/pray_screen.dart';
import 'screens/todays_readings_screen.dart';
import 'services/catholic_day_service.dart';
import 'models/catholic_day.dart';
import 'services/app_database.dart';
import 'services/scripture_database.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

await AppDatabase.instance.database;
await ScriptureDatabase.instance.database;
  runApp(const MyCatholicDayApp());
}

class MyCatholicDayApp extends StatelessWidget {
  const MyCatholicDayApp({super.key});

  static const Color navy = Color(0xFF17324D);
  static const Color burgundy = Color(0xFF7A263A);
  static const Color gold = Color(0xFFC69A45);
  static const Color cream = Color(0xFFF7F2E8);

  @override
  Widget build(BuildContext context) {
 

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'One Nation Faith',
      theme: AppTheme.lightTheme,

      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    TodayPage(),
PrayScreen(),
    PlaceholderPage(
      icon: Icons.menu_book_outlined,
      title: 'Learn',
      message: 'Catholic teachings and guides will be built here.',
    ),
    PlaceholderPage(
      icon: Icons.favorite_outline,
      title: 'Live',
      message: 'Daily Catholic living resources will be built here.',
    ),
    PlaceholderPage(
      icon: Icons.church_outlined,
      title: 'My Church',
      message: 'Your parish and diocesan information will be built here.',
    ),
  ];

  static const List<String> _titles = [
    'One Nation Faith',
    'Pray',
    'Learn',
    'Live',
    'My Church',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Pray',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.church_outlined),
            selectedIcon: Icon(Icons.church),
            label: 'My Church',
          ),
        ],
      ),
    );
  }
}

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final CatholicDayService _service = const CatholicDayService();

  late Future<CatholicDay> _dayFuture;

  @override
  void initState() {
    super.initState();
    _dayFuture = _service.getToday();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);
    final date = _formattedDate(now);

    return SafeArea(
      child: FutureBuilder<CatholicDay>(
        future: _dayFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'Unable to load today’s Catholic calendar information.',
              ),
            );
          }

          final catholicDay = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            children: [
              Text(
                '$greeting, Jeff',
                style:
                    Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: MyCatholicDayApp.navy,
                          fontWeight: FontWeight.w800,
                        ),
              ),
              const SizedBox(height: 6),
              Text(
                date,
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black54,
                        ),
              ),
              const SizedBox(height: 4),
              Text(
                catholicDay.celebration,
                style:
                    Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: MyCatholicDayApp.burgundy,
                          fontWeight: FontWeight.w700,
                        ),
              ),
              const SizedBox(height: 4),
              Text(
                '${catholicDay.seasonName} • '
                '${catholicDay.colorName} • '
                '${catholicDay.rosaryMysteriesName}',
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
              ),
              if (catholicDay.isHolyDayOfObligation) ...[
                const SizedBox(height: 6),
                Text(
                  'Holy Day of Obligation',
                  style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MyCatholicDayApp.burgundy,
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ],
              const SizedBox(height: 24),
              const DailyHeroCard(),
              const SizedBox(height: 18),
              SectionCard(
                icon: Icons.auto_stories_outlined,
                title: "Today's Readings",
                subtitle: "Read today's Mass readings",
                body:
                    'Read the First Reading, Responsorial Psalm, Gospel, and more.',
                buttonLabel: 'Open Readings',
                onPressed: (context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TodaysReadingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              const SectionCard(
                icon: Icons.volunteer_activism_outlined,
                title: "Today's Prayer",
                subtitle: 'Morning Offering',
                body:
                    'Begin your day by offering your prayers, works, joys, and sufferings to Christ.',
                buttonLabel: 'Pray Now',
              ),
              const SizedBox(height: 14),
              SectionCard(
                icon: Icons.person_outline,
                title: 'Saint of the Day',
                subtitle:
                    catholicDay.saintName ?? 'No saint listed today',
                body: catholicDay.saintName == null
                    ? 'Today follows the regular liturgical calendar.'
                    : 'Learn about ${catholicDay.saintName} and their witness to the faith.',
                buttonLabel: 'Learn More',
              ),
              const SizedBox(height: 14),
              const InvitationCard(),
            ],
          );
        },
      ),
    );
  }

  static String _greetingForHour(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _formattedDate(DateTime date) {
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
        '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
class DailyHeroCard extends StatelessWidget {
  const DailyHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            MyCatholicDayApp.navy,
            Color(0xFF274E70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
  '✝',
  style: TextStyle(
    color: MyCatholicDayApp.gold,
    fontSize: 42,
    fontWeight: FontWeight.bold,
  ),
),
          const SizedBox(height: 18),
          Text(
            'What does God have for me today?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Take a quiet moment to listen, pray, learn, and live your faith.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.wb_sunny_outlined),
            label: const Text('Begin Your Day'),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final String buttonLabel;
  final void Function(BuildContext context)? onPressed;

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: MyCatholicDayApp.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: MyCatholicDayApp.navy,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: MyCatholicDayApp.navy,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: MyCatholicDayApp.burgundy,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                onPressed?.call(context);
              },
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class InvitationCard extends StatelessWidget {
  const InvitationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MyCatholicDayApp.burgundy,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.favorite,
              color: MyCatholicDayApp.gold,
            ),
            const SizedBox(height: 12),
            Text(
              "Today's Invitation",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reach out to one person who may need encouragement today.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: MyCatholicDayApp.gold,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: MyCatholicDayApp.navy,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}