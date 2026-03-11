/// === ClinicalAlert ===
/// Alert kliniczny generowany przez moduł ClinicalGuard.
/// Może wskazywać na ryzyko RED-S lub konieczność zastosowania
/// protokołu "Diet Break".

enum ClinicalAlertType {
  /// Relative Energy Deficiency in Sport – chroniczny niedobór energii
  reds,
  /// Protokół przerwy dietetycznej – podniesienie kalorii do poziomu TDEE
  dietBreak,
}

class ClinicalAlert {
  final ClinicalAlertType type;
  final String message;
  final String recommendation;

  const ClinicalAlert({
    required this.type,
    required this.message,
    required this.recommendation,
  });

  bool get isCritical => type == ClinicalAlertType.reds;

  @override
  String toString() => 'ClinicalAlert(${type.name}): $message';
}
