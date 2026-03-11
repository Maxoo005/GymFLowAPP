import '../models/clinical_alert.dart';
import '../models/food_log_entry.dart';
import '../models/activity_entry.dart';
import '../models/micronutrient_targets.dart';
import 'activity_calculator.dart';

/// === ClinicalGuard ===
/// Moduł ochrony klinicznej – monitoruje wskaźniki zdrowotne i wyzwala
/// alerty gdy użytkownik wchodzi w strefę ryzyka.
///
/// Implementuje:
///   1. Obliczanie Dostępności Energii (EA – Energy Availability)
///   2. Detekcję RED-S (Relative Energy Deficiency in Sport)
///   3. Protokół "Diet Break" (tymczasowe podniesienie kalorii do TDEE)
///   4. Tryb GLP-1 Companion (agonisty receptorów GLP-1)
///
/// === Dostępność Energii (EA) ===
///   EA = (EI − EEE) / FFM
///
/// gdzie:
///   EI   = Energy Intake [kcal] – spożycie energii
///   EEE  = Exercise Energy Expenditure [kcal] – kalorie z treningu
///   FFM  = Fat-Free Mass [kg] – beztłuszczowa masa ciała (≡ LBM)
///
/// Progi kliniczne EA (wg Mountjoy et al., British Journal of Sports Medicine, 2018):
///   EA < 30 kcal/kg FFM → Strefa klinicznego ryzyka RED-S
///   EA 30–45 kcal/kg FFM → Strefa zmniejszonej wydajności
///   EA > 45 kcal/kg FFM → Optymalny stan energetyczny
///
/// === RED-S (Relative Energy Deficiency in Sport) ===
///   Przewlekłe EA < 30 przez >5 kolejnych dni wyzwala alert.
///   Alert → uruchomienie protokołu "Diet Break" (kalorie = TDEE maintenance).
///
/// Źródło: IOC Consensus Statement on RED-S (2018, 2023 update)
class ClinicalGuard {
  ClinicalGuard._();

  // ── Progi kliniczne ──────────────────────────────────────────────────────

  /// EA poniżej tego progu przez >5 dni → alert RED-S [kcal/kg FFM]
  static const double eaRiskThreshold = 30.0;

  /// Optymalna EA [kcal/kg FFM]
  static const double eaOptimalThreshold = 45.0;

  /// Liczba dni konsekutywnych EA < progu, by wyzwolić alert
  static const int redsDaysThreshold = 5;

  // ── Obliczanie EA ────────────────────────────────────────────────────────

  /// Oblicza Dostępność Energii (EA) dla jednego dnia.
  ///
  /// [eiKcal]   – całkowite spożycie energii w danym dniu [kcal]
  /// [eeeKcal]  – kalorie spalone podczas treningu [kcal]
  /// [ffmKg]    – beztłuszczowa masa ciała (LBM) [kg]
  ///
  /// Zwraca EA [kcal/kg FFM] lub null jeśli brakuje danych.
  static double? calculateEa({
    required double eiKcal,
    required double eeeKcal,
    required double ffmKg,
  }) {
    if (ffmKg <= 0) return null;
    if (eiKcal < 0) return null;

    return (eiKcal - eeeKcal) / ffmKg;
  }

  /// Klasyfikacja EA.
  static EaStatus classifyEa(double ea) {
    if (ea < eaRiskThreshold) return EaStatus.risk;
    if (ea < eaOptimalThreshold) return EaStatus.subOptimal;
    return EaStatus.optimal;
  }

  // ── Detekcja RED-S ───────────────────────────────────────────────────────

