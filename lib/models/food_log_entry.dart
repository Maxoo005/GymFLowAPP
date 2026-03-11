/// === FoodLogEntry ===
/// Dzienny wpis energetyczny (spożycie kalorii).
/// Używany przez silnik EWMA do obliczania rzeczywistego TDEE:
///   TDEE_adaptive = E_in_avg − (ΔW × 7700 / 7)
class FoodLogEntry {
  final DateTime date;
  final double energyKcal;

  const FoodLogEntry({required this.date, required this.energyKcal});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'energyKcal': energyKcal,
  };

  factory FoodLogEntry.fromJson(Map<String, dynamic> j) => FoodLogEntry(
    date: DateTime.parse(j['date'] as String),
    energyKcal: (j['energyKcal'] as num).toDouble(),
  );

  @override
  String toString() => 'FoodLogEntry(${date.toIso8601String()}, ${energyKcal}kcal)';
}
