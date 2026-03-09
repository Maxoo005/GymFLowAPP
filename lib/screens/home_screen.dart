import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/workout_service.dart';
import '../services/profile_service.dart';
import '../services/plan_service.dart';
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
    final accent = Theme.of(context).colorScheme.primary;
    final profile = _ps.profile;
    final greeting = profile.name.isNotEmpty
        ? 'Cześć, ${profile.name.split(' ').first}! 💪'
        : 'Witaj, sportowcu! 💪';

    final lastWorkout = _ws.workouts.isNotEmpty ? _ws.workouts.first : null;
    final weekly = _ws.weeklyActivity;
    final todayIdx = DateTime.now().weekday - 1;
    final trainedToday = weekly[todayIdx] > 0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: accent,
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
                    shaderCallback: (b) => LinearGradient(
                      colors: [accent, const Color(0xFFFF8A65)],
                    ).createShader(b),
                    child: Text('GymLoom',
                      style: textTheme.displayMedium?.copyWith(
                          fontSize: 28, color: Colors.white)),
                  ),
                ]),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.cardBg(context),
                  child: profile.name.isNotEmpty
                    ? Text(profile.name[0].toUpperCase(),
                        style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.bold))
                    : Icon(Icons.person, color: accent, size: 28),
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
                    color: trainedToday ? AppTheme.success : accent, size: 32),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(trainedToday ? 'Dzisiaj ćwiczyłeś! 🔥' : 'Brak treningu dzisiaj',
                      style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                    Text(trainedToday
                        ? 'Świetna robota – jeszcze jeden?'
                        : 'Czas na trening – możesz to zrobić!',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  ])),
                  TextButton(
                    onPressed: () => _quickStart(context),
                    child: Text(trainedToday ? 'Kolejny' : 'Start',
                        style: TextStyle(color: accent)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Statystyki miesiąca ──────────────────
              Text('Ten miesiąc', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _StatCard(icon: Icons.fitness_center, label: 'Treningi',
                    value: '${_ws.monthlyCount}', color: accent)),
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

  void _quickStart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.modalBg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.border(ctx),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Nowy trening', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 20),
            _HomeOptionTile(
              icon: Icons.flash_on,
              title: 'Trening swobodny',
              subtitle: 'Zacznij bez planu, dodawaj ćwiczenia na bieżąco',
              onTap: () { Navigator.pop(ctx); _startFree(); },
            ),
            const SizedBox(height: 12),
            _HomeOptionTile(
              icon: Icons.list_alt,
              title: 'Z planu treningowego',
              subtitle: 'Wybierz gotowy plan i zacznij trening',
              onTap: () { Navigator.pop(ctx); _startFromPlan(); },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _startFree() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppTheme.modalBg(context),
        title: const Text('Nowy trening'),
        content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(hintText: 'Nazwa treningu...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                dlgCtx, ctrl.text.trim().isEmpty ? 'Trening' : ctrl.text.trim()),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (name != null && mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(workout: Workout(name: name))),
      );
      if (result == true && mounted) setState(() {});
    }
  }

  void _startFromPlan() {
    final plans = PlanService.instance.plans;
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak planów – utwórz plan w zakładce Treningi!')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.modalBg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (_, scroll) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border(ctx),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Wybierz plan', style: Theme.of(ctx).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: plans.length,
              itemBuilder: (_, i) {
                final plan = plans[i];
                final accent = Theme.of(ctx).colorScheme.primary;
                return ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_today, color: accent, size: 18),
                  ),
                  title: Text(plan.name),
                  subtitle: Text('${plan.exercises.length} ćwiczeń',
                      style: TextStyle(color: AppTheme.textSec(ctx), fontSize: 12)),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final memory = PlanService.instance.getMemoryForPlan(plan.id);
                      final sets = plan.toWorkoutSets(memory: memory);
                      final workout = Workout(name: plan.name, exercises: sets);
                      final result = await Navigator.push<bool>(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActiveWorkoutScreen(
                              workout: workout, planId: plan.id),
                        ),
                      );
                      if (result == true && mounted) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    child: const Text('Start'),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Pomocnicze widgety ───────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _StatCard({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      color: AppTheme.cardBg(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border(context)),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: AppTheme.textSec(context), fontSize: 11),
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
    final accent = Theme.of(context).colorScheme.primary;
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
                color: active ? accent : AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(8),
                border: isToday ? Border.all(color: accent, width: 1.5)
                    : Border.all(color: AppTheme.border(context)),
              ),
              child: active
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(days[i], style: TextStyle(
              fontSize: 11,
              color: isToday ? accent : AppTheme.textSec(context),
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
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(children: [
        Icon(Icons.history, color: accent, size: 32),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(workout.name, style: Theme.of(context).textTheme.titleMedium),
          Text(
            '${d.day}.${d.month}.${d.year}  •  ${workout.exercises.length} ćw.  •  ${workout.durationMinutes} min',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (workout.totalVolume > 0)
            Text('Objętość: ${workout.totalVolume.toStringAsFixed(0)} kg',
                style: TextStyle(color: accent, fontSize: 12)),
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
      color: AppTheme.cardBg(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border(context)),
    ),
    child: Row(children: [
      Icon(Icons.history, color: AppTheme.textSec(context), size: 32),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Brak treningów', style: Theme.of(context).textTheme.titleMedium),
        Text('Zacznij swój pierwszy trening!', style: Theme.of(context).textTheme.bodyMedium),
      ])),
      TextButton(onPressed: onStart,
          child: Text('Start',
              style: TextStyle(color: Theme.of(context).colorScheme.primary))),
    ]),
  );
}

// ── Kafelek opcji startu ─────────────────────────────────
class _HomeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _HomeOptionTile({required this.icon, required this.title,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.subtleOverlay(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: AppTheme.textSec(context), fontSize: 12)),
          ])),
          Icon(Icons.chevron_right, color: AppTheme.textSec(context), size: 20),
        ]),
      ),
    );
  }
}
