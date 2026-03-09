import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';

/// Ekran szczegółów ukończonego treningu – podgląd co było robione
class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final d = workout.date;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final timeStr =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('$dateStr  $timeStr',
                    style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // ── Podsumowanie ───────────────────────────────
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(children: [
            _SummaryChip(
              icon: Icons.fitness_center,
              label: 'Ćwiczenia',
              value: '${workout.exercises.length}',
              color: AppTheme.accent,
            ),
            _SummaryChip(
              icon: Icons.repeat,
              label: 'Serie',
              value: '${workout.totalSets}',
              color: const Color(0xFF42A5F5),
            ),
            _SummaryChip(
              icon: Icons.timer_outlined,
              label: 'Czas',
              value: '${workout.durationMinutes} min',
              color: const Color(0xFFFF9800),
            ),
            if (workout.totalVolume > 0)
              _SummaryChip(
                icon: Icons.bar_chart,
                label: 'Objętość',
                value: '${workout.totalVolume.toStringAsFixed(0)} kg',
                color: AppTheme.success,
              ),
          ]),
        ),

        // ── Lista ćwiczeń ──────────────────────────────
        Expanded(
          child: workout.exercises.isEmpty
              ? const Center(
                  child: Text('Brak ćwiczeń w tym treningu',
                      style: TextStyle(color: AppTheme.textSecond)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: workout.exercises.length,
                  itemBuilder: (ctx, i) =>
                      _ExerciseDetailCard(workoutSet: workout.exercises[i], index: i),
                ),
        ),
      ]),
    );
  }
}

// ── Chip statystyki ──────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _SummaryChip(
      {required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label,
              style: const TextStyle(color: AppTheme.textSecond, fontSize: 10)),
        ]),
      );
}

// ── Karta ćwiczenia z listą serii ────────────────────────────
class _ExerciseDetailCard extends StatelessWidget {
  final WorkoutSet workoutSet;
  final int index;
  const _ExerciseDetailCard({required this.workoutSet, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Nagłówek
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(workoutSet.exerciseName,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${workoutSet.entries.length} serii',
                  style: const TextStyle(color: AppTheme.textSecond, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 10),

          // Nagłówek tabeli
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [
              SizedBox(width: 28,
                  child: Text('Seria', style: TextStyle(color: AppTheme.textSecond, fontSize: 10))),
              Expanded(flex: 2,
                  child: Text('Powtórzenia', style: TextStyle(color: AppTheme.textSecond, fontSize: 10), textAlign: TextAlign.center)),
              Expanded(flex: 2,
                  child: Text('Ciężar', style: TextStyle(color: AppTheme.textSecond, fontSize: 10), textAlign: TextAlign.center)),
              Expanded(flex: 3,
                  child: Text('Trudność', style: TextStyle(color: AppTheme.textSecond, fontSize: 10), textAlign: TextAlign.center)),
            ]),
          ),
          const SizedBox(height: 4),

          // Wiersze serii
          ...workoutSet.entries.asMap().entries.map((e) =>
              _SetDetailRow(number: e.key + 1, entry: e.value)),
        ]),
      ),
    );
  }
}

// ── Wiersz serii (read-only) ─────────────────────────────────
class _SetDetailRow extends StatelessWidget {
  final int number;
  final SetEntry entry;
  const _SetDetailRow({required this.number, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.subtleOverlay(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Text('$number',
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        Expanded(
          flex: 2,
          child: Text('${entry.reps} powt.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 2,
          child: Text(
            entry.weight == 0
                ? '– kg'
                : (entry.weight == entry.weight.roundToDouble()
                    ? '${entry.weight.toInt()} kg'
                    : '${entry.weight} kg'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final level = i + 1;
              final filled = level <= entry.difficulty;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? _diffColor(entry.difficulty) : AppTheme.border(context),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }

  Color _diffColor(int v) {
    if (v <= 2) return const Color(0xFF4CAF50);
    if (v == 3) return const Color(0xFFFF9800);
    return AppTheme.accent;
  }
}
