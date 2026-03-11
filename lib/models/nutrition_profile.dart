/// === NutritionProfile ===
/// Kompletny profil użytkownika wymagany przez silnik żywieniowy.
/// Zawiera dane antropometryczne, pomiary ciała (wzór U.S. Navy),
/// cel treningowy oraz flagi kliniczne.
class NutritionProfile {
  String sex;           // 'male' | 'female'
  String activityLevel; // 'sedentary' | 'light' | 'moderate' | 'active' | 'veryActive'
  String goal;          // 'bulk' | 'cut' | 'strength' | 'cardio'

  // Dane antropometryczne
  double? weightKg;
  double? heightCm;
  int? age;

  // Opcjonalne pomiary do wzoru U.S. Navy BF%
  // Mężczyźni: talita + szyja; Kobiety: talita + szyja + biodra
  double? waistCm;
  double? neckCm;
  double? hipCm; // Tylko kobiety

  // BF% wpisany ręcznie przez użytkownika lub sportowca
  double? bodyFatPercent;

  // Flaga kliniczna – tryb GLP-1 (leki na otyłość)
  bool isGlp1Mode;

  NutritionProfile({
    this.sex = 'male',
    this.activityLevel = 'moderate',
    this.goal = 'strength',
    this.weightKg,
    this.heightCm,
    this.age,
    this.waistCm,
    this.neckCm,
    this.hipCm,
    this.bodyFatPercent,
    this.isGlp1Mode = false,
  });

  Map<String, dynamic> toJson() => {
    'sex': sex,
    'activityLevel': activityLevel,
    'goal': goal,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'age': age,
    'waistCm': waistCm,
    'neckCm': neckCm,
    'hipCm': hipCm,
    'bodyFatPercent': bodyFatPercent,
    'isGlp1Mode': isGlp1Mode,
  };

  factory NutritionProfile.fromJson(Map<String, dynamic> j) => NutritionProfile(
    sex: j['sex'] as String? ?? 'male',
    activityLevel: j['activityLevel'] as String? ?? 'moderate',
    goal: j['goal'] as String? ?? 'strength',
    weightKg: (j['weightKg'] as num?)?.toDouble(),
    heightCm: (j['heightCm'] as num?)?.toDouble(),
    age: j['age'] as int?,
    waistCm: (j['waistCm'] as num?)?.toDouble(),
    neckCm: (j['neckCm'] as num?)?.toDouble(),
    hipCm: (j['hipCm'] as num?)?.toDouble(),
    bodyFatPercent: (j['bodyFatPercent'] as num?)?.toDouble(),
    isGlp1Mode: j['isGlp1Mode'] as bool? ?? false,
  );
}
