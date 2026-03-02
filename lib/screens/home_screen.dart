import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Powitanie ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Witaj, sportowcu! 💪',
                          style: textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppTheme.accent, Color(0xFFFF8A65)],
                        ).createShader(bounds),
                        child: Text(
                          'GymFlow',
                          style: textTheme.displayMedium?.copyWith(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.bgCard,
                    child: const Icon(Icons.person, color: AppTheme.accent, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Dzisiejsza aktywność ───────────────────
              Text('Dzisiejsza aktywność', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              _StatsRow(),
              const SizedBox(height: 28),

              // ── Ostatni trening ────────────────────────
              Text('Ostatni trening', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              _LastWorkoutCard(),
              const SizedBox(height: 28),

              // ── Szybki start ───────────────────────────
              Text('Szybki start', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              _QuickStartGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.local_fire_department, label: 'Kalorie', value: '0 kcal', color: AppTheme.accent)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.timer_outlined, label: 'Czas', value: '0 min', color: const Color(0xFF42A5F5))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.fitness_center, label: 'Serie', value: '0', color: AppTheme.success)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _LastWorkoutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentSecond, Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppTheme.accent, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Brak zarejestrowanych treningów',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Zacznij swój pierwszy trening!',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStartGrid extends StatelessWidget {
  final List<_QuickItem> items = const [
    _QuickItem(icon: Icons.add_circle_outline, label: 'Nowy\ntrening', color: AppTheme.accent),
    _QuickItem(icon: Icons.fitness_center, label: 'Baza\nćwiczeń', color: Color(0xFF42A5F5)),
    _QuickItem(icon: Icons.bar_chart, label: 'Postępy', color: AppTheme.success),
    _QuickItem(icon: Icons.people_outline, label: 'Plany\ntreningowe', color: AppTheme.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items.map((item) => _QuickCard(item: item)).toList(),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickItem({required this.icon, required this.label, required this.color});
}

class _QuickCard extends StatelessWidget {
  final _QuickItem item;
  const _QuickCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 32),
            const SizedBox(height: 8),
            Text(item.label, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.2)),
          ],
        ),
      ),
    );
  }
}
