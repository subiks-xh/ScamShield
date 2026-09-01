import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'models/analysis_result.dart';
import 'screens/home_screen.dart';
import 'screens/results_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/onboarding_screen.dart';

// Global state (simple approach for hackathon — use Riverpod in production)
AnalysisResult? currentResult;
late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AnalysisResultAdapter());
  Hive.registerAdapter(ProtectedContactAdapter());
  Hive.registerAdapter(AppPreferencesAdapter());
  await Hive.openBox<AnalysisResult>('history');
  await Hive.openBox<ProtectedContact>('contacts');
  await Hive.openBox<AppPreferences>('prefs');

  prefs = await SharedPreferences.getInstance();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ScamShieldApp());
}

class ScamShieldApp extends StatefulWidget {
  const ScamShieldApp({super.key});

  @override
  State<ScamShieldApp> createState() => _ScamShieldAppState();
}

class _ScamShieldAppState extends State<ScamShieldApp> {
  bool _simpleMode = false;
  bool _darkMode = true;

  void _updateTheme(bool simpleMode, bool darkMode) {
    setState(() {
      _simpleMode = simpleMode;
      _darkMode = darkMode;
    });
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child, onThemeChange: _updateTheme);
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/learn', builder: (_, __) => const LearnScreen()),
          GoRoute(path: '/settings', builder: (_, s) => SettingsScreen(onThemeChange: _updateTheme)),
        ],
      ),
      GoRoute(
        path: '/results',
        builder: (_, __) => const ResultsScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ScamShield',
      theme: _darkMode
          ? AppTheme.dark(simpleMode: _simpleMode)
          : AppTheme.light(simpleMode: _simpleMode),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Main shell with bottom navigation bar
class MainShell extends StatefulWidget {
  final Widget child;
  final Function(bool, bool)? onThemeChange;

  const MainShell({super.key, required this.child, this.onThemeChange});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _destinations = [
    ('/', '🛡️', 'Home'),
    ('/history', '📋', 'History'),
    ('/learn', '📚', 'Learn'),
    ('/settings', '⚙️', 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.royalNavy,
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: (index) {
            setState(() => _currentIndex = index);
            context.go(_destinations[index].$1);
          },
          items: _destinations
              .map((d) => BottomNavigationBarItem(
                    icon: Text(d.$2, style: const TextStyle(fontSize: 20)),
                    label: d.$3,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
