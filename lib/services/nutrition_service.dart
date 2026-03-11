import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/nutrition_profile.dart';
import '../models/nutrition_result.dart';
import '../models/weight_entry.dart';
import '../models/food_log_entry.dart';
import '../models/activity_entry.dart';

import '../nutrition/bmr_calculator.dart';
import '../nutrition/activity_calculator.dart';
import '../nutrition/ewma_engine.dart';
import '../nutrition/macro_distributor.dart';
import '../nutrition/clinical_guard.dart';

/// === NutritionService ===
/// Singleton spinający wszystkie moduły silnika żywieniowego.
///
/// Architektura modułowa:
///   BmrCalculator   → BMR (Mifflin, Katch, U.S. Navy BF%)
///   ActivityCalculator → TDEE z modułowym EEE (MET)
///   EwmaEngine      → Wygładzanie masy ciała + adaptacyjne TDEE
///   MacroDistributor → Makroskładniki w g/kg (absolutne)
///   ClinicalGuard   → EA, RED-S detekcja, GLP-1 tryb
///
/// Persystencja (SharedPreferences):
///   'nutrition_profile'    → NutritionProfile (JSON)
///   'weight_entries'       → List<WeightEntry> (JSON array)
///   'food_log_entries'     → List<FoodLogEntry> (JSON array)
///   'activity_entries'     → List<ActivityEntry> (JSON array)
class NutritionService {
  NutritionService._();
  static final instance = NutritionService._();

  // ── Klucze persystencji ─────────────────────────────────────────────────
  static const _keyProfile    = 'nutrition_profile';
  static const _keyWeights    = 'weight_entries';
  static const _keyFoodLog    = 'food_log_entries';
  static const _keyActivities = 'activity_entries';

  // ── Stan w pamięci ─────────────────────────────────────────────────────
  NutritionProfile _profile = NutritionProfile();
  List<WeightEntry> _weightEntries   = [];
  List<FoodLogEntry> _foodLogEntries = [];
  List<ActivityEntry> _activityEntries = [];

  NutritionProfile get profile => _profile;
  List<WeightEntry> get weightEntries   => List.unmodifiable(_weightEntries);
  List<FoodLogEntry> get foodLogEntries => List.unmodifiable(_foodLogEntries);
  List<ActivityEntry> get activityEntries => List.unmodifiable(_activityEntries);

  // ── Inicjalizacja ─────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Profil
    final rawProfile = prefs.getString(_keyProfile);
    if (rawProfile != null) {
      try {
        _profile = NutritionProfile.fromJson(jsonDecode(rawProfile));
      } catch (_) {}
    }

