import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import '../services/exercise_database_service.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<Exercise> _exercises = [];
  MuscleGroup? _selectedGroup;
  String _searchQuery = '';
  bool _loading = true;

  List<Exercise> get _filtered {
    return _exercises.where((e) {
      final matchGroup = _selectedGroup == null || e.muscleGroup == _selectedGroup;
      final matchSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchGroup && matchSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ExerciseDatabaseService.instance.getAllExercises();
    if (!mounted) return;
    setState(() {
      _exercises = list;
      _loading = false;
    });
  }

  // ── Dialogi ────────────────────────────────────────────

  Future<void> _showAddEditDialog({Exercise? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    MuscleGroup selectedGroup = existing?.muscleGroup ?? MuscleGroup.chest;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.modalBg(context),
          title: Text(existing == null ? 'Nowe ćwiczenie' : 'Edytuj ćwiczenie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa ćwiczenia',
                    hintText: 'np. Wyciskanie hantli',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Partia ciała', style: TextStyle(color: AppTheme.textSecond, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: MuscleGroup.values.map((g) {
                    final isSelected = selectedGroup == g;
                    return GestureDetector(
                      onTap: () => setS(() => selectedGroup = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accent : AppTheme.cardBg(ctx),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.accent : AppTheme.border(ctx),
                          ),
                        ),
                        child: Text(
                          g.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecond,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Opis (opcjonalnie)',
                    hintText: 'Technika, wskazówki...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(existing == null ? 'Dodaj' : 'Zapisz'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      final db = ExerciseDatabaseService.instance;
      if (existing == null) {
        // Dodaj nowe
        final ex = Exercise(
          name: nameCtrl.text.trim(),
          muscleGroup: selectedGroup,
          description: descCtrl.text.trim(),
        );
        await db.addExercise(ex);
      } else {
        // Edytuj
        final updated = Exercise(
          id: existing.id,
          name: nameCtrl.text.trim(),
          muscleGroup: selectedGroup,
          description: descCtrl.text.trim(),
          imageUrl: existing.imageUrl,
        );
        await db.updateExercise(updated);
      }
      await _load();
    }
  }

  Future<void> _deleteExercise(Exercise ex) async {
    final isCustom = await ExerciseDatabaseService.instance.isCustom(ex.id);
    if (!mounted) return;

    if (!isCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie można usunąć domyślnych ćwiczeń')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.modalBg(context),
        title: const Text('Usuń ćwiczenie'),
        content: Text('Czy na pewno usunąć "${ex.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ExerciseDatabaseService.instance.deleteExercise(ex.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Baza ćwiczeń')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj ćwiczenie'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                      _FilterChip(
                        label: 'Wszystkie',
                        selected: _selectedGroup == null,
                        onTap: () => setState(() => _selectedGroup = null),
                      ),
                      ...MuscleGroup.values.map((g) => _FilterChip(
                            label: g.displayName,
                            selected: _selectedGroup == g,
                            onTap: () => setState(() =>
                                _selectedGroup = _selectedGroup == g ? null : g),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ── Lista ćwiczeń ────────────────────────────────
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fitness_center, color: AppTheme.textSecond, size: 48),
                              const SizedBox(height: 12),
                              Text('Brak ćwiczeń',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _ExerciseItem(
                            exercise: _filtered[i],
                            onEdit: () => _showAddEditDialog(existing: _filtered[i]),
                            onDelete: () => _deleteExercise(_filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Chip filtra ──────────────────────────────────────────

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
          color: selected ? AppTheme.accent : AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.accent : AppTheme.border(context)),
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

// ── Kafelek ćwiczenia ────────────────────────────────────

class _ExerciseItem extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ExerciseItem({required this.exercise, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fitness_center, color: AppTheme.accent, size: 20),
        ),
        title: Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(exercise.muscleGroup.displayName,
            style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecond),
          color: AppTheme.modalBg(context),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'detail', child: Text('Szczegóły')),
            const PopupMenuItem(value: 'edit', child: Text('Edytuj')),
            PopupMenuItem(
              value: 'delete',
              child: Text('Usuń', style: TextStyle(color: Colors.red.shade400)),
            ),
          ],
          onSelected: (v) {
            if (v == 'detail') _showDetail(context);
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
        ),
        onTap: () => _showDetail(context),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.modalBg(context),
        title: Text(exercise.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(exercise.muscleGroup.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: AppTheme.accent,
            ),
            const SizedBox(height: 12),
            Text(
              exercise.description.isEmpty ? 'Brak opisu.' : exercise.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zamknij')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            child: const Text('Edytuj'),
          ),
        ],
      ),
    );
  }
}
