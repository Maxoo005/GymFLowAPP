import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Workout workout;
  const ActiveWorkoutScreen({super.key, required this.workout});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late Workout _workout;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Dodaj ćwiczenie ───────────────────────────────────
  void _pickExercise() {
    MuscleGroup? selected;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setB) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (_, scroll) => Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Wybierz ćwiczenie', style: Theme.of(ctx).textTheme.titleLarge)),
              const SizedBox(height: 12),
              // filtry
              SizedBox(height: 40,
                child: ListView(scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FChip('Wszystkie', selected == null, () => setB(() => selected = null)),
                    ...MuscleGroup.values.map((g) => _FChip(g.displayName, selected == g,
                        () => setB(() => selected = selected == g ? null : g))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: defaultExercises
                      .where((e) => selected == null || e.muscleGroup == selected)
                      .map((e) => ListTile(
                    title: Text(e.name),
                    subtitle: Text(e.muscleGroup.displayName,
                        style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
                    trailing: const Icon(Icons.add_circle, color: AppTheme.accent),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _workout.exercises.add(WorkoutSet(
                          exerciseId: e.id,
                          exerciseName: e.name,
                        ));
                      });
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Zakończ trening ───────────────────────────────────
  Future<void> _finishWorkout() async {
    _timer?.cancel();
    _workout.durationMinutes = (_seconds / 60).round();
    await WorkoutService.instance.addWorkout(_workout);
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_workout.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer, color: AppTheme.accent, size: 16),
                  const SizedBox(width: 4),
                  Text(_timeLabel, style: const TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _workout.exercises.isEmpty
                ? _EmptyExercises(onAdd: _pickExercise)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _workout.exercises.length,
                    itemBuilder: (ctx, i) => _ExerciseTile(
                      workoutSet: _workout.exercises[i],
                      index: i,
                      onDelete: () => setState(() => _workout.exercises.removeAt(i)),
                      onChanged: () => setState(() {}),
                    ),
                  ),
          ),
          // ── Dolny pasek ─────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj ćwiczenie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: const BorderSide(color: AppTheme.accent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _workout.exercises.isEmpty ? null : _finishWorkout,
                    icon: const Icon(Icons.check),
                    label: const Text('Zakończ'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: Colors.white10,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pomocnicze widgety ───────────────────────────────────

class _FChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.accent : Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
        style: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecond,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13)),
    ),
  );
}

class _EmptyExercises extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyExercises({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.add_circle_outline, size: 64, color: AppTheme.textSecond),
      const SizedBox(height: 12),
      Text('Brak ćwiczeń', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text('Dodaj pierwsze ćwiczenie do treningu', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Dodaj ćwiczenie')),
    ]),
  );
}

class _ExerciseTile extends StatelessWidget {
  final WorkoutSet workoutSet;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  const _ExerciseTile({required this.workoutSet, required this.index,
    required this.onDelete, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(workoutSet.exerciseName,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.textSecond, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
            ),
          ]),
          const SizedBox(height: 12),
          // Serie/powt/ciężar
          Row(children: [
            _CounterField(label: 'Serie', value: workoutSet.sets,
              onChanged: (v) { workoutSet.sets = v; onChanged(); }),
            const SizedBox(width: 12),
            _CounterField(label: 'Powt.', value: workoutSet.reps,
              onChanged: (v) { workoutSet.reps = v; onChanged(); }),
            const SizedBox(width: 12),
            _WeightField(value: workoutSet.weight,
              onChanged: (v) { workoutSet.weight = v; onChanged(); }),
          ]),
        ]),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _CounterField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecond, fontSize: 11)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: () { if (value > 1) onChanged(value - 1); },
              child: const Icon(Icons.remove, color: AppTheme.accent, size: 18),
            ),
            const SizedBox(width: 8),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onChanged(value + 1),
              child: const Icon(Icons.add, color: AppTheme.accent, size: 18),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _WeightField extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _WeightField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final ctrl = TextEditingController(text: value == 0 ? '' : value.toString());
          final result = await showDialog<double>(
            context: context,
            builder: (dlgCtx) => AlertDialog(
              backgroundColor: AppTheme.bgCard,
              title: const Text('Ciężar (kg)'),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0.0', suffixText: 'kg'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Anuluj')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dlgCtx, double.tryParse(ctrl.text) ?? value),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (result != null) onChanged(result);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            const Text('Ciężar', style: TextStyle(color: AppTheme.textSecond, fontSize: 11)),
            const SizedBox(height: 6),
            Text('${value == value.roundToDouble() ? value.toInt() : value} kg',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accent)),
          ]),
        ),
      ),
    );
  }
}
