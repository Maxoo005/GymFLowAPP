import '../models/weight_entry.dart';
import '../models/food_log_entry.dart';

/// === EwmaEngine ===
/// Rdzeń Termodynamiki Adaptacyjnej – silnik EWMA (Exponentially Weighted Moving Average).
///
/// Cel: Odfiltrowanie fizjologicznego "szumu" (wahania wody, glukogenu, treści przewodu
/// pokarmowego) z codziennych odczytów wagi. Trend wygładzonej wagi jest miarą prawdziwej
/// zmiany tkanki tłuszczowej/mięśniowej.
///
/// === Wzór EWMA ===
///   S_t = α × X_t + (1 − α) × S_{t−1}
///
/// gdzie:
///   α  = 0.1  (stały mnożnik wygładzający – hardcoded)
///   X_t = aktualna waga
///   S_t = wygładzona waga (szacunek trendu)
///   S_{t-1} = poprzednia wygładzona waga
///
/// Dlaczego α = 0.1?
///   Niska wartość α oznacza strong smoothing – wagi sprzed tygodnia mają
///   wciąż duży wpływ na wartość bieżącą. To jest pożądane w kontekście
///   dietetycznym, gdzie chcemy widzieć trend tygodniowy, nie dobowy szum.
///
/// === Cold-Start ===
///   System wymaga ≥14 dni danych wagowych przed przejściem w tryb adaptacyjny.
///   Poniżej tego progu zwracana jest wartość null dla adaptiveTDEE.
///
/// === Obsługa brakujących dni ===
///   Jeśli użytkownik nie zważył się danego dnia, algorytm forward-filluje
///   ostatnią wygładzoną wartość (brak szumu = brak sygnału = S_t = S_{t-1}).
///   Nie generujemy "phantom observations".
///
/// === Wzór adaptacyjnego TDEE ===
///   Na podstawie zasady bilansu energetycznego (1 kg tkanki tłuszczowej ≈ 7700 kcal):
///
///   TDEE_adaptive = E_in_avg − (ΔW_smoothed × 7700 / 7)
///
/// gdzie:
///   E_in_avg        = średnie dzienne spożycie kalorii z okna obserwacji
///   ΔW_smoothed     = zmiana wygładzonej wagi [kg/tydzień]
///                     = (S_last − S_first) / n_weeks
///   7700            = kcal w 1 kg tkanki tłuszczowej [kcal/kg]
///   / 7             = przeliczenie z tygodniowego na dobowy
class EwmaEngine {
  EwmaEngine._();

  /// Sztywny mnożnik wygładzający.
  /// Wartość klinicznie walidowana dla monitorowania wagi przez HealthTech.
  static const double alpha = 0.1;

  /// Minimalna liczba dni wpisów wagowych wymagana do trybu adaptacyjnego.
  static const int coldStartDays = 14;

  // ── Główna metoda obliczeniowa ───────────────────────────────────────────

  /// Przetwarza historyczne wpisy wagowe i kaloryczne, zwracając wynik EWMA.
  ///
  /// [weightEntries]   – wszystkie zapisane wpisy wagowe, posortowane chronologicznie
  /// [foodLogEntries]  – wszystkie wpisy kaloryczne (opcjonalne – potrzebne do adaptiveTDEE)
  /// [windowDays]      – liczba ostatnich dni do analizy (domyślnie 21)
  static EwmaResult calculate({
    required List<WeightEntry> weightEntries,
    required List<FoodLogEntry> foodLogEntries,
    int windowDays = 21,
  }) {
    if (weightEntries.isEmpty) {
      return EwmaResult(
        smoothedWeight: null,
        adaptiveTDEE: null,
        coldStartActive: true,
        dayCount: 0,
        weightEntryCount: 0,
      );
    }

    // Sortujemy chronologicznie
    final sortedEntries = List<WeightEntry>.from(weightEntries)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Przycinamy do okna czasowego
    final cutoff = sortedEntries.last.date.subtract(Duration(days: windowDays));
    final windowEntries = sortedEntries
        .where((e) => e.date.isAfter(cutoff) || e.date.isAtSameMomentAs(cutoff))
        .toList();

    // Inicjalizacja: S_0 = pierwsza waga (nie ma poprzedniej wartości)
    double smoothed = windowEntries.first.weightKg;

    // Oblicz wygładzone wartości dla każdego dnia w oknie
    final smoothedHistory = <DateTime, double>{};
    smoothedHistory[_dateOnly(windowEntries.first.date)] = smoothed;

    for (int i = 1; i < windowEntries.length; i++) {
      // Detekcja brakujących dni – forward-fill
      final prevDate = windowEntries[i - 1].date;
      final currDate = windowEntries[i].date;
      final gapDays = currDate.difference(prevDate).inDays;

      if (gapDays > 1) {
        // Uzupełnij pominięte dni: S_t = S_{t-1} (brak sygnału)
        for (int d = 1; d < gapDays; d++) {
          final fillDate = prevDate.add(Duration(days: d));
          smoothedHistory[_dateOnly(fillDate)] = smoothed;
        }
      }

      // Właściwe obliczenie EWMA dla dnia z danymi
      // S_t = α × X_t + (1 − α) × S_{t-1}
      smoothed = alpha * windowEntries[i].weightKg + (1.0 - alpha) * smoothed;
      smoothedHistory[_dateOnly(currDate)] = smoothed;
    }

    // Sprawdzenie cold-startu
    final isInColdStart = windowEntries.length < coldStartDays;

    // Oblicz adaptacyjne TDEE (tylko po zakończeniu cold-startu)
    double? adaptiveTDEE;
    if (!isInColdStart && foodLogEntries.isNotEmpty) {
      adaptiveTDEE = _calculateAdaptiveTDEE(
        smoothedHistory: smoothedHistory,
        foodLogEntries: foodLogEntries,
        windowDays: windowDays,
      );
    }

    return EwmaResult(
      smoothedWeight: smoothed,
      adaptiveTDEE: adaptiveTDEE,
      coldStartActive: isInColdStart,
      dayCount: smoothedHistory.length,
      weightEntryCount: windowEntries.length,
      smoothedHistory: smoothedHistory,
    );
  }

