/// Model danych ankiety żywieniowej użytkownika
class NutritionProfile {
  String sex;           // 'male' | 'female'
  String activityLevel; // 'sedentary' | 'light' | 'moderate' | 'active' | 'veryActive'

  NutritionProfile({
    this.sex = 'male',
    this.activityLevel = 'moderate',
  });

  Map<String, dynamic> toJson() => {
    'sex': sex,
    'activityLevel': activityLevel,
  };

  factory NutritionProfile.fromJson(Map<String, dynamic> j) => NutritionProfile(
    sex: j['sex'] as String? ?? 'male',
    activityLevel: j['activityLevel'] as String? ?? 'moderate',
  );
}

/// Wynik obliczeń kalorii i makroskładników
class NutritionResult {
  final int calories;    // kcal/dzień
  final int protein;     // g/dzień
  final int carbs;       // g/dzień
  final int fat;         // g/dzień
  final double bmr;      // kcal – podstawowa przemiana materii
  final double tdee;     // kcal – TDEE przed korektą celu

  const NutritionResult({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.bmr,
    required this.tdee,
  });
}
