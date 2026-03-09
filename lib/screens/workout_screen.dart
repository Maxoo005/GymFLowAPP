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
            icon: const Icon(Icons.add, color: AppTheme.accent),
            tooltip: 'Nowy trening',
            onPressed: _showStartOptions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
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
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
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
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                _startWorkout(name, []);
              }
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
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
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
              const Icon(Icons.chevron_right, color: AppTheme.accent),
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
                      foregroundColor: AppTheme.accent,
                      side: const BorderSide(color: AppTheme.accent),
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

class _PlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PlanCard({required this.plan, required this.onStart, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today, color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
                Text('${plan.exercises.length} ćwiczeń',
                    style: Theme.of(context).textTheme.bodyMedium),
              ])),
              // Edytuj
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecond, size: 20),
                tooltip: 'Edytuj plan',
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Start'),
              ),
            ]),
            if (plan.exercises.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 4, children: plan.exercises.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(e.exerciseName,
                    style: const TextStyle(color: AppTheme.textSecond, fontSize: 12)),
              )).toList()),
            ],
          ]),
        ),
      ),
    );
  }
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
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
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
                    style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
                trailing: const Icon(Icons.add_circle, color: AppTheme.accent),
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
            child: const Text('Zapisz', style: TextStyle(color: AppTheme.accent)),
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
                    return Card(
                      key: Key(ex.exerciseId + i.toString()),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Column(children: [
                          ListTile(
                            leading: const Icon(Icons.drag_handle, color: AppTheme.textSecond),
                            title: Text(ex.exerciseName),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.textSecond),
                              onPressed: () => setState(() => _exercises.removeAt(i)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(children: [
                              const Icon(Icons.timer_outlined, size: 18, color: AppTheme.textSecond),
                              const SizedBox(width: 8),
                              const Text('Przerwa po serii:', style: TextStyle(color: AppTheme.textSecond, fontSize: 13)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.accent),
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
                                icon: const Icon(Icons.add_circle_outline, color: AppTheme.accent),
                                onPressed: () => setState(() => ex.restSeconds += 10),
                              ),
                            ]),
                          ),
                        ]),
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
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
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
            color: AppTheme.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.accent),
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
        color: selected ? AppTheme.accent : Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecond,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13)),
    ),
  );
}
