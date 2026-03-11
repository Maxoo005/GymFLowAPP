import 'dart:math';

/// === BmrCalculator ===
/// Moduł estymacji BMR i składu ciała.
///
/// Obsługuje trzy metody obliczeniowe:
///   1. Wzór U.S. Navy – estymacja BF% z pomiarów obwodów ciała
///   2. Równanie Mifflina-St Jeora – domyślne dla populacji ogólnej
///   3. Równanie Katch-McArdle'a – zalecane dla sportowców z dobrą estymacją BF%
///
/// Jeśli dostępne są dane do obu równań (2 i 3), algorytm uśrednia je
/// arytmetycznie, minimalizując indywidualny błąd estymacji.
class BmrCalculator {
  // Prywatny konstruktor – klasa jest używana jako zbiór metod statycznych
  BmrCalculator._();

  // ── Wzór U.S. Navy – Estymacja BF% ─────────────────────────────────────
  //
  // Mężczyźni:
  //   BF% = 495 / (1.0324 − 0.19077·log10(waist−neck) + 0.15456·log10(height)) − 450
  //
  // Kobiety (wymagane biodra):
  //   BF% = 495 / (1.29579 − 0.35004·log10(waist+hip−neck) + 0.22100·log10(height)) − 450
  //
  // Źródło: Hodgdon & Beckett (1984), zaadaptowane przez U.S. Navy
  //
  /// Oblicza BF% metodą U.S. Navy.
  ///
  /// [waistCm] – obwód talii [cm]
  /// [neckCm]  – obwód szyi [cm]
  /// [heightCm] – wzrost [cm]
  /// [isFemale] – płeć (kobiety wymagają [hipCm])
  /// [hipCm]   – obwód bioder [cm] (tylko kobiety)
  ///
  /// Zwraca BF% jako wartość w przedziale [3.0, 60.0] lub null, jeśli
  /// brakuje wymaganych danych lub logarytm jest niedefiniowany.
  static double? usNavyBodyFat({
    required double waistCm,
    required double neckCm,
    required double heightCm,
    required bool isFemale,
    double? hipCm,
  }) {
    if (waistCm <= neckCm) return null; // Logarytm z liczby ≤ 0 jest niezdefiniowany
    if (heightCm <= 0) return null;
    if (isFemale && (hipCm == null || hipCm <= 0)) return null;

    double bf;
    if (!isFemale) {
      // Wzór dla mężczyzn
      final logWaistNeck = log(waistCm - neckCm) / ln10;
      final logHeight    = log(heightCm) / ln10;
      bf = 495.0 / (1.0324 - 0.19077 * logWaistNeck + 0.15456 * logHeight) - 450.0;
    } else {
      // Wzór dla kobiet
      final sum = waistCm + hipCm! - neckCm;
      if (sum <= 0) return null;
      final logSum    = log(sum) / ln10;
      final logHeight = log(heightCm) / ln10;
      bf = 495.0 / (1.29579 - 0.35004 * logSum + 0.22100 * logHeight) - 450.0;
    }

    // Przycinamy do rozsądnego zakresu fizjologicznego
    return bf.clamp(3.0, 60.0);
  }

  // ── Równanie Mifflina-St Jeora ──────────────────────────────────────────
  //
  // Mężczyźni: BMR = 10·W + 6.25·H − 5·A + 5
  // Kobiety:   BMR = 10·W + 6.25·H − 5·A − 161
  //
  // Źródło: Mifflin MD, St Jeor ST et al. (1990). Am J Clin Nutr.
  //
  /// Oblicza BMR metodą Mifflina-St Jeora.
  ///
  /// [weightKg] – masa ciała [kg]
  /// [heightCm] – wzrost [cm]
  /// [age]      – wiek [lata]
  /// [isFemale] – płeć
  static double mifflinStJeor({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isFemale,
  }) {
    final genderConstant = isFemale ? -161.0 : 5.0;
    return 10.0 * weightKg + 6.25 * heightCm - 5.0 * age + genderConstant;
  }

