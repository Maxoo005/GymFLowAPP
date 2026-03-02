import 'package:uuid/uuid.dart';

class WorkoutSet {
  final String exerciseId;
  final String exerciseName;
  int reps;
  double weight; // w kg
  int sets;

  WorkoutSet({
    required this.exerciseId,
    required this.exerciseName,
    this.reps = 10,
    this.weight = 0,
    this.sets = 3,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'reps': reps,
    'weight': weight,
    'sets': sets,
  };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    exerciseId: json['exerciseId'],
    exerciseName: json['exerciseName'],
    reps: json['reps'] ?? 10,
    weight: (json['weight'] ?? 0).toDouble(),
    sets: json['sets'] ?? 3,
  );
}

class Workout {
  final String id;
  String name;
  DateTime date;
  List<WorkoutSet> exercises;
  int durationMinutes;
  String? notes;

  Workout({
    String? id,
    required this.name,
    DateTime? date,
    List<WorkoutSet>? exercises,
    this.durationMinutes = 0,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        exercises = exercises ?? [];

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);
  double get totalVolume => exercises.fold(
    0.0, (sum, e) => sum + e.weight * e.reps * e.sets,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'durationMinutes': durationMinutes,
    'notes': notes,
  };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'],
    name: json['name'],
    date: DateTime.parse(json['date']),
    exercises: (json['exercises'] as List).map((e) => WorkoutSet.fromJson(e)).toList(),
    durationMinutes: json['durationMinutes'] ?? 0,
    notes: json['notes'],
  );
}
