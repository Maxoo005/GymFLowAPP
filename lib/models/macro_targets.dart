/// === MacroTargets ===
/// Absolutne wartości makroskładników w gramach na dobę.
/// Silnik dietetyczny całkowicie porzuca programowanie procentowe
/// na rzecz bezwzględnych wartości g/kg masy ciała.
class MacroTargets {
  /// Białko [g/dobę]
  /// Norma: 1.6–2.4 g/kg całkowitej masy ciała (lub LBM przy otyłości BF% > 20%)
  final double proteinG;

  /// Tłuszcze [g/dobę]
  /// Minimum kliniczne: 0.5–0.8 g/kg masy ciała
  final double fatG;

  /// Węglowodany [g/dobę]
  /// Wypełniają pozostałą pulę kalorii po białku i tłuszczach
  final double carbsG;

  /// Błonnik [g/dobę]
  /// Minimum: 14 g / 1000 kcal diety
  final double fiberG;

  const MacroTargets({
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.fiberG,
  });

  /// Całkowita energia z makroskładników [kcal]
  double get totalKcal => proteinG * 4 + carbsG * 4 + fatG * 9;

  /// Udział procentowy białka (tylko do celów informacyjnych, NIE do obliczania)
  double get proteinPct => totalKcal > 0 ? (proteinG * 4 / totalKcal * 100) : 0;
  double get fatPct     => totalKcal > 0 ? (fatG * 9 / totalKcal * 100) : 0;
  double get carbsPct   => totalKcal > 0 ? (carbsG * 4 / totalKcal * 100) : 0;

  @override
  String toString() =>
      'MacroTargets(P:${proteinG.toStringAsFixed(0)}g, F:${fatG.toStringAsFixed(0)}g, C:${carbsG.toStringAsFixed(0)}g, Fiber:${fiberG.toStringAsFixed(0)}g)';
}
