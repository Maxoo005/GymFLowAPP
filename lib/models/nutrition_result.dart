import 'macro_targets.dart';
import 'clinical_alert.dart';
import 'micronutrient_targets.dart';

/// === NutritionResult ===
/// Kompletny wynik obliczeń silnika żywieniowego dla danego użytkownika
/// i danego momentu czasowego.
///
/// Zawiera:
///   - Szacowane BMR i TDEE (moduł estymacji)
///   - Adaptacyjne TDEE (dostępne po 14 dniach danych wagowych)
///   - Beztłuszczową masę ciała (LBM)
///   - Cele makroskładnikowe w gramach bezwzględnych
///   - (Opcjonalnie) Cele mikroskładnikowe – tylko tryb GLP-1
///   - Aktywny alert kliniczny (RED-S / Diet Break) lub null
///   - Flagi stanu systemu (cold start, tryb GLP-1)
class NutritionResult {
  // ── Energetyka bazowa ────────────────────────────────────────────────
  /// BMR [kcal] – Podstawowa Przemiana Materii
  /// (średnia Mifflina-St Jeora i/lub Katch-McArdle'a)
  final double bmr;

  /// TDEE szacowane [kcal] – BMR × 1.2 (dni bez treningu) + EEE (dni treningowe)
  final double tdeeEstimated;

  /// TDEE adaptacyjne [kcal] – obliczone z rzeczywistych danych wagowych i kalorycznych
  /// Dostępne tylko po zakończeniu cold-startu (≥14 dni danych).
  /// Wzór: TDEE_adaptive = E_in_avg − (ΔW_smoothed × 7700 / 7)
  final double? tdeeAdaptive;

  /// Docelowe kalorie [kcal] – po korekcie celu treningowego
  final double targetKcal;

  // ── Skład ciała ──────────────────────────────────────────────────────
  /// Beztłuszczowa masa ciała [kg]  (LBM = masa × (1 − BF%/100))
  final double lbmKg;

  /// Procent tkanki tłuszczowej [%] (z wzoru U.S. Navy lub wpisu ręcznego)
  final double bodyFatPercent;

  /// Wygładzona masa ciała z EWMA [kg] (dostępna po ≥1 wpisie wagowym)
  final double? smoothedWeightKg;

  // ── Makro / Mikro ────────────────────────────────────────────────────
  /// Absolutne cele makroskładnikowe w gramach
  final MacroTargets macros;

  /// Cele mikroskładnikowe – aktywne tylko w trybie GLP-1
  final MicronutrientTargets? micros;

  // ── Moduł kliniczny ─────────────────────────────────────────────────
  /// Alert kliniczny (RED-S / Diet Break) lub null, gdy brak zagrożenia
  final ClinicalAlert? alert;

  /// Dostępność Energii [kcal/kg FFM]
  /// EA = (EI − EEE) / FFM
  /// Wartość < 30 przez >5 dni → ryzyko RED-S
  final double? energyAvailability;

  // ── Flagi stanu systemu ──────────────────────────────────────────────
  /// True, gdy system jest w fazie cold-startu (<14 dni danych wagowych)
  /// W tym trybie używane jest wyłącznie TDEE szacowane.
  final bool coldStartActive;

  /// True, gdy tryb GLP-1 Companion jest aktywny
  final bool glp1Mode;

  const NutritionResult({
    required this.bmr,
    required this.tdeeEstimated,
    required this.tdeeAdaptive,
    required this.targetKcal,
    required this.lbmKg,
    required this.bodyFatPercent,
    required this.smoothedWeightKg,
    required this.macros,
    required this.micros,
    required this.alert,
    required this.energyAvailability,
    required this.coldStartActive,
    required this.glp1Mode,
  });

  /// TDEE do użycia w UI: adaptacyjne (jeśli dostępne) lub szacowane
  double get effectiveTDEE => tdeeAdaptive ?? tdeeEstimated;

  /// Zaokrąglone docelowe kalorie dla UI
  int get targetKcalRounded => targetKcal.round();

  @override
  String toString() =>
      'NutritionResult(BMR:${bmr.toStringAsFixed(0)}, TDEE:${effectiveTDEE.toStringAsFixed(0)}, '
      'Target:${targetKcalRounded}kcal, $macros)';
}
