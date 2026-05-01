import 'package:flutter/material.dart';
import 'src/models/user_profile.dart';
import 'src/services/database_service.dart';
import 'src/ui/screens/setup_screen.dart';
import 'src/ui/screens/home_screen.dart';
import 'src/ui/screens/history_screen.dart';
import 'src/ui/screens/profile_screen.dart';

void main() {
  runApp(const BalancaApp());
}

class BalancaApp extends StatelessWidget {
  const BalancaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balança',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1117),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const AppRoot(),
    );
  }
}

// ── App root: profile check → setup or main ──────────────────────────────────

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DatabaseService.getProfile().then((p) {
      setState(() {
        _profile = p;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_profile == null) {
      return SetupScreen(
        onSaved: (p) => setState(() => _profile = p),
      );
    }
    return MainShell(
      profile: _profile!,
      onProfileChanged: (p) => setState(() => _profile = p),
    );
  }
}

// ── Main shell with bottom nav ───────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileChanged;
  const MainShell(
      {super.key, required this.profile, required this.onProfileChanged});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _historyKey = 0; // increments on each visit to force reload

  void _onTabSelected(int i) {
    if (i == 1 && _index != 1) _historyKey++;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(profile: widget.profile),
          HistoryScreen(key: ValueKey(_historyKey)),
          ProfileScreen(
            profile: widget.profile,
            onSaved: widget.onProfileChanged,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
        backgroundColor: const Color(0xFF161B27),
        indicatorColor: Colors.teal.withValues(alpha: 0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Peso',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