  /// Analizuje historię spożycia i aktywności pod kątem ryzyka RED-S.
  ///
  /// Zwraca [ClinicalAlert] jeśli wykryto >5 kolejnych dni z EA < 30,
  /// lub null jeśli brak ryzyka / brak wystarczających danych.
  ///
  /// [foodLogEntries]   – historia spożycia kalorii (ostatnie N dni)
  /// [activityEntries]  – historia sesji treningowych
  /// [ffmKg]            – beztłuszczowa masa ciała [kg]
  /// [weightKg]         – masa ciała [kg] (do obliczeń EEE)
  /// [maintenanceTDEE]  – kalibracyjne TDEE do protokołu Diet Break
  static ClinicalAlert? detectReds({
    required List<FoodLogEntry> foodLogEntries,
    required List<ActivityEntry> activityEntries,
    required double ffmKg,
    required double weightKg,
    required double maintenanceTDEE,
  }) {
    if (foodLogEntries.isEmpty || ffmKg <= 0) return null;

    // Grupuj spożycie wg dnia
    final dailyEI = <DateTime, double>{};
    for (final entry in foodLogEntries) {
      final d = _dateOnly(entry.date);
      dailyEI[d] = (dailyEI[d] ?? 0) + entry.energyKcal;
    }

    // Grupuj EEE wg dnia
    final dailyEEE = <DateTime, double>{};
    for (final entry in activityEntries) {
      final d = _dateOnly(entry.date);
      final eee = ActivityCalculator.calculateEee(
        met: entry.met,
        durationMin: entry.durationMin,
        weightKg: weightKg,
      );
      dailyEEE[d] = (dailyEEE[d] ?? 0) + eee;
    }

    // Oblicz EA dzień po dniu i zlicz kolejne dni poniżej progu
    final dates = dailyEI.keys.toList()..sort();
    int consecutiveRiskDays = 0;
    int maxConsecutiveRiskDays = 0;

    for (final date in dates) {
      final ei  = dailyEI[date] ?? 0;
      final eee = dailyEEE[date] ?? 0;
      final ea  = calculateEa(eiKcal: ei, eeeKcal: eee, ffmKg: ffmKg);

      if (ea != null && ea < eaRiskThreshold) {
        consecutiveRiskDays++;
        if (consecutiveRiskDays > maxConsecutiveRiskDays) {
          maxConsecutiveRiskDays = consecutiveRiskDays;
        }
      } else {
        consecutiveRiskDays = 0;
      }
    }

    if (maxConsecutiveRiskDays > redsDaysThreshold) {
      return ClinicalAlert(
        type: ClinicalAlertType.dietBreak,
        message: 'Wykryto RED-S: Dostępność Energii poniżej 30 kcal/kg FFM '
                 'przez $maxConsecutiveRiskDays kolejnych dni. '
                 'Ryzyko: niedobór hormonów, utrata gęstości kości, '
                 'zaburzenia metaboliczne.',
        recommendation: 'Protokół "Diet Break": zwiększ kalorie do poziomu '
                        'zapotrzebowania na utrzymanie '
                        '(${maintenanceTDEE.toStringAsFixed(0)} kcal/dobę) '
                        'przez minimum 1–2 tygodnie. '
                        'Zalecana konsultacja z dietetykiem klinicznym.',
      );
    }

    return null;
  }

  // ── Analiza EA dla jednego dnia (helper dla UI) ──────────────────────────

  /// Zwraca EA bieżącego dnia na podstawie dzisiejszych wpisów.
  static double? todaysEa({
    required List<FoodLogEntry> foodLogEntries,
    required List<ActivityEntry> activityEntries,
    required double ffmKg,
    required double weightKg,
  }) {
    final today = _dateOnly(DateTime.now());

    final ei = foodLogEntries
        .where((e) => _dateOnly(e.date) == today)
        .fold(0.0, (s, e) => s + e.energyKcal);

    final eee = activityEntries
        .where((e) => _dateOnly(e.date) == today)
        .fold(0.0, (s, e) => s + ActivityCalculator.calculateEee(
          met: e.met,
          durationMin: e.durationMin,
          weightKg: weightKg,
        ));

    return calculateEa(eiKcal: ei, eeeKcal: eee, ffmKg: ffmKg);
  }

  // ── Tryb GLP-1 Companion ─────────────────────────────────────────────────

  /// Zwraca cele mikroskładnikowe dla trybu GLP-1.
  ///
  /// Gdy flaga GLP-1 jest aktywna:
  ///   - Agonisty GLP-1 silnie hamują łaknienie → drastycznie mniejsze spożycie pokarmów
  ///   - Ryzyko niedoborów: Ca, Fe, Mg, Zn, Witamina D
  ///   - System pomija adaptacyjne cięcie kalorii (lek i tak redukuje kaloryczność)
  ///   - Białko: minimum 1.8 g/kg LBM (obsługiwane przez MacroDistributor)
  ///
  /// [isFemale] – płeć (wpływa na normy Fe i Mg)
  static MicronutrientTargets glp1Micros({required bool isFemale}) {
    return MicronutrientTargets.glp1Defaults(isFemale: isFemale);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}

/// Status dostępności energii
enum EaStatus {
  /// EA < 30 kcal/kg FFM – strefa klinicznego ryzyka RED-S
  risk,

  /// EA 30–45 kcal/kg FFM – strefa zmniejszonej wydajności sportowej
  subOptimal,

  /// EA > 45 kcal/kg FFM – optymalny stan energetyczny
  optimal,
}

extension EaStatusExtension on EaStatus {
  String get label {
    switch (this) {
      case EaStatus.risk:       return 'Strefa Ryzyka RED-S';
      case EaStatus.subOptimal: return 'Suboptymalny';
      case EaStatus.optimal:    return 'Optymalny';
    }
  }
}