    // Wpisy wagowe
    final rawWeights = prefs.getString(_keyWeights);
    if (rawWeights != null) {
      try {
        final list = jsonDecode(rawWeights) as List<dynamic>;
        _weightEntries = list
            .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Dziennik kalorii
    final rawFood = prefs.getString(_keyFoodLog);
    if (rawFood != null) {
      try {
        final list = jsonDecode(rawFood) as List<dynamic>;
        _foodLogEntries = list
            .map((e) => FoodLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Aktywności
    final rawActivities = prefs.getString(_keyActivities);
    if (rawActivities != null) {
      try {
        final list = jsonDecode(rawActivities) as List<dynamic>;
        _activityEntries = list
            .map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
  }

  // ── Zapisywanie profilu ───────────────────────────────────────────────
  Future<void> saveProfile(NutritionProfile p) async {
    _profile = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(p.toJson()));
  }

  // ── Dodawanie wpisów ─────────────────────────────────────────────────
  Future<void> addWeightEntry(WeightEntry entry) async {
    // Jeden wpis na dobę – nadpisujemy jeśli już istnieje
    final today = _dateOnly(entry.date);
    _weightEntries.removeWhere((e) => _dateOnly(e.date) == today);
    _weightEntries.add(entry);
    _weightEntries.sort((a, b) => a.date.compareTo(b.date));
    await _persistWeights();
  }

  Future<void> addFoodLogEntry(FoodLogEntry entry) async {
    _foodLogEntries.add(entry);
    await _persistFoodLog();
  }

  Future<void> addActivityEntry(ActivityEntry entry) async {
    _activityEntries.add(entry);
    await _persistActivities();
  }

  Future<void> clearWeightHistory() async {
    _weightEntries.clear();
    await _persistWeights();
  }

  // ── GŁÓWNE OBLICZENIA ─────────────────────────────────────────────────

  /// Uruchamia pełny potok obliczeniowy silnika żywieniowego.
  ///
  /// [activitiesToday] – sesje treningowe z bieżącego dnia (do EEE i EA)
  /// [eiTodayKcal]     – spożycie kalorii dziś (do obliczeń EA)
  /// [weightToday]     – dzisiejsza waga (jeśli dostępna, dla EA)
  NutritionResult? calculate({
    List<ActivityEntry>? activitiesToday,
    double? eiTodayKcal,
  }) {
    // Wymagane dane minimalne
    final w = _profile.weightKg;
    final h = _profile.heightCm;
    final a = _profile.age;
    if (w == null || h == null || a == null || w <= 0 || h <= 0 || a <= 0) {
      return null; // Brak minimalnych danych antropometrycznych
    }

    final isFemale = _profile.sex == 'female';
    final activities = activitiesToday ?? [];

    // ── Krok 1: BMR + skład ciała ─────────────────────────────────────
    final bmrResult = BmrCalculator.calculate(
      weightKg: w,
      heightCm: h,
      age: a,
      isFemale: isFemale,
      waistCm: _profile.waistCm,
      neckCm: _profile.neckCm,
      hipCm: _profile.hipCm,
      manualBodyFatPct: _profile.bodyFatPercent,
    );

    // ── Krok 2: TDEE szacowane (bazowe + EEE z treningu) ─────────────
    final eeeToday = ActivityCalculator.totalEeeFromEntries(
      activities: activities,
      weightKg: w,
    );
    final tdeeEstimated = activities.isEmpty
        ? ActivityCalculator.baseTdee(bmrResult.bmr)
        : ActivityCalculator.trainingDayTdee(
            bmr: bmrResult.bmr,
            activities: activities,
            weightKg: w,
          );

    // ── Krok 3: EWMA + adaptacyjne TDEE ──────────────────────────────
    final ewmaResult = EwmaEngine.calculate(
      weightEntries: _weightEntries,
      foodLogEntries: _foodLogEntries,
    );

    // Efektywne TDEE: adaptacyjne (jeśli dostępne) lub szacowane
    final effectiveTDEE = ewmaResult.adaptiveTDEE ?? tdeeEstimated;

    // ── Krok 4: Korekta celu treningowego ─────────────────────────────
    // GLP-1: pomiń adaptacyjne cięcie kalorii – lek i tak hamuje głód
    double targetKcal;
    if (_profile.isGlp1Mode) {
      // Nie ciniemy kalorii w trybie GLP-1 – utrzymanie
      targetKcal = tdeeEstimated;
    } else {
      targetKcal = effectiveTDEE + _goalOffset(_profile.goal);
    }
    // Wymuszamy minimum kliniczne (nie mniej niż 1000 kcal)
    targetKcal = targetKcal.clamp(1000.0, double.infinity);

    // ── Krok 5: Makroskładniki (absolutne g/kg) ───────────────────────
    final macroResult = MacroDistributor.calculate(
      targetKcal: targetKcal,
      weightKg: w,
      lbmKg: bmrResult.lbmKg,
      bodyFatPct: bmrResult.bodyFatPct,
      isGlp1Mode: _profile.isGlp1Mode,
    );

    // ── Krok 6: Kliniczny moduł ochronny ─────────────────────────────
    // EA i RED-S (tylko jeśli mamy dzisiejsze dane)
    final todayEa = (eiTodayKcal != null)
        ? ClinicalGuard.calculateEa(
            eiKcal: eiTodayKcal,
            eeeKcal: eeeToday,
            ffmKg: bmrResult.lbmKg,
          )
        : null;

    final clinicalAlert = ClinicalGuard.detectReds(
      foodLogEntries: _foodLogEntries,
      activityEntries: _activityEntries,
      ffmKg: bmrResult.lbmKg,
      weightKg: w,
      maintenanceTDEE: effectiveTDEE,
    );

    // Diet Break protocol: jeśli alert → nadpisz targetKcal do maintenance
    final finalTargetKcal = clinicalAlert != null
        ? effectiveTDEE // Diet Break = utrzymanie
        : targetKcal;

    // ── Krok 7: Mikroskładniki (tylko tryb GLP-1) ─────────────────────
    final micros = _profile.isGlp1Mode
        ? ClinicalGuard.glp1Micros(isFemale: isFemale)
        : null;

    return NutritionResult(
      bmr: bmrResult.bmr,
      tdeeEstimated: tdeeEstimated,
      tdeeAdaptive: ewmaResult.adaptiveTDEE,
      targetKcal: finalTargetKcal,
      lbmKg: bmrResult.lbmKg,
      bodyFatPercent: bmrResult.bodyFatPct,
      smoothedWeightKg: ewmaResult.smoothedWeight,
      macros: macroResult.macros,
      micros: micros,
      alert: clinicalAlert,
      energyAvailability: todayEa,
      coldStartActive: ewmaResult.coldStartActive,
      glp1Mode: _profile.isGlp1Mode,
    );
  }

  // ── Korekta kalorii wg celu ───────────────────────────────────────────
  double _goalOffset(String goal) {
    switch (goal) {
      case 'bulk':     return 350.0;
      case 'cut':      return -400.0;
      case 'strength': return 150.0;
      case 'cardio':   return -100.0;
      default:         return 0.0;
    }
  }

  // ── Persystencja ─────────────────────────────────────────────────────
  Future<void> _persistWeights() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyWeights,
      jsonEncode(_weightEntries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistFoodLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFoodLog,
      jsonEncode(_foodLogEntries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyActivities,
      jsonEncode(_activityEntries.map((e) => e.toJson()).toList()),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────
  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  // ── Opisy UI (zachowane dla kompatybilności wstecznej) ───────────────
  static String activityLabel(String level) {
    const map = {
      'sedentary':  'Siedzący tryb życia',
      'light':      'Lekka aktywność (1-2×/tydz.)',
      'moderate':   'Umiarkowana (3-4×/tydz.)',
      'active':     'Aktywna (5×/tydz.)',
      'veryActive': 'Bardzo aktywna (codziennie)',
    };
    return map[level] ?? level;
  }

  static String goalLabel(String goal) {
    const map = {
      'bulk':     'Budowanie masy',
      'cut':      'Redukcja',
      'strength': 'Siła',
      'cardio':   'Kondycja',
    };
    return map[goal] ?? goal;
  }
}
