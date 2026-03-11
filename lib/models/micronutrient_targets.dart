/// === MicronutrientTargets ===
/// Dzienne docelowe wartości mikroskładników stosowane w trybie GLP-1.
/// Agonisty GLP-1 znacznie ograniczają spożycie pokarmów, przez co
/// monitorowanie mikroskładników jest klinicznie konieczne.
///
/// Wartości referencyjne (DRI dla dorosłych):
///   - Wapń (Ca):     1000–1200 mg/dobę
///   - Żelazo (Fe):   8–18 mg/dobę (wyższy próg kobiety)
///   - Magnez (Mg):   310–420 mg/dobę
///   - Cynk (Zn):     8–11 mg/dobę
///   - Witamina D:    600–2000 IU/dobę
class MicronutrientTargets {
  /// Wapń [mg/dobę]
  final double calciumMg;

  /// Żelazo [mg/dobę]
  final double ironMg;

  /// Magnez [mg/dobę]
  final double magnesiumMg;

  /// Cynk [mg/dobę]
  final double zincMg;

  /// Witamina D [IU/dobę]
  final double vitaminDIu;

  const MicronutrientTargets({
    required this.calciumMg,
    required this.ironMg,
    required this.magnesiumMg,
    required this.zincMg,
    required this.vitaminDIu,
  });

  /// Domyślne wartości dla trybu GLP-1 (górna granica DRI)
  factory MicronutrientTargets.glp1Defaults({required bool isFemale}) {
    return MicronutrientTargets(
      calciumMg: 1200,           // Wyższy próg – leki mogą zaburzać wchłanianie Ca
      ironMg: isFemale ? 18 : 8, // Kobiety mają wyższe zapotrzebowanie
      magnesiumMg: isFemale ? 320 : 420,
      zincMg: isFemale ? 8 : 11,
      vitaminDIu: 2000,          // Agresywna suplementacja w przypadku GLP-1
    );
  }

  @override
  String toString() =>
      'MicronutrientTargets(Ca:${calciumMg}mg, Fe:${ironMg}mg, Mg:${magnesiumMg}mg, Zn:${zincMg}mg, D:${vitaminDIu}IU)';
}
