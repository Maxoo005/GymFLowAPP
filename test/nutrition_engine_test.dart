// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/models/weight_entry.dart';
import 'package:gymapp/models/food_log_entry.dart';
import 'package:gymapp/models/activity_entry.dart';
import 'package:gymapp/models/macro_targets.dart';
import 'package:gymapp/models/clinical_alert.dart';
import 'package:gymapp/nutrition/bmr_calculator.dart';
import 'package:gymapp/nutrition/activity_calculator.dart';
import 'package:gymapp/nutrition/ewma_engine.dart';
import 'package:gymapp/nutrition/macro_distributor.dart';
import 'package:gymapp/nutrition/clinical_guard.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════════════
  // BmrCalculator
  // ════════════════════════════════════════════════════════════════════════════
  group('BmrCalculator', () {
    test('Mifflin-St Jeor – mężczyzna', () {
      // 85 kg, 184 cm, 25 lat, mężczyzna
      // BMR = 10×85 + 6.25×184 − 5×25 + 5 = 850 + 1150 − 125 + 5 = 1880
      final bmr = BmrCalculator.mifflinStJeor(
        weightKg: 85, heightCm: 184, age: 25, isFemale: false,
      );
      expect(bmr, closeTo(1880, 1));
    });

    test('Mifflin-St Jeor – kobieta', () {
      // 60 kg, 165 cm, 30 lat, kobieta
      // BMR = 10×60 + 6.25×165 − 5×30 − 161 = 600 + 1031.25 − 150 − 161 = 1320.25
      final bmr = BmrCalculator.mifflinStJeor(
        weightKg: 60, heightCm: 165, age: 30, isFemale: true,
      );
      expect(bmr, closeTo(1320.25, 1));
    });

    test('Katch-McArdle – wynik', () {
      // 85 kg, BF% = 15% → LBM = 85 × 0.85 = 72.25 kg
      // BMR = 370 + 21.6 × 72.25 = 370 + 1560.6 = 1930.6
      final bmr = BmrCalculator.katchMcArdle(weightKg: 85, bodyFatPct: 15);
      expect(bmr, closeTo(1930.6, 1));
    });

    test('Uśrednianie Mifflin + Katch gdy znany BF%', () {
      // Przy BF% = 15% oba równania powinny być uśrednione
      final result = BmrCalculator.calculate(
        weightKg: 85, heightCm: 184, age: 25, isFemale: false,
        manualBodyFatPct: 15,
      );
      expect(result.usedAveraging, isTrue);
      // BMR musi być między Mifflin a Katch
      expect(result.bmr, greaterThan(result.bmrMifflin < result.bmrKatch!
          ? result.bmrMifflin : result.bmrKatch!));
      expect(result.bmr, lessThan(result.bmrMifflin > result.bmrKatch!
          ? result.bmrMifflin : result.bmrKatch!));
    });

    test('Bez BF% – brak uśredniania, używa tylko Mifflin', () {
      final result = BmrCalculator.calculate(
        weightKg: 70, heightCm: 175, age: 28, isFemale: false,
      );
      expect(result.usedAveraging, isFalse);
      expect(result.bmrKatch, isNull);
      expect(result.bmr, closeTo(result.bmrMifflin, 0.01));
    });

    test('US Navy BF% – mężczyzna', () {
      // Dane testowe z kalkulatora US Navy: talita=85cm, szyja=38cm, wzrost=184cm
      // Oczekiwane BF% ~ 16–18%
      final bf = BmrCalculator.usNavyBodyFat(
        waistCm: 85, neckCm: 38, heightCm: 184, isFemale: false,
      );
      expect(bf, isNotNull);
      expect(bf!, inInclusiveRange(10.0, 30.0));
    });

    test('US Navy BF% – talita <= szyja zwraca null', () {
      final bf = BmrCalculator.usNavyBodyFat(
        waistCm: 38, neckCm: 38, heightCm: 184, isFemale: false,
      );
      expect(bf, isNull);
    });

    test('US Navy BF% – kobiety bez bioder zwraca null', () {
      final bf = BmrCalculator.usNavyBodyFat(
        waistCm: 75, neckCm: 33, heightCm: 165, isFemale: true,
        // hipCm nie podane
      );
      expect(bf, isNull);
    });

    test('LBM obliczone poprawnie', () {
      final result = BmrCalculator.calculate(
        weightKg: 80, heightCm: 175, age: 30, isFemale: false,
        manualBodyFatPct: 20,
      );
      // LBM = 80 × (1 − 0.20) = 64.0 kg
      expect(result.lbmKg, closeTo(64.0, 0.01));
    });

    test('isObesityRange – BF% > 20% zwraca true', () {
      final result = BmrCalculator.calculate(
        weightKg: 100, heightCm: 175, age: 35, isFemale: false,
        manualBodyFatPct: 25,
      );
      expect(result.isObesityRange, isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // ActivityCalculator
  // ════════════════════════════════════════════════════════════════════════════
  group('ActivityCalculator', () {
    test('Wzór EEE: MET=5, 60 min, 85 kg', () {
      // EEE = 60 × (5 × 3.5 × 85) / 200 = 60 × 1487.5 / 200 = 446.25 kcal
      final eee = ActivityCalculator.calculateEee(
        met: 5.0, durationMin: 60, weightKg: 85,
      );
      expect(eee, closeTo(446.25, 0.01));
    });

    test('baseTDEE = BMR × 1.2', () {
      expect(ActivityCalculator.baseTdee(1880), closeTo(2256, 0.01));
    });

    test('totalEeeFromEntries – lista aktywności', () {
      final now = DateTime.now();
      final entries = [
        ActivityEntry(date: now, met: 5.0, durationMin: 60),  // 446.25
        ActivityEntry(date: now, met: 3.5, durationMin: 30),  // 3.5×3.5×85/200×30 = 156.1875
      ];
      final eee = ActivityCalculator.totalEeeFromEntries(
        activities: entries, weightKg: 85,
      );
      expect(eee, closeTo(446.25 + 156.1875, 0.5));
    });

    test('totalEeeFromEntries – pusta lista zwraca 0', () {
      final eee = ActivityCalculator.totalEeeFromEntries(
        activities: [], weightKg: 85,
      );
      expect(eee, 0.0);
    });

    test('getMet – znany klucz', () {
      expect(ActivityCalculator.getMet('strength_moderate'), 5.0);
      expect(ActivityCalculator.getMet('running_10kmh'), 10.0);
    });

    test('getMet – nieznany klucz zwraca domyślne 5.0', () {
      expect(ActivityCalculator.getMet('nieznana_aktywnosc'), 5.0);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // EwmaEngine
  // ════════════════════════════════════════════════════════════════════════════
  group('EwmaEngine', () {
    test('Brak wpisów → cold start, null values', () {
      final result = EwmaEngine.calculate(
        weightEntries: [], foodLogEntries: [],
      );
      expect(result.coldStartActive, isTrue);
      expect(result.smoothedWeight, isNull);
      expect(result.adaptiveTDEE, isNull);
    });

    test('< 14 wpisów → cold start aktywny', () {
      final base = DateTime(2026, 1, 1);
      final entries = List.generate(13, (i) => WeightEntry(
        date: base.add(Duration(days: i)),
        weightKg: 80.0,
      ));
      final result = EwmaEngine.calculate(
        weightEntries: entries, foodLogEntries: [],
      );
      expect(result.coldStartActive, isTrue);
      expect(result.weightEntryCount, 13);
      expect(result.coldStartDaysRemaining, 1);
    });

    test('>= 14 wpisów → wyjście z cold startu', () {
      final base = DateTime(2026, 1, 1);
      final entries = List.generate(14, (i) => WeightEntry(
        date: base.add(Duration(days: i)),
        weightKg: 80.0,
      ));
      final result = EwmaEngine.calculate(
        weightEntries: entries, foodLogEntries: [],
      );
      expect(result.coldStartActive, isFalse);
      expect(result.coldStartDaysRemaining, 0);
    });

    test('Wzór EWMA – wygładzanie stabilnej wagi', () {
      // Przy stałej wadze 80 kg, wygładzona wartość powinna pozostawać ~80 kg
      final base = DateTime(2026, 1, 1);
      final entries = List.generate(20, (i) => WeightEntry(
        date: base.add(Duration(days: i)),
        weightKg: 80.0,
      ));
      final result = EwmaEngine.calculate(
        weightEntries: entries, foodLogEntries: [],
      );
      expect(result.smoothedWeight, closeTo(80.0, 0.01));
    });

    test('EWMA – wygładzanie skoku wagi (spike reduction)', () {
      final base = DateTime(2026, 1, 1);
      // 14 dni po 80 kg, a potem skok do 90 kg (retencja wody)
      final entries = [
        ...List.generate(14, (i) => WeightEntry(
          date: base.add(Duration(days: i)),
          weightKg: 80.0,
        )),
        WeightEntry(date: base.add(const Duration(days: 14)), weightKg: 90.0),
      ];
      final result = EwmaEngine.calculate(
        weightEntries: entries, foodLogEntries: [],
      );
      // Wygładzona powinna być znacznie poniżej 90 (efekt wygładzania α=0.1)
      // S = 0.1 × 90 + 0.9 × 80 = 9 + 72 = 81
      expect(result.smoothedWeight, closeTo(81.0, 0.5));
    });

    test('Obsługa brakujących dni – forward-fill', () {
      // 2 wpisy z przerwą 5 dni – historia powinna zawierać 6 dni
      final base = DateTime(2026, 1, 1);
      final entries = [
        WeightEntry(date: base, weightKg: 80.0),
        WeightEntry(date: base.add(const Duration(days: 5)), weightKg: 80.0),
      ];
      final result = EwmaEngine.calculate(
        weightEntries: entries, foodLogEntries: [],
      );
      // 2 dni własne + 4 forward-fill = 6 wpisów w historii
      expect(result.dayCount, 6);
      expect(result.weightEntryCount, 2);
    });

    test('Adaptacyjne TDEE – obliczanie po cold starcie ze spożyciem', () {
      // 14 dni stałe 80 kg, spożycie 2500 kcal/dzień → ΔW = 0 → TDEE = 2500
      final base = DateTime(2026, 1, 1);
      final weights = List.generate(14, (i) => WeightEntry(
        date: base.add(Duration(days: i)),
        weightKg: 80.0,
      ));
      final food = List.generate(14, (i) => FoodLogEntry(
        date: base.add(Duration(days: i)),
        energyKcal: 2500,
      ));
      final result = EwmaEngine.calculate(
        weightEntries: weights, foodLogEntries: food,
      );
      expect(result.coldStartActive, isFalse);
      expect(result.adaptiveTDEE, isNotNull);
      // Przy ΔW ≈ 0 → TDEE_adaptive ≈ E_in_avg = 2500
      expect(result.adaptiveTDEE!, closeTo(2500, 50));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // MacroDistributor
  // ════════════════════════════════════════════════════════════════════════════
  group('MacroDistributor', () {
    test('Normalna ścieżka – 85 kg, BF%=15%, target=2500 kcal', () {
      final result = MacroDistributor.calculate(
        targetKcal: 2500,
        weightKg: 85,
        lbmKg: 85 * 0.85,  // 72.25 kg
        bodyFatPct: 15,
      );
      // Białko: 85 × 2.0 = 170 g
      expect(result.macros.proteinG, closeTo(170, 1));
      // Tłuszcz: 85 × 0.7 = 59.5 g
      expect(result.macros.fatG, closeTo(59.5, 1));
      // Carbs: (2500 − 170×4 − 59.5×9) / 4 = (2500 − 680 − 535.5) / 4 = 321.125 g
      expect(result.macros.carbsG, closeTo(321, 2));
      // Błonnik: 14 × 2500/1000 = 35 g
      expect(result.macros.fiberG, closeTo(35, 0.1));
      expect(result.usedLbmForProtein, isFalse);
    });

    test('Otyłość (BF%>20%) – białko na LBM', () {
      // 100 kg, BF%=30%, LBM=70 kg
      final result = MacroDistributor.calculate(
        targetKcal: 2200,
        weightKg: 100,
        lbmKg: 70,
        bodyFatPct: 30,
      );
      // Białko na LBM: 70 × 2.0 = 140 g (nie 100 × 2.0 = 200 g)
      expect(result.macros.proteinG, closeTo(140, 2));
      expect(result.usedLbmForProtein, isTrue);
    });

    test('Tryb GLP-1 – białko min 1.8 g/kg LBM', () {
      // 80 kg, BF%=15%, LBM=68 kg
      final result = MacroDistributor.calculate(
        targetKcal: 2000,
        weightKg: 80,
        lbmKg: 68,
        bodyFatPct: 15,
        isGlp1Mode: true,
      );
      // Białko: max(68 × 1.8, ...) = 122.4 g
      expect(result.macros.proteinG, greaterThanOrEqualTo(122));
      expect(result.usedLbmForProtein, isTrue);
    });

    test('Floor błonnika – 14g/1000kcal', () {
      final result = MacroDistributor.calculate(
        targetKcal: 1500,
        weightKg: 60,
        lbmKg: 51,
        bodyFatPct: 15,
      );
      // Błonnik min: 14 × 1500/1000 = 21 g
      expect(result.macros.fiberG, closeTo(21, 0.1));
    });

    test('totalKcal makr ≈ targetKcal', () {
      final result = MacroDistributor.calculate(
        targetKcal: 2400,
        weightKg: 75,
        lbmKg: 63.75,
        bodyFatPct: 15,
      );
      // Makra muszą sumować się do ~targetKcal (margines 5 kcal)
      expect(result.macros.totalKcal, closeTo(2400, 10));
    });

    test('Edge case: za mało kalorii → carbsDeficit warning', () {
      // 1000 kcal, 80kg – białko (160g=640kcal) + tłuszcz (56g=504kcal) > 1000 kcal
      final result = MacroDistributor.calculate(
        targetKcal: 1000,
        weightKg: 80,
        lbmKg: 68,
        bodyFatPct: 15,
      );
      expect(result.carbsDeficitWarning, isTrue);
      expect(result.macros.carbsG, 0.0);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // ClinicalGuard
  // ════════════════════════════════════════════════════════════════════════════
  group('ClinicalGuard', () {
    test('EA – prawidłowe obliczenie', () {
      // EA = (2000 − 500) / 65 ≈ 23.08 kcal/kg FFM
      final ea = ClinicalGuard.calculateEa(
        eiKcal: 2000, eeeKcal: 500, ffmKg: 65,
      );
      expect(ea, closeTo(23.08, 0.1));
    });

    test('EA – ffmKg = 0 zwraca null', () {
      final ea = ClinicalGuard.calculateEa(
        eiKcal: 2000, eeeKcal: 500, ffmKg: 0,
      );
      expect(ea, isNull);
    });

    test('classifyEa – risk poniżej 30', () {
      expect(ClinicalGuard.classifyEa(25), EaStatus.risk);
    });

    test('classifyEa – subOptimal między 30 a 45', () {
      expect(ClinicalGuard.classifyEa(38), EaStatus.subOptimal);
    });

    test('classifyEa – optimal powyżej 45', () {
      expect(ClinicalGuard.classifyEa(50), EaStatus.optimal);
    });

    test('Brak alertu RED-S przy EA ≥ 30 przez 5 dni', () {
      final base = DateTime(2026, 1, 1);
      // EA > 30: EI=2200, EEE=200, FFM=65 → EA = 2000/65 ≈ 30.77
      final food = List.generate(5, (i) => FoodLogEntry(
        date: base.add(Duration(days: i)),
        energyKcal: 2200,
      ));
      final alert = ClinicalGuard.detectReds(
        foodLogEntries: food,
        activityEntries: [],
        ffmKg: 65,
        weightKg: 80,
        maintenanceTDEE: 2500,
      );
      expect(alert, isNull);
    });

    test('Alert RED-S przy EA < 30 przez 6 dni', () {
      final base = DateTime(2026, 1, 1);
      // EA < 30: EI=1200, EEE=0, FFM=65 → EA = 1200/65 ≈ 18.46
      final food = List.generate(6, (i) => FoodLogEntry(
        date: base.add(Duration(days: i)),
        energyKcal: 1200,
      ));
      final alert = ClinicalGuard.detectReds(
        foodLogEntries: food,
        activityEntries: [],
        ffmKg: 65,
        weightKg: 80,
        maintenanceTDEE: 2500,
      );
      expect(alert, isNotNull);
      expect(alert!.type, ClinicalAlertType.dietBreak);
    });

    test('Brak alertu przy dokładnie 5 dniach EA < 30 (próg: > 5)', () {
      final base = DateTime(2026, 1, 1);
      final food = List.generate(5, (i) => FoodLogEntry(
        date: base.add(Duration(days: i)),
        energyKcal: 1200,
      ));
      final alert = ClinicalGuard.detectReds(
        foodLogEntries: food,
        activityEntries: [],
        ffmKg: 65,
        weightKg: 80,
        maintenanceTDEE: 2500,
      );
      expect(alert, isNull);
    });

    test('Przerwa w niskim EA resetuje licznik', () {
      final base = DateTime(2026, 1, 1);
      // 3 dni niskie EA, 1 dzień wysokie, 3 dni niskie → max streak = 3, brak alertu
      final food = [
        ...List.generate(3, (i) => FoodLogEntry(
          date: base.add(Duration(days: i)),
          energyKcal: 1200, // EA < 30
        )),
        FoodLogEntry(date: base.add(const Duration(days: 3)), energyKcal: 3000), // EA > 30
        ...List.generate(3, (i) => FoodLogEntry(
          date: base.add(Duration(days: 4 + i)),
          energyKcal: 1200,  // EA < 30
        )),
      ];
      final alert = ClinicalGuard.detectReds(
        foodLogEntries: food,
        activityEntries: [],
        ffmKg: 65,
        weightKg: 80,
        maintenanceTDEE: 2500,
      );
      expect(alert, isNull);
    });

    test('GLP-1 – mikroskładniki kobieta zawierają wyższe żelazo', () {
      final micros = ClinicalGuard.glp1Micros(isFemale: true);
      expect(micros.ironMg, 18.0);
      final microsM = ClinicalGuard.glp1Micros(isFemale: false);
      expect(microsM.ironMg, 8.0);
    });
  });
}
