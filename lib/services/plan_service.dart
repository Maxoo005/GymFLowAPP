import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';

class PlanService {
  static const _plansKey = 'workout_plans';
  static const _memoryKey = 'plan_exercise_memory'; // ciężar + serie per ćwiczenie w planie
  static PlanService? _instance;
  static PlanService get instance => _instance ??= PlanService._();
  PlanService._();

  List<WorkoutPlan> _plans = [];
  List<WorkoutPlan> get plans => List.unmodifiable(_plans);

  /// Pamięć ostatniego treningu: planId → exerciseId → lista SetEntry
  /// Zapamiętujemy TYLKO dla ćwiczeń oryginalnych z planu (jeśli użytkownik zmienił
  /// ćwiczenie na zamienne, nie pamiętamy go).
  Map<String, Map<String, List<SetEntry>>> _memory = {};

  // ── Inicjalizacja ───────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Plany
    final rawPlans = prefs.getString(_plansKey);
    if (rawPlans != null) {
      final List<dynamic> list = jsonDecode(rawPlans);
      _plans = list.map((e) => WorkoutPlan.fromJson(e)).toList();
      _plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Pamięć ciężarów
    final rawMem = prefs.getString(_memoryKey);
    if (rawMem != null) {
      final Map<String, dynamic> outer = jsonDecode(rawMem);
      _memory = outer.map((planId, innerDyn) {
        final inner = innerDyn as Map<String, dynamic>;
        return MapEntry(planId, inner.map((exId, entriesDyn) {
          final entries = (entriesDyn as List)
              .map((e) => SetEntry.fromJson(e))
              .toList();
          return MapEntry(exId, entries);
        }));
      });
    }
  }

  // ── Zapis ───────────────────────────────────────────────
  Future<void> _savePlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_plansKey, jsonEncode(_plans.map((p) => p.toJson()).toList()));
  }

  Future<void> _saveMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _memory.map((planId, inner) => MapEntry(planId,
        inner.map((exId, entries) =>
            MapEntry(exId, entries.map((e) => e.toJson()).toList()))));
    await prefs.setString(_memoryKey, jsonEncode(encoded));
  }

  // ── CRUD planów ─────────────────────────────────────────
  Future<void> addPlan(WorkoutPlan plan) async {
    _plans.insert(0, plan);
    await _savePlans();
  }

  Future<void> updatePlan(WorkoutPlan plan) async {
    final i = _plans.indexWhere((p) => p.id == plan.id);
    if (i != -1) {
      _plans[i] = plan;
      await _savePlans();
    }
  }

  Future<void> deletePlan(String id) async {
    _plans.removeWhere((p) => p.id == id);
    _memory.remove(id); // usuń też pamięć
    await Future.wait([_savePlans(), _saveMemory()]);
  }

  // ── Pamięć ciężarów / serii ─────────────────────────────

  /// Zwraca całą mapę exerciseId→entries dla danego planu (lub null).
  Map<String, List<SetEntry>>? getMemoryForPlan(String planId) =>
      _memory[planId];

  /// Zwraca zapamiętane serie dla danego ćwiczenia w planie.
  List<SetEntry>? getMemory(String planId, String exerciseId) {
    return _memory[planId]?[exerciseId];
  }

  /// Zapisuje serie po zakończeniu treningu.
  /// Wywołaj tylko dla ćwiczeń ORYGINALNYCH z planu (nie zamienionych).
  Future<void> saveMemory(
      String planId, String exerciseId, List<SetEntry> entries) async {
    _memory.putIfAbsent(planId, () => {});
    _memory[planId]![exerciseId] = entries;
    await _saveMemory();
  }
}
