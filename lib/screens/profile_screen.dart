import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ────────────────────────────────────
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppTheme.bgCard,
                  child: const Icon(Icons.person, size: 52, color: AppTheme.accent),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Twój profil', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Uzupełnij dane, aby śledzić postępy',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),

            // ── Dane użytkownika ──────────────────────────
            _SectionHeader('Dane osobowe'),
            const SizedBox(height: 10),
            _InfoTile(icon: Icons.person_outline, label: 'Imię i nazwisko', value: 'Nie ustawiono'),
            _InfoTile(icon: Icons.cake_outlined, label: 'Wiek', value: 'Nie ustawiono'),
            _InfoTile(icon: Icons.height, label: 'Wzrost', value: 'Nie ustawiono'),
            _InfoTile(icon: Icons.monitor_weight_outlined, label: 'Waga', value: 'Nie ustawiono'),
            const SizedBox(height: 24),

            // ── Cel treningowy ────────────────────────────
            _SectionHeader('Cel treningowy'),
            const SizedBox(height: 10),
            _GoalSelector(),
            const SizedBox(height: 24),

            // ── Ustawienia ────────────────────────────────
            _SectionHeader('Ustawienia'),
            const SizedBox(height: 10),
            _SettingsTile(icon: Icons.notifications_outlined, label: 'Powiadomienia', onTap: () {}),
            _SettingsTile(icon: Icons.color_lens_outlined, label: 'Motyw', onTap: () {}),
            _SettingsTile(icon: Icons.language, label: 'Język', onTap: () {}),
            _SettingsTile(icon: Icons.info_outline, label: 'O aplikacji', onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.accent)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Text(value, style: const TextStyle(color: AppTheme.textSecond)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppTheme.textSecond, size: 18),
        ],
      ),
    );
  }
}

class _GoalSelector extends StatefulWidget {
  @override
  State<_GoalSelector> createState() => _GoalSelectorState();
}

class _GoalSelectorState extends State<_GoalSelector> {
  int _selected = 0;
  final List<(String, IconData)> _goals = [
    ('Budowa masy', Icons.trending_up),
    ('Redukcja', Icons.local_fire_department),
    ('Siła', Icons.fitness_center),
    ('Kondycja', Icons.directions_run),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: List.generate(_goals.length, (i) => GestureDetector(
        onTap: () => setState(() => _selected = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _selected == i ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selected == i ? AppTheme.accent : Colors.white10,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_goals[i].$2,
                  color: _selected == i ? AppTheme.accent : AppTheme.textSecond, size: 18),
              const SizedBox(width: 8),
              Text(_goals[i].$1,
                  style: TextStyle(
                    color: _selected == i ? AppTheme.accent : AppTheme.textSecond,
                    fontWeight: _selected == i ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      )),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecond, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            const Icon(Icons.chevron_right, color: AppTheme.textSecond, size: 18),
          ],
        ),
      ),
    );
  }
}
