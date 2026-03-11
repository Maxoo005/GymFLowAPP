import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/workout_service.dart';
import '../services/plan_service.dart';
import '../services/exercise_database_service.dart';
import 'active_workout_screen.dart';
import 'workout_detail_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Workout> get _workouts => WorkoutService.instance.workouts;
  List<WorkoutPlan> get _plans => PlanService.instance.plans;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treningi'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
            tooltip: 'Nowy trening',
            onPressed: _showStartOptions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: AppTheme.textSecond,
          tabs: const [
            Tab(text: 'Historia'),
            Tab(text: 'Plany'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HistoryTab(
            workouts: _workouts,
            onAdd: _showStartOptions,
            onDelete: (id) async {
              await WorkoutService.instance.deleteWorkout(id);
              if (mounted) setState(() {});
            },
          ),
          _PlansTab(
            plans: _plans,
            onAddPlan: _showCreatePlanDialog,
            onStartPlan: _startWorkoutFromPlan,
            onEditPlan: (plan) => _showCreatePlanDialog(existing: plan),
            onDeletePlan: (id) async {
              await PlanService.instance.deletePlan(id);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // ── Opcje startu ────────────────────────────────────────
  void _showStartOptions() {
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
                decoration: BoxDecoration(color: AppTheme.border(ctx), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Nowy trening', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 20),
            _OptionTile(
              icon: Icons.flash_on,
              title: 'Trening swobodny',
              subtitle: 'Zacznij bez planu, dodawaj ćwiczenia na bieżąco',
              onTap: () { Navigator.pop(ctx); _showFreeWorkoutDialog(); },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.list_alt,
              title: 'Z planu treningowego',
              subtitle: 'Wybierz gotowy plan i zacznij trening',
              onTap: () { Navigator.pop(ctx); _showPickPlanDialog(); },
            ),
          ]),
        ),
      ),
    );
  }

  void _showFreeWorkoutDialog() {
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.modalBg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Swobodny trening', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl, autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nazwa treningu', hintText: 'np. Klatka + triceps'),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              // BUG FIX: użyj domyślnej nazwy gdy pole jest puste
              final name = nameCtrl.text.trim().isEmpty
                  ? 'Trening swobodny'
                  : nameCtrl.text.trim();
              Navigator.pop(ctx);
              _startWorkout(name, []);
            },
            child: const Text('Rozpocznij trening'),
          )),
        ]),
      ),
    );
  }

  void _showPickPlanDialog() {
    if (_plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak planów – najpierw utwórz plan!')),
      );
      _tabController.animateTo(1);
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
              decoration: BoxDecoration(color: AppTheme.border(ctx), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Wybierz plan', style: Theme.of(ctx).textTheme.titleLarge)),
          const SizedBox(height: 8),
          Expanded(child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _plans.length,
            itemBuilder: (_, i) {
              final plan = _plans[i];
              return ListTile(
                title: Text(plan.name),
                subtitle: Text('${plan.exercises.length} ćwiczeń',
                    style: const TextStyle(color: AppTheme.textSecond, fontSize: 12)),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startWorkoutFromPlan(plan);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Start'),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }

  Future<void> _startWorkout(String name, List<WorkoutSet> sets, {String? planId}) async {
    final workout = Workout(name: name, exercises: sets);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(workout: workout, planId: planId),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _startWorkoutFromPlan(WorkoutPlan plan) async {
    // Załaduj zapamiętane ciężary/serie z poprzedniego treningu
    final memory = PlanService.instance.getMemoryForPlan(plan.id);
    final sets = plan.toWorkoutSets(memory: memory);
    await _startWorkout(plan.name, sets, planId: plan.id);
  }

  // ── Tworzenie / edycja planu ──────────────────────────
  void _showCreatePlanDialog({WorkoutPlan? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlanScreen(existingPlan: existing),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// Historia treningów
// ═══════════════════════════════════════════════════════════════

class _HistoryTab extends StatelessWidget {
  final List<Workout> workouts;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  const _HistoryTab({required this.workouts, required this.onAdd, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.fitness_center, size: 72, color: AppTheme.textSecond),
        const SizedBox(height: 16),
        Text('Brak historii treningów', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Zacznij swój pierwszy trening!', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Nowy trening')),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workouts.length,
      itemBuilder: (ctx, i) => _WorkoutHistoryCard(
        workout: workouts[i],
        onDelete: () => onDelete(workouts[i].id),
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workout: workouts[i]),
          ),
        ),
      ),
    );
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _WorkoutHistoryCard({required this.workout, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = workout.date;
    final dateStr = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return Dismissible(
      key: Key(workout.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade900, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                ],
              ])),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Plany treningowe
// ═══════════════════════════════════════════════════════════════

class _PlansTab extends StatelessWidget {
  final List<WorkoutPlan> plans;
  final VoidCallback onAddPlan;
  final ValueChanged<WorkoutPlan> onStartPlan;
  final ValueChanged<WorkoutPlan> onEditPlan;
  final ValueChanged<String> onDeletePlan;
  const _PlansTab({required this.plans, required this.onAddPlan, required this.onStartPlan, required this.onEditPlan, required this.onDeletePlan});

  @override
  Widget build(BuildContext context) {
    return plans.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.calendar_today_outlined, size: 72, color: AppTheme.textSecond),
            const SizedBox(height: 16),
            Text('Brak planów treningowych', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Stwórz swój plan i ćwicz regularnie!', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: onAddPlan, icon: const Icon(Icons.add), label: const Text('Utwórz plan')),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length + 1,
            itemBuilder: (ctx, i) {
              if (i == plans.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: onAddPlan,
                    icon: const Icon(Icons.add),
                    label: const Text('Utwórz nowy plan'),
                    style: OutlinedButton.styleFrom(
                     foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              }
              return _PlanCard(
                plan: plans[i],
                onStart: () => onStartPlan(plans[i]),
                onEdit: () => onEditPlan(plans[i]),
                onDelete: () => onDeletePlan(plans[i].id),
              );
            },
          );
  }
}

class _PlanCard extends StatefulWidget {
  final WorkoutPlan plan;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PlanCard({required this.plan, required this.onStart, required this.onEdit, required this.onDelete});

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.plan.name, style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      Text('${widget.plan.exercises.length} ćwiczeń',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: AppTheme.textSecond,
                      ),
                    ],
                  ),
                ])),
                // Edytuj
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecond, size: 20),
                  tooltip: 'Edytuj plan',
                  onPressed: widget.onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.onStart,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Start'),
                ),
              ]),
              if (widget.plan.exercises.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 4, children: widget.plan.exercises.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                   color: AppTheme.subtleOverlay(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(e.exerciseName,
                      style: TextStyle(color: AppTheme.textSec(context), fontSize: 12)),
                )).toList()),
              ],
              if (_expanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Text('Objętość planu', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                _PlanVolumeChart(plan: widget.plan),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Podsumowanie objętości planu ──────────────────────────

class _PlanVolumeChart extends StatelessWidget {
  final WorkoutPlan plan;
  const _PlanVolumeChart({required this.plan});

  static const _colors = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF45B7D1),
    Color(0xFFF7DC6F), Color(0xFFBB8FCE), Color(0xFF82E0AA),
    Color(0xFFF0B27A), Color(0xFF85C1E9), Color(0xFFABEBC6),
    Color(0xFFD2B4DE),
  ];

  @override
  Widget build(BuildContext context) {
    if (plan.exercises.isEmpty) {
      return const Text('Brak ćwiczeń w planie.', style: TextStyle(color: AppTheme.textSecond));
    }

    // Map: muscleGroupName -> { 'sets': int, 'exercises': int }
    final Map<String, Map<String, int>> stats = {};
    for (final ex in plan.exercises) {
      final muscle = ex.muscleGroupName ?? 'Inne';
      stats.putIfAbsent(muscle, () => {'sets': 0, 'exercises': 0});
      stats[muscle]!['sets'] = stats[muscle]!['sets']! + ex.defaultSets;
      stats[muscle]!['exercises'] = stats[muscle]!['exercises']! + 1;
    }

    final entries = stats.entries.toList()
      ..sort((a, b) => b.value['sets']!.compareTo(a.value['sets']!));
    final maxSets = entries.isNotEmpty ? entries.first.value['sets']! : 1;
    
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _LegendDot(color: accent),
        const SizedBox(width: 6),
        const Text('Serie', style: TextStyle(color: AppTheme.textSecond, fontSize: 11)),
        const SizedBox(width: 16),
        const _LegendDot(color: Color(0xFF42A5F5)),
        const SizedBox(width: 6),
        const Text('Ćwiczenia', style: TextStyle(color: AppTheme.textSecond, fontSize: 11)),
      ]),
      const SizedBox(height: 12),
      ...entries.asMap().entries.map((mapEntry) {
        final idx = mapEntry.key;
        final name = mapEntry.value.key;
        final sets = mapEntry.value.value['sets']!;
        final exCount = mapEntry.value.value['exercises']!;
        final color = _colors[idx % _colors.length];
        final fraction = sets / (maxSets == 0 ? 1 : maxSets);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                child: Text(name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('$sets serii  |  $exCount ćw.',
                  style: const TextStyle(color: AppTheme.textSecond, fontSize: 11)),
            ]),
            const SizedBox(height: 4),
            Stack(children: [
              Container(
                height: 8, width: double.infinity,
                decoration: BoxDecoration(color: barBg, borderRadius: BorderRadius.circular(4)),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ]),
          ]),
        );
      }),
    ]);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ═══════════════════════════════════════════════════════════════
