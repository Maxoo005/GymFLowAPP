import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/workout_service.dart';
import '../services/profile_service.dart';
import '../models/workout.dart';
import 'active_workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WorkoutService get _ws => WorkoutService.instance;
  ProfileService get _ps => ProfileService.instance;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = _ps.profile;
    final greeting = profile.name.isNotEmpty ? 'Cześć, ${profile.name.split(' ').first}! 💪' : 'Witaj, sportowcu! 💪';

    final lastWorkout = _ws.workouts.isNotEmpty ? _ws.workouts.first : null;
    final weekly = _ws.weeklyActivity;
    final todayIdx = DateTime.now().weekday - 1;
    final trainedToday = weekly[todayIdx] > 0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Powitanie ────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greeting, style: textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppTheme.accent, Color(0xFFFF8A65)],
                    ).createShader(b),
                    child: Text('GymFlow',
                      style: textTheme.displayMedium?.copyWith(fontSize: 28, color: Colors.white)),
                  ),
                ]),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.bgCard,
                  child: profile.name.isNotEmpty
                    ? Text(profile.name[0].toUpperCase(),
                        style: const TextStyle(color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.bold))
                    : const Icon(Icons.person, color: AppTheme.accent, size: 28),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Status dnia ─────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: trainedToday
                        ? [const Color(0xFF1B4332), const Color(0xFF0D2818)]
                        : [AppTheme.accentSecond, const Color(0xFF16213E)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(trainedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: trainedToday ? AppTheme.success : AppTheme.accent, size: 32),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(trainedToday ? 'Dzisiaj ćwiczyłeś! 🔥' : 'Brak treningu dzisiaj',
                      style: textTheme.titleMedium),
                    Text(trainedToday ? 'Świetna robota, tak trzymaj!'
                        : 'Czas na trening – możesz to zrobić!',
                      style: textTheme.bodyMedium),
                  ])),
                  if (!trainedToday)
                    TextButton(
                      onPressed: () => _quickStart(context),
                      child: const Text('Start', style: TextStyle(color: AppTheme.accent)),
                    ),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Statystyki miesiąca ──────────────────
              Text('Ten miesiąc', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _StatCard(icon: Icons.fitness_center, label: 'Treningi',
                    value: '${_ws.monthlyCount}', color: AppTheme.accent)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.timer_outlined, label: 'Czas',
                    value: '${_ws.monthlyDuration} min', color: const Color(0xFF42A5F5))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.bar_chart, label: 'Objętość',
                    value: '${_ws.monthlyVolume.toStringAsFixed(0)} kg', color: AppTheme.success)),
              ]),
              const SizedBox(height: 24),

              // ── Aktywność tygodnia ───────────────────
              Text('Aktywność tygodnia', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              _WeekBar(weekly: weekly),
              const SizedBox(height: 24),

              // ── Ostatni trening ──────────────────────
              Text('Ostatni trening', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              lastWorkout != null
                  ? _LastWorkoutCard(workout: lastWorkout)
                  : _NoWorkoutCard(onStart: () => _quickStart(context)),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _quickStart(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Nowy trening'),
        content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(hintText: 'Nazwa treningu...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgCtx, ctrl.text.trim().isEmpty ? 'Trening' : ctrl.text.trim()),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (name != null && mounted) {
      final w = Workout(name: name);
      // ignore: use_build_context_synchronously
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(workout: w)),
      );
      if (result == true && mounted) setState(() {});
    }
  }
}

// ── Pomocnicze widgety ───────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.textSecond, fontSize: 11),
          textAlign: TextAlign.center),
    ]),
  );
}

class _WeekBar extends StatelessWidget {
  final List<int> weekly;
  const _WeekBar({required this.weekly});

  @override
  Widget build(BuildContext context) {
    const days = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
    final todayIdx = DateTime.now().weekday - 1;
    return Row(
      children: List.generate(7, (i) {
        final active = weekly[i] > 0;
        final isToday = i == todayIdx;
        return Expanded(child: Container(
          margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 36,
              decoration: BoxDecoration(
                color: active ? AppTheme.accent : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: isToday ? Border.all(color: AppTheme.accent, width: 1.5) : null,
              ),
              child: active ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(height: 4),
            Text(days[i], style: TextStyle(
              fontSize: 11,
              color: isToday ? AppTheme.accent : AppTheme.textSecond,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            )),
          ]),
        ));
      }),
    );
  }
}

class _LastWorkoutCard extends StatelessWidget {
  final Workout workout;
  const _LastWorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final d = workout.date;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.history, color: AppTheme.accent, size: 32),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(workout.name, style: Theme.of(context).textTheme.titleMedium),
          Text(
            '${d.day}.${d.month}.${d.year}  •  ${workout.exercises.length} ćw.  •  ${workout.durationMinutes} min',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (workout.totalVolume > 0)
            Text('Objętość: ${workout.totalVolume.toStringAsFixed(0)} kg',
                style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _NoWorkoutCard extends StatelessWidget {
  final VoidCallback onStart;
  const _NoWorkoutCard({required this.onStart});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      const Icon(Icons.history, color: AppTheme.textSecond, size: 32),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Brak treningów', style: Theme.of(context).textTheme.titleMedium),
        Text('Zacznij swój pierwszy trening!', style: Theme.of(context).textTheme.bodyMedium),
      ])),
      TextButton(onPressed: onStart, child: const Text('Start',
          style: TextStyle(color: AppTheme.accent))),
    ]),
  );
}
