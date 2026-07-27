import 'package:flutter/material.dart';

void main() {
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: navy,
      secondary: burgundy,
      tertiary: gold,
      surface: cream,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Catholic Day',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: gold.withValues(alpha: 0.22),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? navy
                  : Colors.black54,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: burgundy,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
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
    PlaceholderPage(
      icon: Icons.volunteer_activism_outlined,
      title: 'Pray',
      message: 'Your prayer library will be built here.',
    ),
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
    'My Catholic Day',
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

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);
    final date = _formattedDate(now);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        children: [
          Text(
            '$greeting, Jeff',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: MyCatholicDayApp.navy,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ordinary Time',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: MyCatholicDayApp.burgundy,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 24),
          const DailyHeroCard(),
          const SizedBox(height: 18),
          const SectionCard(
            icon: Icons.auto_stories_outlined,
            title: "Today's Gospel",
            subtitle: 'Matthew 5:13–16',
            body:
                '"You are the light of the world. A city set on a mountain cannot be hidden."',
            buttonLabel: 'Read the Gospel',
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
          const SectionCard(
            icon: Icons.person_outline,
            title: 'Saint of the Day',
            subtitle: 'Saint of the day coming soon',
            body:
                'This section will introduce the life, witness, and prayer of today’s saint.',
            buttonLabel: 'Learn More',
          ),
          const SizedBox(height: 14),
          const InvitationCard(),
        ],
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final String buttonLabel;

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
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: MyCatholicDayApp.navy,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
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