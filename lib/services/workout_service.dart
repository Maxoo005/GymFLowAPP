import 'dart:convert';
import 'package:flutter/material.dart';
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

  /// Liczba treningów per dzień tygodnia (0=pn, 6=nd) w bieżącym tygodniu (pon–nd)
  List<int> get weeklyActivity {
    final now = DateTime.now();
    // Poniedziałek bieżącego tygodnia o godz. 00:00
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final counts = List<int>.filled(7, 0);
    for (var w in _workouts) {
      if (!w.date.isBefore(weekStart)) {
        final idx = w.date.weekday - 1; // 0=pn..6=nd
        counts[idx]++;
      }
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

  /// Statystyki per partia ciała – liczba ćwiczeń i serii
  /// Zwraca: { 'Klatka piersiowa': {'exercises': 5, 'sets': 15}, ... }
  Map<String, Map<String, int>> get muscleGroupStats {
    final Map<String, Map<String, int>> stats = {};
    for (var w in _workouts) {
      for (var ws in w.exercises) {
        final groupName = ws.muscleGroupName;
        if (groupName == null || groupName.isEmpty) continue;
        final entry = stats.putIfAbsent(groupName, () => {'exercises': 0, 'sets': 0});
        entry['exercises'] = (entry['exercises'] ?? 0) + 1;
        entry['sets'] = (entry['sets'] ?? 0) + ws.sets;
      }
    }
    return stats;
  }

  // ── Metody z filtrem zakresu ──────────────────────────────

  /// Granica czasowa dla danego zakresu
  DateTime _rangeCutoff(int rangeIndex) {
    final now = DateTime.now();
    switch (rangeIndex) {
      case 0: // Tydzień – poniedziałek bieżącego tygodnia
        return DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
      case 1: // Miesiąc – 1. dzień bieżącego miesiąca
        return DateTime(now.year, now.month, 1);
      case 2: // 3 miesiące
        final m = now.month - 3;
        return DateTime(now.year + (m <= 0 ? -1 : 0), m <= 0 ? m + 12 : m, 1);
      case 3: // Rok – 1. stycznia bieżącego roku
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
    }
  }

  /// Treningi w wybranym zakresie
  List<Workout> workoutsInRange(int rangeIndex) {
    final cutoff = _rangeCutoff(rangeIndex);
    return _workouts.where((w) => !w.date.isBefore(cutoff)).toList();
  }

  /// Liczba treningów w zakresie
  int countInRange(int rangeIndex) => workoutsInRange(rangeIndex).length;

  /// Łączny czas treningów w zakresie (minuty)
  int durationInRange(int rangeIndex) =>
      workoutsInRange(rangeIndex).fold(0, (sum, w) => sum + w.durationMinutes);

  /// Łączna objętość w zakresie (kg)
  double volumeInRange(int rangeIndex) =>
      workoutsInRange(rangeIndex).fold(0.0, (sum, w) => sum + w.totalVolume);

  /// Dane do wykresu aktywności w zależności od zakresu:
  /// 0=7 dni (pn-nd), 1=dni miesiąca, 2=tygodnie (ok. 13), 3=12 miesięcy
  List<int> activityData(int rangeIndex) {
    final now = DateTime.now();
    final filtered = workoutsInRange(rangeIndex);

    switch (rangeIndex) {
      case 0: // Tydzień — 7 dni (pn=0 .. nd=6)
        final counts = List<int>.filled(7, 0);
        for (final w in filtered) {
          counts[w.date.weekday - 1]++;
        }
        return counts;

      case 1: // Miesiąc — dni miesiąca
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
        final counts = List<int>.filled(daysInMonth, 0);
        for (final w in filtered) {
          if (w.date.year == now.year && w.date.month == now.month) {
            counts[w.date.day - 1]++;
          }
        }
        return counts;

      case 2: // 3 miesiące — 13 tygodni
        final cutoff = _rangeCutoff(2);
        final counts = List<int>.filled(13, 0);
        for (final w in filtered) {
          final diff = w.date.difference(cutoff).inDays;
          final week = (diff / 7).floor().clamp(0, 12);
          counts[week]++;
        }
        return counts;

      case 3: // Rok — 12 miesięcy (sty=0 .. gru=11)
        final counts = List<int>.filled(12, 0);
        for (final w in filtered) {
          if (w.date.year == now.year) {
            counts[w.date.month - 1]++;
          }
        }
        return counts;

      default:
        return weeklyActivity;
    }
  }

  /// Statystyki partii ciała w wybranym zakresie
  Map<String, Map<String, int>> muscleGroupStatsInRange(int rangeIndex) {
    final filtered = workoutsInRange(rangeIndex);
    final Map<String, Map<String, int>> stats = {};
    for (var w in filtered) {
      for (var ws in w.exercises) {
        final groupName = ws.muscleGroupName;
        if (groupName == null || groupName.isEmpty) continue;
        final entry = stats.putIfAbsent(groupName, () => {'exercises': 0, 'sets': 0});
        entry['exercises'] = (entry['exercises'] ?? 0) + 1;
        entry['sets'] = (entry['sets'] ?? 0) + ws.sets;
      }
    }
    return stats;
  }
}