// Tworzenie planu
// ═══════════════════════════════════════════════════════════════

class CreatePlanScreen extends StatefulWidget {
  final WorkoutPlan? existingPlan;
  const CreatePlanScreen({super.key, this.existingPlan});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  late final TextEditingController _nameCtrl;
  late final List<PlanExercise> _exercises;

  bool get _isEditing => widget.existingPlan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.existingPlan;
    _nameCtrl = TextEditingController(text: plan?.name ?? '');
    _exercises = plan != null ? List.of(plan.exercises) : [];
  }

  Future<void> _addExercise() async {
    // Załaduj ćwiczenia z SQLite
    final allExercises = await ExerciseDatabaseService.instance.getAllExercises();
    if (!mounted) return;
    MuscleGroup? selected;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.modalBg(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setB) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (_, scroll) => Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.border(context), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Wybierz ćwiczenie', style: Theme.of(ctx).textTheme.titleLarge)),
            const SizedBox(height: 12),
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
            Expanded(child: ListView(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: allExercises
                  .where((e) => selected == null || e.muscleGroup == selected)
                  .map((e) => ListTile(
                title: Text(e.name),
                subtitle: Text(e.muscleGroup.displayName,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.primary, fontSize: 12)),
                trailing: Icon(Icons.add_circle, color: Theme.of(ctx).colorScheme.primary),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _exercises.add(PlanExercise(
                      exerciseId: e.id,
                      exerciseName: e.name,
                      muscleGroupName: e.muscleGroup.displayName,
                    ));
                  });
                },
              )).toList(),
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> _savePlan() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Podaj nazwę planu')));
      return;
    }
    if (_isEditing) {
      // Aktualizacja istniejącego planu
      final updated = WorkoutPlan(
        id: widget.existingPlan!.id,
        name: name,
        exercises: _exercises,
        createdAt: widget.existingPlan!.createdAt,
      );
      await PlanService.instance.updatePlan(updated);
    } else {
      // Nowy plan
      final plan = WorkoutPlan(name: name, exercises: _exercises);
      await PlanService.instance.addPlan(plan);
    }
    if (mounted) Navigator.pop(context);
  }

  /// Toggle serii łączonej między ćwiczeniem [i] a [i+1].
  /// Jeśli są już połączone → rozłącza. Jeśli nie → łączy wspólnym ID.
  void _toggleSuperset(int i) {
    if (i >= _exercises.length - 1) return;
    final current = _exercises[i];
    final next = _exercises[i + 1];
    final alreadyLinked = current.supersetGroupId != null &&
        current.supersetGroupId == next.supersetGroupId;

    if (alreadyLinked) {
      // Rozłącz: usuń ID z obu (i z całej grupy)
      final groupId = current.supersetGroupId;
      for (final ex in _exercises) {
        if (ex.supersetGroupId == groupId) {
          ex.supersetGroupId = null;
        }
      }
    } else {
      // Połącz: użyj istniejącego ID z [i] lub [i+1], albo wygeneruj nowe
      final groupId = current.supersetGroupId ??
          next.supersetGroupId ??
          generateSupersetGroupId();
      current.supersetGroupId = groupId;
      next.supersetGroupId = groupId;
    }
  }

  /// Czyści grupę supersetu gdy ćwiczenie na [removeIndex] jest usuwane.
  /// Jeśli po usunięciu zostanie tylko jeden członek grupy, usuwa mu też ID.
  void _cleanupSupersetGroup(String? groupId, {required int removeIndex}) {
    if (groupId == null) return;
    final remaining = _exercises
        .asMap()
        .entries
        .where((e) => e.key != removeIndex && e.value.supersetGroupId == groupId)
        .toList();
    if (remaining.length <= 1) {
      for (final e in remaining) {
        e.value.supersetGroupId = null;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edytuj plan' : 'Nowy plan'),
        actions: [
          TextButton(
            onPressed: _savePlan,
            child: Text('Zapisz', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nazwa planu',
              hintText: 'np. Push Day – klatka i ramiona',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
        ),
        Expanded(
          child: _exercises.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_circle_outline, size: 56, color: AppTheme.textSecond),
                  const SizedBox(height: 12),
                  Text('Dodaj ćwiczenia do planu',
                      style: Theme.of(context).textTheme.bodyMedium),
                ]))
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onReorder: (a, b) {
                    setState(() {
                      if (b > a) b--;
                      final item = _exercises.removeAt(a);
                      _exercises.insert(b, item);
                    });
                  },
                  itemCount: _exercises.length,
                  itemBuilder: (ctx, i) {
                    final ex = _exercises[i];
                    final isLast = i == _exercises.length - 1;
                    // Sprawdź czy następne ćwiczenie jest w tej samej grupie
                    final linkedWithNext = !isLast &&
                        ex.supersetGroupId != null &&
                        _exercises[i + 1].supersetGroupId == ex.supersetGroupId;

                    return Container(
                      key: Key(ex.exerciseId + i.toString()),
                      margin: const EdgeInsets.only(bottom: 0),
                      child: Column(
                        children: [
                          Card(
                            margin: EdgeInsets.only(
                              bottom: linkedWithNext ? 0 : 10,
                              top: (i > 0 && _exercises[i-1].supersetGroupId != null &&
                                    _exercises[i-1].supersetGroupId == ex.supersetGroupId) ? 0 : 0,
                            ),
                            shape: ex.isInSuperset
                                ? RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                  )
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Column(children: [
                                ListTile(
                                  leading: ReorderableDragStartListener(
                                    index: i,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(Icons.drag_handle, color: AppTheme.textSecond),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      if (ex.isInSuperset)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('🔗 Łączona',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              )),
                                        ),
                                      Expanded(child: Text(ex.exerciseName)),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.textSecond),
                                    onPressed: () => setState(() {
                                      // Jeśli był w supersecie i to jedyni członkowie – wyczyść grupę
                                      _cleanupSupersetGroup(ex.supersetGroupId, removeIndex: i);
                                      _exercises.removeAt(i);
                                    }),
                                  ),
                                ),
                                // ── Ustawienia docelowe (Serie, Powtórzenia, Ciężar) ──
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text('Serie', style: TextStyle(color: AppTheme.textSecond, fontSize: 11)),
                                          const SizedBox(height: 4),
                                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                            InkWell(
                                              onTap: () { if (ex.defaultSets > 1) setState(() => ex.defaultSets--); },
                                              child: Icon(Icons.remove, size: 18, color: Theme.of(context).colorScheme.primary),
                                            ),
                                            const SizedBox(width: 6),
                                            Text('${ex.defaultSets}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => setState(() => ex.defaultSets++),
                                              child: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.primary),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text('Powt.', style: TextStyle(color: AppTheme.textSecond, fontSize: 11)),
                                          const SizedBox(height: 4),
                                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                            InkWell(
                                              onTap: () { if (ex.defaultReps > 1) setState(() => ex.defaultReps--); },
                                              child: Icon(Icons.remove, size: 18, color: Theme.of(context).colorScheme.primary),
                                            ),
                                            const SizedBox(width: 6),
                                            Text('${ex.defaultReps}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => setState(() => ex.defaultReps++),
                                              child: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.primary),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text('Ciężar (kg)', style: TextStyle(color: AppTheme.textSecond, fontSize: 11)),
                                          SizedBox(
                                            height: 28,
                                            child: TextFormField(
                                              initialValue: ex.defaultWeight?.toString() ?? '',
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.only(bottom: 12),
                                                isDense: true,
                                                hintText: 'auto',
                                                border: UnderlineInputBorder(),
                                              ),
                                              onChanged: (val) {
                                                ex.defaultWeight = double.tryParse(val.replaceAll(',', '.'));
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(children: [
                                    const Icon(Icons.timer_outlined, size: 18, color: AppTheme.textSecond),
                                    const SizedBox(width: 8),
                                    const Text('Przerwa po serii:', style: TextStyle(color: AppTheme.textSecond, fontSize: 13)),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.primary),
                                      onPressed: () {
                                        if (ex.restSeconds > 10) {
                                          setState(() => ex.restSeconds -= 10);
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        ex.restSeconds >= 60
                                            ? '${ex.restSeconds ~/ 60}m ${ex.restSeconds % 60}s'
                                            : '${ex.restSeconds}s',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                                      onPressed: () => setState(() => ex.restSeconds += 10),
                                    ),
                                  ]),
                                ),
                                // ── Seria łączona toggle ──
                                if (!isLast)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => setState(() => _toggleSuperset(i)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: linkedWithNext
                                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                                              : Colors.white.withValues(alpha: 0.04),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: linkedWithNext
                                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                                                : Colors.white12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              linkedWithNext ? Icons.link : Icons.link_off,
                                              size: 16,
                                              color: linkedWithNext
                                                  ? Theme.of(context).colorScheme.primary
                                                  : AppTheme.textSecond,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              linkedWithNext
                                                  ? 'Seria łączona z następnym'
                                                  : 'Połącz w serię łączoną',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: linkedWithNext
                                                    ? Theme.of(context).colorScheme.primary
                                                    : AppTheme.textSecond,
                                                fontWeight: linkedWithNext
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ]),
                            ),
                          ),
                          // ── Linia łącznika między ćwiczeniami w supersecie ──
                          if (linkedWithNext)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              child: Row(
                                children: [
                                  Container(
                                    width: 2,
                                    height: 12,
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj ćwiczenie'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══ Helpers ══════════════════════════════════════════════════
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _OptionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ])),
        const Icon(Icons.chevron_right, color: AppTheme.textSecond),
      ]),
    ),
  );
}

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
        color: selected ? Theme.of(context).colorScheme.primary : AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecond,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13)),
    ),
  );
}
