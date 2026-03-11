import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/plan_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Workout workout;
  /// Jeśli trening pochodzi z planu – jego ID (do zapisu pamięci ciężarów)
  final String? planId;
  const ActiveWorkoutScreen({super.key, required this.workout, this.planId});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late Workout _workout;
  Timer? _timer;
  int _seconds = 0;

  int _restSecondsRemaining = 0;
  Timer? _restTimer;

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

  void _startRestTimer(int seconds) {
    if (seconds <= 0) return;
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_restSecondsRemaining > 0) {
          _restSecondsRemaining--;
          if (_restSecondsRemaining == 0) {
            timer.cancel();
            if (SettingsService.instance.notificationsEnabled) {
              NotificationService.instance.showTimerFinishedNotification();
            }
          }
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _restTimeLabel {
    final m = _restSecondsRemaining ~/ 60;
    final s = _restSecondsRemaining % 60;
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  // ── Picker ćwiczeń (dodaj nowe) ───────────────────────
  void _pickExercise({int? replaceIndex}) {
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
              child: Text(
                replaceIndex != null ? 'Zamień ćwiczenie' : 'Wybierz ćwiczenie',
                style: Theme.of(ctx).textTheme.titleLarge,
              )),
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
            Expanded(child: ListView(controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: defaultExercises
                  .where((e) => selected == null || e.muscleGroup == selected)
                  // Wyklucz ćwiczenie które zamieniamy
                  .where((e) => replaceIndex == null ||
                      e.id != _workout.exercises[replaceIndex].exerciseId)
                  .map((e) => ListTile(
                title: Text(e.name),
                subtitle: Text(e.muscleGroup.displayName,
                    style: const TextStyle(color: AppTheme.accent, fontSize: 12)),
                trailing: Icon(
                  replaceIndex != null ? Icons.swap_horiz : Icons.add_circle,
                  color: AppTheme.accent,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    if (replaceIndex != null) {
                      // Zamień ćwiczenie – nowe NIE jest originalne z planu
                      // (planExerciseId = null) → nie będzie zapamiętane
                      final old = _workout.exercises[replaceIndex];
                      _workout.exercises[replaceIndex] = WorkoutSet(
                        exerciseId: e.id,
                        exerciseName: e.name,
                        planExerciseId: null, // zamienione → nie zapamiętuj
                        entries: [
                          // Przepisz liczbę serii z zastępowanego ćwiczenia
                          for (final s in old.entries)
                            SetEntry(reps: s.reps, weight: 0), // ciężar zresetuj
                        ],
                      );
                    } else {
                      _workout.exercises.add(WorkoutSet(
                        exerciseId: e.id,
                        exerciseName: e.name,
                      ));
                    }
                  });
                },
              )).toList(),
            )),
          ]),
        ),
      ),
    );
  }

  // ── Zakończ trening ───────────────────────────────────
  Future<void> _finishWorkout() async {
    _timer?.cancel();
    _workout.durationMinutes = (_seconds / 60).round();

    // Zapisz pamięć ciężarów dla ćwiczeń z planu
    final planId = widget.planId;
    if (planId != null) {
      for (final ex in _workout.exercises) {
        if (ex.isOriginalPlanExercise) {
          await PlanService.instance.saveMemory(planId, ex.exerciseId, ex.entries);
        }
      }
    }

    await WorkoutService.instance.addWorkout(_workout);
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.pop(context, true);
  }

  /// Toggle serii łączonej między ćwiczeniem [i] a [i+1].
  void _toggleSuperset(int i) {
    if (i >= _workout.exercises.length - 1) return;
    final current = _workout.exercises[i];
    final next = _workout.exercises[i + 1];
    final alreadyLinked = current.supersetGroupId != null &&
        current.supersetGroupId == next.supersetGroupId;

    if (alreadyLinked) {
      // Rozłącz
      final groupId = current.supersetGroupId;
      for (final ex in _workout.exercises) {
        if (ex.supersetGroupId == groupId) {
          ex.supersetGroupId = null;
        }
      }
    } else {
      // Połącz
      final groupId = current.supersetGroupId ??
          next.supersetGroupId ??
          generateSupersetGroupId();
      current.supersetGroupId = groupId;
      next.supersetGroupId = groupId;
    }
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
      body: Column(children: [
        Expanded(
          child: _workout.exercises.isEmpty
              ? _EmptyExercises(onAdd: () => _pickExercise())
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = _workout.exercises.removeAt(oldIndex);
                      _workout.exercises.insert(newIndex, item);
                    });
                  },
                  itemCount: _workout.exercises.length,
                  itemBuilder: (ctx, i) {
                    final ws = _workout.exercises[i];
                    final isLast = i == _workout.exercises.length - 1;
                    final linkedWithNext = !isLast &&
                        ws.supersetGroupId != null &&
                        _workout.exercises[i + 1].supersetGroupId == ws.supersetGroupId;
                    return Container(
                      key: ValueKey('${ws.exerciseId}_$i'),
                      child: Column(
                        children: [
                          _ExerciseCard(
                            index: i,
                            workoutSet: ws,
                            onDelete: () => setState(() => _workout.exercises.removeAt(i)),
                            onChanged: () => setState(() {}),
                            onSwap: () => _pickExercise(replaceIndex: i),
                            onStartRest: _startRestTimer,
                            canToggleSuperset: !isLast,
                            isLinkedWithNext: linkedWithNext,
                            onToggleSuperset: () => setState(() => _toggleSuperset(i)),
                          ),
                          if (linkedWithNext)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              child: Row(
                                children: [
                                  Container(
                                    width: 2,
                                    height: 12,
                                    color: AppTheme.accent.withValues(alpha: 0.5),
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
        // ── Pasek stopera przerwy ────────────────────────
        if (_restSecondsRemaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.accent.withValues(alpha: 0.15),
            child: Row(children: [
              const Icon(Icons.timer_outlined, color: AppTheme.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Przerwa: $_restTimeLabel',
                    style: const TextStyle(
                        color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.accent),
                onPressed: () {
                  _restTimer?.cancel();
                  setState(() => _restSecondsRemaining = 0);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
        // ── Dolny pasek ─────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickExercise(),
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
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Kafelek ćwiczenia z listą serii
// ═══════════════════════════════════════════════════════════════

class _ExerciseCard extends StatelessWidget {
  final int index;
  final WorkoutSet workoutSet;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final VoidCallback onSwap;
  final ValueChanged<int> onStartRest;
  final bool canToggleSuperset;
  final bool isLinkedWithNext;
  final VoidCallback onToggleSuperset;

  const _ExerciseCard({
    required this.index,
    required this.workoutSet,
    required this.onDelete,
    required this.onChanged,
    required this.onSwap,
    required this.onStartRest,
    this.canToggleSuperset = false,
    this.isLinkedWithNext = false,
    required this.onToggleSuperset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: isLinkedWithNext ? 0 : 14),
      shape: workoutSet.isInSuperset
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppTheme.accent.withValues(alpha: 0.6),
                width: 1.5,
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Nagłówek ćwiczenia ──────────────────────
          Row(children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: 6, top: 4, bottom: 4),
                child: Icon(Icons.drag_indicator, color: AppTheme.textSecond, size: 24),
              ),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fitness_center, color: AppTheme.accent, size: 18),
            ),
            const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (workoutSet.isInSuperset)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('🔗 Superseria',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    Text(
                      workoutSet.exerciseName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (workoutSet.isOriginalPlanExercise)
                      const Text(
                        'z planu',
                        style: TextStyle(color: AppTheme.textSecond, fontSize: 11),
                      ),
                  ],
                ),
              ),
            // Zamień ćwiczenie
            Tooltip(
              message: 'Podmień na inne ćwiczenie (zostawia serie)',
              child: IconButton(
                icon: const Icon(Icons.swap_horiz, color: AppTheme.accent, size: 20),
                onPressed: onSwap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            // Usuń ćwiczenie
            Tooltip(
              message: 'Usuń z tego treningu',
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.textSecond, size: 20),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // ── Nagłówki tabeli serii ──────────────────────
          if (workoutSet.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 28,
                    child: Text('Seria', style: TextStyle(color: AppTheme.textSecond, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Text('Powt.', style: TextStyle(color: AppTheme.textSecond, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 2,
                    child: Text('Ciężar', style: TextStyle(color: AppTheme.textSecond, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 4,
                    child: Text('Trudność (1-5)', style: TextStyle(color: AppTheme.textSecond, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  ),
                  const SizedBox(width: 14),
                  const SizedBox(
                    width: 28,
                    child: Text('Wyk.', style: TextStyle(color: AppTheme.textSecond, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  if (workoutSet.entries.length > 1) const SizedBox(width: 20),
                ],
              ),
            ),

          // ── Serie ────────────────────────────────────
          ...workoutSet.entries.asMap().entries.map((entry) {
            final idx = entry.key;
            final setEntry = entry.value;
            return _SetRow(
              seriesNumber: idx + 1,
              entry: setEntry,
              onDelete: workoutSet.entries.length > 1
                  ? () {
                      workoutSet.entries.removeAt(idx);
                      onChanged();
                    }
                  : null,
              onChanged: (updated) {
                final wasDone = workoutSet.entries[idx].isDone;
                workoutSet.entries[idx] = updated;
                if (!wasDone && updated.isDone) {
                  onStartRest(workoutSet.restSeconds);
                }
                onChanged();
              },
            );
          }),

          // ── Przycisk dodaj serię ─────────────────────
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final last = workoutSet.entries.isNotEmpty
                        ? workoutSet.entries.last
                        : SetEntry();
                    workoutSet.entries.add(SetEntry(
                      reps: last.reps,
                      weight: last.weight,
                      difficulty: last.difficulty,
                    ));
                    onChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add, color: AppTheme.accent, size: 16),
                      SizedBox(width: 6),
                      Text('Dodaj serię', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
              if (canToggleSuperset) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: isLinkedWithNext 
                      ? 'Rozłącz superserię' 
                      : 'Połącz to ćwiczenie z następnym w superserię (serię łączoną)',
                  child: GestureDetector(
                    onTap: onToggleSuperset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLinkedWithNext
                            ? AppTheme.accent.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLinkedWithNext
                              ? AppTheme.accent.withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          isLinkedWithNext ? Icons.link : Icons.link_off,
                          color: isLinkedWithNext ? AppTheme.accent : AppTheme.textSecond,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLinkedWithNext ? 'Superseria' : 'Superseria',
                          style: TextStyle(
                            color: isLinkedWithNext ? AppTheme.accent : AppTheme.textSecond,
                            fontSize: 12,
                            fontWeight: isLinkedWithNext ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Wiersz pojedynczej serii
// ═══════════════════════════════════════════════════════════════

class _SetRow extends StatelessWidget {
  final int seriesNumber;
  final SetEntry entry;
  final VoidCallback? onDelete;
  final ValueChanged<SetEntry> onChanged;

  const _SetRow({
    required this.seriesNumber,
    required this.entry,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        // Numer serii
        SizedBox(
          width: 28,
          child: Text(
            '$seriesNumber',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        // Powtórzenia
        _EditableValue(
          label: 'powt.',
          value: '${entry.reps}',
          onTap: () async {
            final result = await _showNumberDialog(
              context, 'Powtórzenia', entry.reps.toDouble(), false);
            if (result != null) onChanged(entry.copyWith(reps: result.toInt()));
          },
        ),
        const SizedBox(width: 8),
        // Ciężar
        _EditableValue(
          label: 'kg',
          value: entry.weight == 0
              ? '–'
              : (entry.weight == entry.weight.roundToDouble()
                  ? '${entry.weight.toInt()}'
                  : '${entry.weight}'),
          onTap: () async {
            final result = await _showNumberDialog(
              context, 'Ciężar (kg)', entry.weight, true);
            if (result != null) onChanged(entry.copyWith(weight: result));
          },
          accent: true,
        ),
        const SizedBox(width: 8),
        // Trudność
        Expanded(
          child: _DifficultyPicker(
            value: entry.difficulty,
            onChanged: (d) => onChanged(entry.copyWith(difficulty: d)),
          ),
        ),
        const SizedBox(width: 8),
        // Wykonane (Checkbox / Przycisk)
        Tooltip(
          message: entry.isDone ? 'Oznacz jako niewykonane' : 'Zakończ serię (uruchamia stoper)',
          child: GestureDetector(
            onTap: () => onChanged(entry.copyWith(isDone: !entry.isDone)),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: entry.isDone ? AppTheme.success : Colors.transparent,
                border: Border.all(color: entry.isDone ? AppTheme.success : AppTheme.textSecond.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: entry.isDone ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
            ),
          ),
        ),
        // Usuń serię
        if (onDelete != null) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: 'Usuń serię',
            child: GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 16, color: AppTheme.textSecond),
            ),
          ),
        ],
      ]),
    );
  }

  Future<double?> _showNumberDialog(
      BuildContext context, String title, double current, bool decimal) async {
    final ctrl = TextEditingController(
      text: current == 0 ? '' : (decimal ? current.toString() : current.toInt().toString()),
    );
    return showDialog<double>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppTheme.modalBg(context),
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgCtx, double.tryParse(ctrl.text) ?? current),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ══ Edytowalna wartość ════════════════════════════════════════
class _EditableValue extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  final bool accent;
  const _EditableValue({required this.label, required this.value, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent
              ? AppTheme.accent.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: accent ? AppTheme.accent : AppTheme.textPrimary,
          )),
          Text(label, style: const TextStyle(color: AppTheme.textSecond, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ══ Trudność – skala 1–5 ════════════════════════════════════════
class _DifficultyPicker extends StatelessWidget {
  final int value; // 1–5
  final ValueChanged<int> onChanged;
  const _DifficultyPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: List.generate(5, (i) {
        final level = i + 1;
        final filled = level <= value;
        return GestureDetector(
          onTap: () => onChanged(level),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? _diffColor(value) : Colors.white12,
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _diffColor(int v) {
    if (v <= 2) return const Color(0xFF4CAF50);
    if (v == 3) return const Color(0xFFFF9800);
    return AppTheme.accent;
  }
}

// ══ Pomocnicze ═════════════════════════════════════════════════

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
      Text('Dodaj pierwsze ćwiczenie do treningu',
          style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Dodaj ćwiczenie')),
    ]),
  );
}
