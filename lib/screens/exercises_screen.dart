import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  MuscleGroup? _selectedGroup;
  String _searchQuery = '';

  List<Exercise> get _filtered {
    return defaultExercises.where((e) {
      final matchGroup = _selectedGroup == null || e.muscleGroup == _selectedGroup;
      final matchSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchGroup && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Baza ćwiczeń')),
      body: Column(
        children: [
          // ── Szukaj ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Szukaj ćwiczenia...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecond),
              ),
            ),
          ),
          // ── Filtry grup mięśniowych ──────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(label: 'Wszystkie', selected: _selectedGroup == null,
                    onTap: () => setState(() => _selectedGroup = null)),
                ...MuscleGroup.values.map((g) => _FilterChip(
                  label: g.displayName,
                  selected: _selectedGroup == g,
                  onTap: () => setState(() => _selectedGroup = _selectedGroup == g ? null : g),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Lista ćwiczeń ────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) => _ExerciseItem(exercise: _filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.accent : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecond,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ExerciseItem extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseItem({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fitness_center, color: AppTheme.accent, size: 20),
        ),
        title: Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(exercise.muscleGroup.displayName,
            style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecond),
        onTap: () => _showDetail(context, exercise),
      ),
    );
  }

  void _showDetail(BuildContext context, Exercise ex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text(ex.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(ex.muscleGroup.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: AppTheme.accent,
            ),
            const SizedBox(height: 12),
            Text(ex.description.isEmpty ? 'Brak opisu.' : ex.description,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zamknij')),
        ],
      ),
    );
  }
}