  // ── Obliczanie adaptacyjnego TDEE ────────────────────────────────────────
  //
  //   TDEE_adaptive = E_in_avg − (ΔW_smoothed × 7700 / 7)
  //
  // ΔW_smoothed = verschiedenheit wygładzonej wagi między początkiem i końcem okna [kg/tydzień]
  static double? _calculateAdaptiveTDEE({
    required Map<DateTime, double> smoothedHistory,
    required List<FoodLogEntry> foodLogEntries,
    required int windowDays,
  }) {
    if (smoothedHistory.length < 2) return null;

    final dates = smoothedHistory.keys.toList()..sort();
    final weightFirst = smoothedHistory[dates.first]!;
    final weightLast  = smoothedHistory[dates.last]!;

    // ΔW = całkowita zmiana wygładzonej wagi w oknie [kg]
    final deltaWTotal = weightLast - weightFirst;
    // Przeliczenie na zmianę tygodniową [kg/tydzień]
    final nWeeks = dates.last.difference(dates.first).inDays / 7.0;
    if (nWeeks < 0.001) return null;

    final deltaWWeekly = deltaWTotal / nWeeks;

    // Średnie spożycie kalorii w oknie czasowym
    final cutoff = dates.last.subtract(Duration(days: windowDays));
    final windowFood = foodLogEntries.where(
      (e) => e.date.isAfter(cutoff) || e.date.isAtSameMomentAs(cutoff),
    ).toList();

    if (windowFood.isEmpty) return null;
    final eInAvg = windowFood.fold(0.0, (s, e) => s + e.energyKcal) / windowFood.length;

    // TDEE_adaptive = E_in_avg − (ΔW_weekly × 7700 / 7)
    final adaptiveTDEE = eInAvg - (deltaWWeekly * 7700.0 / 7.0);

    // Sanity check: odrzuć nierealistyczne wartości
    if (adaptiveTDEE < 800 || adaptiveTDEE > 8000) return null;

    return adaptiveTDEE;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}

/// Wynik obliczeń silnika EWMA.
class EwmaResult {
  /// Wygładzona waga [kg] – ostatnia wartość szeregu EWMA
  /// (null jeśli brak wpisów wagowych)
  final double? smoothedWeight;

  /// Adaptacyjne TDEE [kcal] – obliczone z rzeczywistych danych
  /// (null w trakcie cold-startu lub braku danych kalorycznych)
  final double? adaptiveTDEE;

  /// True jeśli system jest w fazie cold-startu (<14 dni danych wagowych)
  final bool coldStartActive;

  /// Liczba dni w wygładzonej historii (z forward-fill brakujących dni)
  final int dayCount;

  /// Liczba rzeczywistych wpisów wagowych od użytkownika
  final int weightEntryCount;

  /// Pełna historia wygładzonych wartości [data → kg]
  final Map<DateTime, double>? smoothedHistory;

  const EwmaResult({
    required this.smoothedWeight,
    required this.adaptiveTDEE,
    required this.coldStartActive,
    required this.dayCount,
    required this.weightEntryCount,
    this.smoothedHistory,
  });

  /// Liczba dni pozostałych do zakończenia cold-startu
  int get coldStartDaysRemaining =>
      (EwmaEngine.coldStartDays - weightEntryCount).clamp(0, EwmaEngine.coldStartDays);

  @override
  String toString() =>
      'EwmaResult(smoothed:${smoothedWeight?.toStringAsFixed(2)}kg, '
      'adaptiveTDEE:${adaptiveTDEE?.toStringAsFixed(0)}kcal, '
      'coldStart:$coldStartActive, entries:$weightEntryCount)';
}
