import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import 'active_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<Workout> get _workouts => WorkoutService.instance.workouts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treningi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.accent),
            onPressed: _showAddWorkoutDialog,
          ),
        ],
      ),
      body: _workouts.isEmpty
          ? _EmptyWorkouts(onAdd: _showAddWorkoutDialog)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _workouts.length,
              itemBuilder: (ctx, i) => _WorkoutCard(
                workout: _workouts[i],
                onDelete: () async {
                  await WorkoutService.instance.deleteWorkout(_workouts[i].id);
                  if (mounted) setState(() {});
                },
              ),
            ),
    );
  }

  void _showAddWorkoutDialog() {
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nowy trening', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nazwa treningu',
                hintText: 'np. Klatka + triceps',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(ctx);
                    _startWorkout(name);
                  }
                },
                child: const Text('Rozpocznij trening'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startWorkout(String name) async {
    final workout = Workout(name: name);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(workout: workout)),
    );
    if (result == true && mounted) setState(() {});
  }
}

// ── Puste stany ──────────────────────────────────────────

class _EmptyWorkouts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyWorkouts({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.fitness_center, size: 72, color: AppTheme.textSecond),
      const SizedBox(height: 16),
      Text('Brak treningów', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text('Zacznij swój pierwszy trening!',
          style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Nowy trening'),
      ),
    ]),
  );
}

// ── Karta treningu ───────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onDelete;
  const _WorkoutCard({required this.workout, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final d = workout.date;
    final dateStr = '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';
    return Dismissible(
      key: Key(workout.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center, color: AppTheme.accent),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(workout.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '$dateStr  •  ${workout.exercises.length} ćw.  •  ${workout.durationMinutes} min',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (workout.totalVolume > 0) ...[
                const SizedBox(height: 2),
                Text('Objętość: ${workout.totalVolume.toStringAsFixed(0)} kg',
                    style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
              ],
            ])),
            const Icon(Icons.chevron_right, color: AppTheme.textSecond),
          ]),
        ),
      ),
    );
  }
}
