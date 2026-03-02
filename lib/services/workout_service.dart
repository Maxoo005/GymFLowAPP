import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';

class WorkoutService {
  static const _key = 'workouts';
  static WorkoutService? _instance;
  static WorkoutService get instance => _instance ??= WorkoutService._();
  WorkoutService._();

  List<Workout> _workouts = [];
  List<Workout> get workouts => List.unmodifiable(_workouts);

  // ── Inicjalizacja ────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final List<dynamic> list = jsonDecode(raw);
      _workouts = list.map((e) => Workout.fromJson(e)).toList();
      _workouts.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_workouts.map((w) => w.toJson()).toList()));
  }

  // ── CRUD ─────────────────────────────────────────────
  Future<void> addWorkout(Workout w) async {
    _workouts.insert(0, w);
    await _save();
  }

  Future<void> updateWorkout(Workout w) async {
    final i = _workouts.indexWhere((x) => x.id == w.id);
    if (i != -1) {
      _workouts[i] = w;
      await _save();
    }
  }

  Future<void> deleteWorkout(String id) async {
    _workouts.removeWhere((w) => w.id == id);
    await _save();
  }

  Workout? getById(String id) {
    try {
      return _workouts.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Statystyki ────────────────────────────────────────
  /// Treningi w ostatnich [days] dniach
  List<Workout> recentWorkouts(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _workouts.where((w) => w.date.isAfter(cutoff)).toList();
  }

  /// Liczba treningów w tym miesiącu
  int get monthlyCount {
    final now = DateTime.now();
    return _workouts
        .where((w) => w.date.year == now.year && w.date.month == now.month)
        .length;
  }

  /// Łączny czas treningów w tym miesiącu (minuty)
  int get monthlyDuration {
    final now = DateTime.now();
    return _workouts
        .where((w) => w.date.year == now.year && w.date.month == now.month)
        .fold(0, (sum, w) => sum + w.durationMinutes);
  }

  /// Łączna objętość treningów w tym miesiącu (kg)
  double get monthlyVolume {
    final now = DateTime.now();
    return _workouts
        .where((w) => w.date.year == now.year && w.date.month == now.month)
        .fold(0.0, (sum, w) => sum + w.totalVolume);
  }

  /// Liczba treningów per dzień tygodnia (0=pn, 6=nd) w ostatnich 7 dniach
  List<int> get weeklyActivity {
    final counts = List<int>.filled(7, 0);
    for (var w in recentWorkouts(7)) {
      // weekday: 1=pn .. 7=nd → index 0..6
      final idx = w.date.weekday - 1;
      counts[idx]++;
    }
    return counts;
  }

  /// Rekordy osobiste – max ciężar na ćwiczenie
  Map<String, double> get personalRecords {
    final Map<String, double> records = {};
    for (var w in _workouts) {
      for (var s in w.exercises) {
        final current = records[s.exerciseName] ?? 0;
        if (s.weight > current) records[s.exerciseName] = s.weight;
      }
    }
    return records;
  }
}
