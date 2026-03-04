import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/workout_service.dart';
import 'services/profile_service.dart';
import 'services/plan_service.dart';
import 'screens/home_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/exercises_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Inicjalizacja serwisów ────────────────────────────
  await Future.wait([
    WorkoutService.instance.init(),
    ProfileService.instance.init(),
    PlanService.instance.init(),
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const GymFlowApp());
}

class GymFlowApp extends StatelessWidget {
  const GymFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
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
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    WorkoutScreen(),
    ExercisesScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined,      activeIcon: Icons.home,              label: 'Główna'),
    _NavItem(icon: Icons.fitness_center,     activeIcon: Icons.fitness_center,    label: 'Treningi'),
    _NavItem(icon: Icons.grid_view_rounded,  activeIcon: Icons.grid_view_rounded, label: 'Ćwiczenia'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart,         label: 'Postępy'),
    _NavItem(icon: Icons.person_outline,     activeIcon: Icons.person,            label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: _navItems.map((item) => BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
