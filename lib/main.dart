import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  runApp(const OneNationFaithApp());
}

class OneNationFaithApp extends StatelessWidget {
  const OneNationFaithApp({super.key});

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
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    Future<void>.delayed(
      const Duration(milliseconds: 2500),
      () {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) =>
                const MainShell(),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE2D4),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/onf_logo.png',
                width: 560,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
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

  final GlobalKey<_TodayPageState> _todayPageKey =
      GlobalKey<_TodayPageState>();

  late final List<Widget> _pages;

  static const List<String> _titles = [
    'One Nation Faith',
    'Pray',
    'Learn',
    'Live',
    'My Church',
  ];

  @override
  void initState() {
    super.initState();

    _pages = [
      TodayPage(key: _todayPageKey),
      const PrayScreen(),
      const PlaceholderPage(
        icon: Icons.menu_book_outlined,
        title: 'Learn',
        message: 'Catholic teachings and guides will be built here.',
      ),
      const PlaceholderPage(
        icon: Icons.favorite_outline,
        title: 'Live',
        message: 'Daily Catholic living resources will be built here.',
      ),
      const PlaceholderPage(
        icon: Icons.church_outlined,
        title: 'My Church',
        message: 'Your parish and diocesan information will be built here.',
      ),
    ];
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const NameSettingsPage(),
      ),
    );

    await _todayPageKey.currentState?.reloadName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.person_outline),
          ),
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

  String? _displayName;
  bool _nameDialogScheduled = false;
  bool _nameDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _dayFuture = _service.getToday();
    _loadName(promptIfMissing: true);
  }

  Future<void> reloadName() async {
    await _loadName();
  }

  Future<void> _loadName({
    bool promptIfMissing = false,
  }) async {
    final String? savedName = await _UserNameStore.loadName();
    final bool hasPrompted = await _UserNameStore.hasPrompted();

    if (!mounted) {
      return;
    }

    setState(() {
      _displayName = savedName;
    });

    if (promptIfMissing &&
        !hasPrompted &&
        !_nameDialogScheduled &&
        !_nameDialogOpen) {
      _nameDialogScheduled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _showFirstRunNameDialog();
      });
    }
  }

  Future<void> _showFirstRunNameDialog() async {
    if (_nameDialogOpen) {
      return;
    }

    _nameDialogOpen = true;

    final TextEditingController controller =
        TextEditingController(text: _displayName ?? '');

    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Welcome to One Nation Faith'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What should we call you?',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  Navigator.pop(
                    dialogContext,
                    value.trim(),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Your name is saved only on this device.',
                style: Theme.of(dialogContext)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, '');
              },
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    _nameDialogOpen = false;
    _nameDialogScheduled = false;

    if (result == null || result.trim().isEmpty) {
      await _UserNameStore.skipName();
    } else {
      await _UserNameStore.saveName(result);
    }

    await reloadName();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String greeting = _greetingForHour(now.hour);
    final String date = _formattedDate(now);
    final String greetingText = _displayName == null
        ? 'Welcome'
        : '$greeting, $_displayName';

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

          final CatholicDay catholicDay = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            children: [
              Text(
                greetingText,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      color: OneNationFaithApp.navy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                date,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                catholicDay.celebration,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                      color: OneNationFaithApp.burgundy,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${catholicDay.seasonName} • '
                '${catholicDay.colorName} • '
                '${catholicDay.rosaryMysteriesName}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              if (catholicDay.isHolyDayOfObligation) ...[
                const SizedBox(height: 6),
                Text(
                  'Holy Day of Obligation',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: OneNationFaithApp.burgundy,
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
                    MaterialPageRoute<void>(
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
    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  static String _formattedDate(DateTime date) {
    const List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const List<String> months = [
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

class NameSettingsPage extends StatefulWidget {
  const NameSettingsPage({super.key});

  @override
  State<NameSettingsPage> createState() =>
      _NameSettingsPageState();
}

class _NameSettingsPageState extends State<NameSettingsPage> {
  final TextEditingController _controller =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final String? savedName = await _UserNameStore.loadName();

    if (!mounted) {
      return;
    }

    _controller.text = savedName ?? '';

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveName() async {
    final String name = _controller.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a name, or choose “Use Welcome instead.”',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await _UserNameStore.saveName(name);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _removeName() async {
    setState(() {
      _isSaving = true;
    });

    await _UserNameStore.skipName();

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Personal greeting',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: OneNationFaithApp.navy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose the name One Nation Faith uses on the Today screen.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _saveName(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveName,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Name'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _isSaving ? null : _removeName,
                  child: const Text('Use Welcome instead'),
                ),
                const SizedBox(height: 18),
                Text(
                  'This name is stored only on this device.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),
    );
  }
}

class _UserNameStore {
  static const String _nameKey = 'user_display_name';
  static const String _promptedKey =
      'user_display_name_prompted';

  static Future<String?> loadName() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final String? savedName =
        preferences.getString(_nameKey)?.trim();

    if (savedName == null || savedName.isEmpty) {
      return null;
    }

    return savedName;
  }

  static Future<bool> hasPrompted() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    return preferences.getBool(_promptedKey) ?? false;
  }

  static Future<void> saveName(String name) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _nameKey,
      name.trim(),
    );

    await preferences.setBool(
      _promptedKey,
      true,
    );
  }

  static Future<void> skipName() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(_nameKey);

    await preferences.setBool(
      _promptedKey,
      true,
    );
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
            OneNationFaithApp.navy,
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
    color: OneNationFaithApp.gold,
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
                    color: OneNationFaithApp.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: OneNationFaithApp.navy,
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
                              color: OneNationFaithApp.navy,
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
                              color: OneNationFaithApp.burgundy,
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
      color: OneNationFaithApp.burgundy,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.favorite,
              color: OneNationFaithApp.gold,
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
              color: OneNationFaithApp.gold,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: OneNationFaithApp.navy,
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






