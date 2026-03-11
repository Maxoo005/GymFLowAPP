import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nutrition_profile.dart';

class NutritionService {
  NutritionService._();
  static final instance = NutritionService._();

  static const _key = 'nutrition_profile';

  NutritionProfile _profile = NutritionProfile();
  NutritionProfile get profile => _profile;

  // ── Inicjalizacja ─────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _profile = NutritionProfile.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
  }

  Future<void> save(NutritionProfile p) async {
    _profile = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(p.toJson()));
  }

  // ── Główne obliczenia ─────────────────────────────────────────

  /// [weightKg] – waga, [heightCm] – wzrost, [age] – wiek,
  /// [goal] – 'bulk' | 'cut' | 'strength' | 'cardio'
  /// [weeklyVolumeKg] – suma objętości z ostatnich 4 tygodni / 4 (śr. tyg.)
  NutritionResult calculate({
    required NutritionProfile nutritionProfile,
    required double weightKg,
    required double heightCm,
    required int age,
    required String goal,
    double weeklyVolumeKg = 0,
  }) {
    // ── BMR ──────────────────────────────────────────────────────
    final bmr = nutritionProfile.sex == 'male'
        ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
        : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;

    // ── PAL (mnożnik aktywności) ──────────────────────────────────
    double pal = _pal(nutritionProfile.activityLevel);

    // Drobna korekta na podstawie objętości treningowej (kg/tydzień)
    // Każde 1000 kg dodatkowej objętości tygodniowej → +0.05 PAL (maks. +0.2)
    final volumeBonus = (weeklyVolumeKg / 1000 * 0.05).clamp(0.0, 0.2);
    pal += volumeBonus;

    final tdee = bmr * pal;

    // ── Korekta celu ──────────────────────────────────────────────
    final targetCal = (tdee + _goalOffset(goal)).round();

    // ── Makroskładniki ────────────────────────────────────────────
    final splits = _macroSplit(goal);
    final protein = ((targetCal * splits[0]) / 4).round(); // 4 kcal/g
    final carbs   = ((targetCal * splits[1]) / 4).round(); // 4 kcal/g
    final fat     = ((targetCal * splits[2]) / 9).round(); // 9 kcal/g

    return NutritionResult(
      calories: targetCal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      bmr: bmr,
      tdee: tdee,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  double _pal(String level) {
    switch (level) {
      case 'sedentary':  return 1.2;
      case 'light':      return 1.375;
      case 'active':     return 1.725;
      case 'veryActive': return 1.9;
      case 'moderate':
      default:           return 1.55;
    }
  }

  int _goalOffset(String goal) {
    switch (goal) {
      case 'bulk':     return 350;
      case 'cut':      return -400;
      case 'strength': return 150;
      case 'cardio':   return -100;
      default:         return 0;
    }
  }

  /// [protein%, carbs%, fat%]
  List<double> _macroSplit(String goal) {
    switch (goal) {
      case 'bulk':     return [0.30, 0.45, 0.25];
      case 'cut':      return [0.40, 0.30, 0.30];
      case 'strength': return [0.35, 0.40, 0.25];
      case 'cardio':   return [0.30, 0.45, 0.25];
      default:         return [0.30, 0.40, 0.30];
    }
  }

  // ── Opisy UI ──────────────────────────────────────────────────
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