  // ── Równanie Katch-McArdle'a ────────────────────────────────────────────
  //
  // BMR = 370 + 21.6 × LBM
  //
  // gdzie LBM (Lean Body Mass) = masa ciała × (1 − BF% / 100)
  //
  // Źródło: Katch FI, McArdle WD (1975). Prediction of body density...
  //
  /// Oblicza BMR metodą Katch-McArdle'a.
  ///
  /// [weightKg]    – masa ciała [kg]
  /// [bodyFatPct]  – procent tkanki tłuszczowej [%]
  static double katchMcArdle({
    required double weightKg,
    required double bodyFatPct,
  }) {
    final lbm = weightKg * (1.0 - bodyFatPct / 100.0);
    return 370.0 + 21.6 * lbm;
  }

  // ── BmrResult – pełna estymacja ─────────────────────────────────────────

  /// Wynik pełnego procesu estymacji BMR.
  static BmrResult calculate({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isFemale,
    // Opcjonalne dane do wzoru Navy i Katch-McArdle
    double? waistCm,
    double? neckCm,
    double? hipCm,
    double? manualBodyFatPct, // Ręcznie wprowadzony przez użytkownika/sportowca
  }) {
    // Krok 1: Estymacja BF%
    // Priorytet: ręczny wpis → wzór U.S. Navy → brak
    double? bfPct = manualBodyFatPct;
    if (bfPct == null && waistCm != null && neckCm != null) {
      bfPct = usNavyBodyFat(
        waistCm: waistCm,
        neckCm: neckCm,
        heightCm: heightCm,
        isFemale: isFemale,
        hipCm: hipCm,
      );
    }

    // Krok 2: Oblicz LBM
    final lbmKg = bfPct != null
        ? weightKg * (1.0 - bfPct / 100.0)
        : weightKg * 0.85; // Fallback: 15% BF zakładane jeśli brak danych

    // Krok 3: BMR – Mifflin-St Jeor (zawsze dostępny)
    final bmrMifflin = mifflinStJeor(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      isFemale: isFemale,
    );

    // Krok 4: BMR – Katch-McArdle (dostępny tylko gdy znany BF%)
    final double? bmrKatch = bfPct != null
        ? katchMcArdle(weightKg: weightKg, bodyFatPct: bfPct)
        : null;

    // Krok 5: Uśrednianie – minimalizacja błędu estymacji
    // Jeśli oba równania dostępne → BMR = (Mifflin + Katch) / 2
    final double bmrFinal = bmrKatch != null
        ? (bmrMifflin + bmrKatch) / 2.0
        : bmrMifflin;

    return BmrResult(
      bmr: bmrFinal,
      bmrMifflin: bmrMifflin,
      bmrKatch: bmrKatch,
      bodyFatPct: bfPct ?? (isFemale ? 20.0 : 15.0), // Wartość domyślna jeśli nieznana
      lbmKg: lbmKg,
      usedAveraging: bmrKatch != null,
    );
  }
}

/// Wynik modułu estymacji BMR.
class BmrResult {
  /// Ostateczny BMR [kcal] – uśredniony lub z jednego równania
  final double bmr;

  /// BMR wg Mifflina-St Jeora [kcal]
  final double bmrMifflin;

  /// BMR wg Katch-McArdle'a [kcal] – null gdy brak danych BF%
  final double? bmrKatch;

  /// Procent tkanki tłuszczowej użyty do obliczeń [%]
  final double bodyFatPct;

  /// Beztłuszczowa masa ciała [kg]
  final double lbmKg;

  /// True, gdy BMR obliczono jako średnią arytmetyczną obu równań
  final bool usedAveraging;

  const BmrResult({
    required this.bmr,
    required this.bmrMifflin,
    required this.bmrKatch,
    required this.bodyFatPct,
    required this.lbmKg,
    required this.usedAveraging,
  });

  bool get isObesityRange => bodyFatPct > 20.0;

  @override
  String toString() =>
      'BmrResult(BMR:${bmr.toStringAsFixed(0)}kcal, BF%:${bodyFatPct.toStringAsFixed(1)}, '
      'LBM:${lbmKg.toStringAsFixed(1)}kg, avg:$usedAveraging)';
}
