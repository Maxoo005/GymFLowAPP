import '../models/macro_targets.dart';

/// === MacroDistributor ===
/// Moduł dystrybucji makroskładników w wartościach ABSOLUTNYCH [g/kg].
///
/// UWAGA: Ten moduł całkowicie porzuca programowanie procentowe.
/// Makroskładniki są programowane w bezwzględnych gramach na kilogram
/// masy ciała lub LBM, zgodnie z aktualnym konsensusem naukowym.
///
/// === Algorytm dystrybucji ===
///
/// 1. BIAŁKO (Protein) – priorytety:
///    Norma: 1.6–2.4 g/kg całkowitej masy ciała
///    Środek zakresu: 2.0 g/kg (domyślne)
///    Wyjątek otyłości (BF% > 20%): używamy WYŁĄCZNIE LBM jako bazy,
///    aby uniknąć absurdalnie wysokich dawek (np. 200 g/dobę przy 100 kg i 30% BF)
///    Wyjątek GLP-1: minimum 1.8 g/kg LBM (bez względu na BF%)
///
/// 2. TŁUSZCZE (Fat) – minimum kliniczne:
///    Norma: 0.5–0.8 g/kg całkowitej masy ciała
///    Środek zakresu: 0.7 g/kg (domyślne)
///    Minimum kliniczne chroni: hormony płciowe, wchłanianie witamin ADEK,
///    integralność błon komórkowych.
///
/// 3. WĘGLOWODANY (Carbs) – reszt kaloryczna:
///    Carbs = (targetKcal − protein×4 − fat×9) / 4
///    Jeśli wynik ujemny → ustaw 0 i flaga ostrzeżenia.
///
/// 4. BŁONNIK (Fiber) – floor kliniczny:
///    Minimum: 14 g / 1000 kcal diety
///    (zgodne z wytycznymi EFSA i American Heart Association)
class MacroDistributor {
  MacroDistributor._();

  // ── Konstandy kliniczne ──────────────────────────────────────────────────

  /// Docelowa podaż białka [g/kg] – środek zakresu 1.6–2.4
  static const double proteinGPerKg = 2.0;

  /// Minimalna podaż białka [g/kg] (dolna granica kliniczna)
  static const double proteinMinGPerKg = 1.6;

  /// Maksymalna podaż białka [g/kg] (górna granica rozsądna)
  static const double proteinMaxGPerKg = 2.4;

  /// Docelowa podaż tłuszczu [g/kg] – środek zakresu 0.5–0.8
  static const double fatGPerKg = 0.7;

  /// Minimalna kliniczna podaż tłuszczu [g/kg]
  static const double fatMinGPerKg = 0.5;

  /// Próg BF% definiujący otyłość dla celów obliczania białka
  /// Powyżej tej wartości białko jest liczone na LBM, nie całkowitą masę ciała
  static const double obesityBfThreshold = 20.0;

  /// Minimalna podaż błonnika [g / 1000 kcal]
  static const double fiberPerKcal = 14.0 / 1000.0;

  /// Minimalna podaż białka w trybie GLP-1 [g/kg LBM]
  static const double glp1ProteinMinPerLbm = 1.8;

  // ── Główna metoda ────────────────────────────────────────────────────────

  /// Oblicza absolutne cele makroskładnikowe.
  ///
  /// [targetKcal]   – docelowa podaż kalorii [kcal]
  /// [weightKg]     – całkowita masa ciała [kg]
  /// [lbmKg]        – beztłuszczowa masa ciała [kg]
  /// [bodyFatPct]   – procent tkanki tłuszczowej [%]
  /// [isGlp1Mode]   – flaga trybu GLP-1 (lek na otyłość)
  static MacroResult calculate({
    required double targetKcal,
    required double weightKg,
    required double lbmKg,
    required double bodyFatPct,
    bool isGlp1Mode = false,
  }) {
    assert(targetKcal > 0);
    assert(weightKg > 0);
    assert(lbmKg > 0 && lbmKg <= weightKg);

    final bool isObese = bodyFatPct > obesityBfThreshold;

    // ── Krok 1: Białko ────────────────────────────────────────────────
    double proteinG;

    if (isGlp1Mode) {
      // Tryb GLP-1: minimum 1.8 g/kg LBM (zawsze na LBM)
      proteinG = lbmKg * glp1ProteinMinPerLbm;
    } else if (isObese) {
      // Otyłość: używamy LBM aby uniknąć absurdów
      // Reguła: 2.0 g/kg LBM (równoważne ok. 1.6 g/kg BW przy typowej otyłości)
      proteinG = lbmKg * proteinGPerKg;
    } else {
      // Norma: 2.0 g/kg całkowitej masy ciała
      proteinG = weightKg * proteinGPerKg;
    }

    // Weryfikacja: nigdy poniżej minimum klinicznego
    // W przypadku otyłości zarówno floor jak i ceiling odnoszą się do LBM
    final proteinFloor = isGlp1Mode
        ? lbmKg * glp1ProteinMinPerLbm
        : (isObese ? lbmKg * proteinMinGPerKg : weightKg * proteinMinGPerKg);
        
    final proteinCeiling = isObese ? lbmKg * proteinMaxGPerKg : weightKg * proteinMaxGPerKg;
    
    proteinG = proteinG.clamp(proteinFloor, proteinCeiling);

    // ── Krok 2: Tłuszcze ──────────────────────────────────────────────
    // Zawsze na całkowitą masę ciała (nie LBM)
    double fatG = weightKg * fatGPerKg;
    // Minimum kliniczne
    final fatFloor = weightKg * fatMinGPerKg;
    if (fatG < fatFloor) fatG = fatFloor;

    // ── Krok 3: Węglowodany (reszt kaloryczna) ────────────────────────
    final proteinKcal = proteinG * 4.0;
    final fatKcal     = fatG * 9.0;
    final remainingKcal = targetKcal - proteinKcal - fatKcal;

    // Obsługa edge case: ujemna reszt (np. bardzo niska podaż kaloryczna)
    final bool carbsDeficit = remainingKcal < 0;
    final double carbsG = carbsDeficit ? 0.0 : remainingKcal / 4.0;

    // ── Krok 4: Błonnik ───────────────────────────────────────────────
    // Minimum: 14 g / 1000 kcal → fiberPerKcal × targetKcal
    final fiberG = fiberPerKcal * targetKcal;

    // Rzeczywiste kalorie po korekcie węglowodanów
    final actualKcal = carbsDeficit
        ? proteinKcal + fatKcal
        : targetKcal;

    return MacroResult(
      macros: MacroTargets(
        proteinG: proteinG,
        fatG: fatG,
        carbsG: carbsG,
        fiberG: fiberG,
      ),
      actualKcal: actualKcal,
      carbsDeficitWarning: carbsDeficit,
      usedLbmForProtein: isObese || isGlp1Mode,
    );
  }
}

/// Wynik modułu dystrybucji makroskładników.
class MacroResult {
  /// Absolutne cele makroskładnikowe
  final MacroTargets macros;

  /// Rzeczywiste kalorie (może różnić się od targetKcal przy edge case'ach)
  final double actualKcal;

  /// True, gdy po odliczeniu białka i tłuszczu brakuje kalorii na węglowodany
  final bool carbsDeficitWarning;

  /// True, gdy białko obliczono na LBM (nie na całkowitą masę ciała)
  final bool usedLbmForProtein;

  const MacroResult({
    required this.macros,
    required this.actualKcal,
    required this.carbsDeficitWarning,
    required this.usedLbmForProtein,
  });
}
