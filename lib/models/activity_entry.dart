/// === ActivityEntry ===
/// Pojedyncza sesja aktywności fizycznej.
/// Używana przez ActivityCalculator do obliczania EEE (Exercise Energy Expenditure)
/// za pomocą równoważników metabolicznych (MET):
///
///   EEE [kcal] = durationMin × (MET × 3.5 × weightKg) / 200
///
/// Przykładowe wartości MET:
///   - Trening siłowy umiarkowany: 5.0
///   - Trening siłowy intensywny: 6.0
///   - Bieg (10 km/h): 10.0
///   - Rower stacjonarny umiarkowany: 7.0
///   - Spacer (5 km/h): 3.5
class ActivityEntry {
  final DateTime date;
  final double met;
  final double durationMin;
  final String? label; // Opcjonalny opis aktywności (np. "Trening siłowy")

  const ActivityEntry({
    required this.date,
    required this.met,
    required this.durationMin,
    this.label,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'met': met,
    'durationMin': durationMin,
    'label': label,
  };

  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry(
    date: DateTime.parse(j['date'] as String),
    met: (j['met'] as num).toDouble(),
    durationMin: (j['durationMin'] as num).toDouble(),
    label: j['label'] as String?,
  );

  @override
  String toString() => 'ActivityEntry(${label ?? 'Activity'}, MET=$met, ${durationMin}min)';
}
