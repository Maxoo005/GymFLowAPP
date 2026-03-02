import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // Lista przykładowych treningów (docelowo z bazy danych)
  final List<Workout> _workouts = [];

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
              itemBuilder: (ctx, i) => _WorkoutCard(workout: _workouts[i]),
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
                hintText: 'np. Trening klatki – Poniedziałek',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    setState(() {
                      _workouts.insert(
                        0,
                        Workout(name: nameController.text.trim()),
                      );
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Utwórz trening'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkouts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyWorkouts({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 72, color: AppTheme.textSecond),
          const SizedBox(height: 16),
          Text('Brak treningów', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Dodaj swój pierwszy trening!', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Nowy trening'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center, color: AppTheme.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${workout.date.day}.${workout.date.month}.${workout.date.year}  •  ${workout.exercises.length} ćwiczeń',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecond),
          ],
        ),
      ),
    );
  }
}
