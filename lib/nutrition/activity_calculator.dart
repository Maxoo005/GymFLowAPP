import '../models/activity_entry.dart';

/// === ActivityCalculator ===
/// Moduł obliczania wydatku energetycznego z aktywności fizycznej (EEE).
///
/// Używa równoważników metabolicznych (MET) jako jednostek intensywności.
///
/// Wzór na EEE (Exercise Energy Expenditure):
///   EEE [kcal] = durationMin × (MET × 3.5 × weightKg) / 200
///
/// Źródło wzoru: Ainsworth BE et al. "Compendium of Physical Activities" (2011)
///
/// Wzór TDEE bazowego (dni bez treningu):
///   baseTDEE = BMR × 1.2
///
/// TDEE dnia treningowego:
///   trainingDayTDEE = baseTDEE + Σ EEE_i
///
/// Dlaczego BMR × 1.2, a nie klasyczny PAL?
///   Mnożnik 1.2 (sedentary NEAT + termogeneza poposiłkowa) jest używany
///   jako bazowe okno. Aktywność jest dokładana MODUŁOWO z rzeczywistych
///   danych MET, co eliminuje chroniczne zawyżanie PAL typowe dla statycznych
///   mnożników aktywności.
class ActivityCalculator {
  ActivityCalculator._();

  /// Oblicza EEE (kalorie spalone) dla jednej sesji aktywności.
  ///
  /// [met]        – wartość MET aktywności (np. 5.0 – trening siłowy)
  /// [durationMin] – czas trwania [min]
  /// [weightKg]   – masa ciała użytkownika [kg]
  static double calculateEee({
    required double met,
    required double durationMin,
    required double weightKg,
  }) {
    assert(met > 0, 'MET musi być większy od 0');
    assert(durationMin > 0, 'Czas trwania musi być większy od 0');
    assert(weightKg > 0, 'Masa ciała musi być większa od 0');

    // EEE [kcal] = durationMin × (MET × 3.5 × weightKg) / 200
    return durationMin * (met * 3.5 * weightKg) / 200.0;
  }

  /// Oblicza całkowite EEE z listy sesji treningowych (jeden dzień).
  ///
  /// [activities] – lista sesji z jednego dnia
  /// [weightKg]   – aktualna masa ciała użytkownika
  static double totalEeeFromEntries({
    required List<ActivityEntry> activities,
    required double weightKg,
  }) {
    if (activities.isEmpty) return 0.0;
    return activities.fold(0.0, (sum, entry) {
      return sum + calculateEee(
        met: entry.met,
        durationMin: entry.durationMin,
        weightKg: weightKg,
      );
    });
  }

  /// Oblicza bazowe TDEE (dni bez treningu): BMR × 1.2.
  ///
  /// Mnożnik 1.2 uwzględnia NEAT w siedzącym trybie życia oraz
  /// termogenezę indukowaną dietą (DIT). Aktywność fizyczna jest
  /// uwzględniana osobno przez [totalEeeFromEntries].
  static double baseTdee(double bmr) => bmr * 1.2;

  /// Oblicza TDEE dla dnia treningowego: baseTDEE + EEE.
  ///
  /// [bmr]       – podstawowa przemiana materii
  /// [activities] – sesje treningowe z danego dnia
  /// [weightKg]  – masa ciała użytkownika
  static double trainingDayTdee({
    required double bmr,
    required List<ActivityEntry> activities,
    required double weightKg,
  }) {
    return baseTdee(bmr) + totalEeeFromEntries(
      activities: activities,
      weightKg: weightKg,
    );
  }

  // ── Predefiniowane wartości MET ──────────────────────────────────────────
  // Na podstawie: Ainsworth "Compendium of Physical Activities" (2011), ACSM
  static const Map<String, double> metValues = {
    // Trening siłowy
    'strength_light':       3.5,  // Trening siłowy lekki (<50% 1RM)
    'strength_moderate':    5.0,  // Trening siłowy umiarkowany (50-70% 1RM)
    'strength_vigorous':    6.0,  // Trening siłowy intensywny (>70% 1RM)
    'powerlifting':         6.0,  // Podnoszenie ciężarów
    'olympic_lifting':      6.0,  // Dwubój olimpijski
    // Cardio
    'walking_slow':         2.8,  // Spacer 4 km/h
    'walking_moderate':     3.5,  // Spacer 5 km/h
    'walking_brisk':        4.3,  // Szybki spacer 6 km/h
    'running_8kmh':         8.0,  // Bieg 8 km/h
    'running_10kmh':        10.0, // Bieg 10 km/h
    'running_12kmh':        11.5, // Bieg 12 km/h
    'cycling_moderate':     7.0,  // Rower stacjonarny umiarkowany
    'cycling_vigorous':     10.0, // Rower intensywny
    'swimming_leisurely':   6.0,  // Pływanie rekreacyjne
    'swimming_vigorous':    9.8,  // Pływanie intensywne
    // HIIT / Sporty grupowe
    'hiit':                 8.0,  // HIIT (typowy)
    'crossfit':             10.0, // CrossFit
    'basketball':           6.5,  // Koszykówka
    'football':             8.0,  // Piłka nożna
    'yoga':                 2.5,  // Joga
    'stretching':           2.3,  // Rozciąganie
  };

  /// Zwraca wartość MET dla danego klucza aktywności lub domyślną (5.0).
  static double getMet(String activityKey) =>
      metValues[activityKey] ?? 5.0;
}
