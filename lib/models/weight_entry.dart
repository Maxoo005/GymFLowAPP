/// === WeightEntry ===
/// Pojedynczy wpis wagowy (raz dziennie).
/// Używany przez silnik EWMA do wygładzania wahań masy ciała
/// i obliczania rzeczywistego TDEE w trybie adaptacyjnym.
class WeightEntry {
  final DateTime date;
  final double weightKg;

  const WeightEntry({required this.date, required this.weightKg});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weightKg': weightKg,
  };

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
    date: DateTime.parse(j['date'] as String),
    weightKg: (j['weightKg'] as num).toDouble(),
  );

  @override
  String toString() => 'WeightEntry(${date.toIso8601String()}, ${weightKg}kg)';
}
