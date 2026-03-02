import 'package:uuid/uuid.dart';

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  legs,
  abs,
  cardio,
  fullBody,
}

extension MuscleGroupExt on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:    return 'Klatka piersiowa';
      case MuscleGroup.back:     return 'Plecy';
      case MuscleGroup.shoulders: return 'Barki';
      case MuscleGroup.biceps:   return 'Biceps';
      case MuscleGroup.triceps:  return 'Triceps';
      case MuscleGroup.legs:     return 'Nogi';
      case MuscleGroup.abs:      return 'Brzuch';
      case MuscleGroup.cardio:   return 'Cardio';
      case MuscleGroup.fullBody: return 'Całe ciało';
    }
  }
}

class Exercise {
  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final String description;
  final String? imageUrl;

  Exercise({
    String? id,
    required this.name,
    required this.muscleGroup,
    this.description = '',
    this.imageUrl,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'muscleGroup': muscleGroup.name,
    'description': description,
    'imageUrl': imageUrl,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'],
    name: json['name'],
    muscleGroup: MuscleGroup.values.byName(json['muscleGroup']),
    description: json['description'] ?? '',
    imageUrl: json['imageUrl'],
  );
}

// ── Przykładowe ćwiczenia ────────────────────────────────
final List<Exercise> defaultExercises = [
  Exercise(name: 'Wyciskanie sztangi na ławce',  muscleGroup: MuscleGroup.chest,    description: 'Klasyczne ćwiczenie na klatkę piersiową'),
  Exercise(name: 'Rozpiętki ze sztangielkami',   muscleGroup: MuscleGroup.chest,    description: 'Izolacja klatki piersiowej'),
  Exercise(name: 'Martwy ciąg',                  muscleGroup: MuscleGroup.back,     description: 'Złożone ćwiczenie angażujące plecy i nogi'),
  Exercise(name: 'Podciąganie na drążku',        muscleGroup: MuscleGroup.back,     description: 'Szerokie plecy i obszerny zakres ruchu'),
  Exercise(name: 'Wiosłowanie sztangą',          muscleGroup: MuscleGroup.back,     description: 'Grubość pleców'),
  Exercise(name: 'Wyciskanie żołnierskie',       muscleGroup: MuscleGroup.shoulders, description: 'Barki + triceps'),
  Exercise(name: 'Uginanie ramion ze sztangielkami', muscleGroup: MuscleGroup.biceps, description: 'Klasyczne na biceps'),
  Exercise(name: 'Prostowanie ramion na wyciągu', muscleGroup: MuscleGroup.triceps, description: 'Izolacja tricepsa'),
  Exercise(name: 'Przysiady ze sztangą',         muscleGroup: MuscleGroup.legs,     description: 'Król ćwiczeń na nogi'),
  Exercise(name: 'Wykroki z hantlami',           muscleGroup: MuscleGroup.legs,     description: 'Czworogłowe + pośladki'),
  Exercise(name: 'Plank',                        muscleGroup: MuscleGroup.abs,      description: 'Stabilizacja core'),
  Exercise(name: 'Bieganie',                     muscleGroup: MuscleGroup.cardio,   description: 'Cardio / wytrzymałość'),
];
