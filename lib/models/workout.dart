import 'package:uuid/uuid.dart';

// ── Pojedyncza seria ─────────────────────────────────────────
class SetEntry {
  int reps;
  double weight; // kg
  int difficulty; // 1–5
  bool isDone; // Transient: czy seria została wykonana podczs treningu

  SetEntry({
    this.reps = 10,
    this.weight = 0,
    this.difficulty = 3,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
    'reps': reps,
    'weight': weight,
    'difficulty': difficulty,
    'isDone': isDone,
  };

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
    reps: json['reps'] ?? 10,
    weight: (json['weight'] ?? 0).toDouble(),
    difficulty: json['difficulty'] ?? 3,
    isDone: json['isDone'] ?? false,
  );

  SetEntry copyWith({int? reps, double? weight, int? difficulty, bool? isDone}) => SetEntry(
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
    difficulty: difficulty ?? this.difficulty,
    isDone: isDone ?? this.isDone,
  );
}

// ── Ćwiczenie w sesji treningowej ────────────────────────────
class WorkoutSet {
  final String exerciseId;
  final String exerciseName;
  List<SetEntry> entries; // każda seria jako osobny obiekt

  /// Jeśli started z planu – ID ćwiczenia z planu (exerciseId z PlanExercise).
  /// Jeśli null lub różne od exerciseId → ćwiczenie zamienione → nie zapamiętujemy.
  final String? planExerciseId;

  int restSeconds; // Nowe pole: czas przerwy po serii (w sekundach)

  /// Partia ciała – opcjonalne, zapisywane przy tworzeniu z bazy ćwiczeń
  final String? muscleGroupName;

  WorkoutSet({
    required this.exerciseId,
    required this.exerciseName,
    List<SetEntry>? entries,
    this.planExerciseId,
    this.restSeconds = 60,
    this.muscleGroupName,
  }) : entries = entries ?? [SetEntry(), SetEntry()]; // domyślnie 2 serie

  /// Czy to oryginalne ćwiczenie z planu (nie zamienione)
  bool get isOriginalPlanExercise =>
      planExerciseId != null && planExerciseId == exerciseId;

  // Legacy gettery dla kompatybilności ze statystykami
  int get sets => entries.length;
  int get reps => entries.isEmpty ? 0 : entries.first.reps;
  double get weight => entries.isEmpty ? 0 : entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b);

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'entries': entries.map((e) => e.toJson()).toList(),
    if (planExerciseId != null) 'planExerciseId': planExerciseId,
    'restSeconds': restSeconds,
    if (muscleGroupName != null) 'muscleGroupName': muscleGroupName,
  };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    // Obsługa starszego formatu (sets/reps/weight)
    if (json.containsKey('entries')) {
      return WorkoutSet(
        exerciseId: json['exerciseId'],
        exerciseName: json['exerciseName'],
        entries: (json['entries'] as List).map((e) => SetEntry.fromJson(e)).toList(),
        planExerciseId: json['planExerciseId'],
        restSeconds: json['restSeconds'] ?? 60,
        muscleGroupName: json['muscleGroupName'] as String?,
      );
    } else {
      // Stary format – konwertuj
      final sets = json['sets'] ?? 3;
      final reps = json['reps'] ?? 10;
      final weight = (json['weight'] ?? 0).toDouble();
      return WorkoutSet(
        exerciseId: json['exerciseId'],
        exerciseName: json['exerciseName'],
        entries: List.generate(sets, (_) => SetEntry(reps: reps, weight: weight)),
        restSeconds: 60,
      );
    }
  }
}


// ── Sesja treningowa ─────────────────────────────────────────
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
    0.0, (sum, e) => sum + e.entries.fold(0.0, (s, se) => s + se.weight * se.reps),
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

// ── Plan treningowy ──────────────────────────────────────────
class WorkoutPlan {
  final String id;
  String name;
  List<PlanExercise> exercises;
  DateTime createdAt;

  WorkoutPlan({
    String? id,
    required this.name,
    List<PlanExercise>? exercises,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        exercises = exercises ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
    id: json['id'],
    name: json['name'],
    exercises: (json['exercises'] as List).map((e) => PlanExercise.fromJson(e)).toList(),
    createdAt: DateTime.parse(json['createdAt']),
  );

  /// Konwertuj plan na WorkoutSet-y gotowe do treningu.
  /// [memory] – opcjonalne zapamiętane serie: exerciseId -> List<SetEntry>
  List<WorkoutSet> toWorkoutSets({Map<String, List<SetEntry>>? memory}) =>
      exercises.map((e) {
        final remembered = memory?[e.exerciseId];
        return WorkoutSet(
          exerciseId: e.exerciseId,
          exerciseName: e.exerciseName,
          planExerciseId: e.exerciseId,
          restSeconds: e.restSeconds,
          muscleGroupName: e.muscleGroupName,
          entries: remembered != null
              ? remembered.map((s) => SetEntry(reps: s.reps, weight: s.weight, difficulty: s.difficulty)).toList()
              : [SetEntry(), SetEntry()],
        );
      }).toList();
}

// ── Ćwiczenie w planie ───────────────────────────────────────
class PlanExercise {
  final String exerciseId;
  final String exerciseName;
  int defaultSets;
  int defaultReps;
  int restSeconds;
  final String? muscleGroupName;

  PlanExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.restSeconds = 60,
    this.muscleGroupName,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'defaultSets': defaultSets,
    'defaultReps': defaultReps,
    'restSeconds': restSeconds,
    if (muscleGroupName != null) 'muscleGroupName': muscleGroupName,
  };

  factory PlanExercise.fromJson(Map<String, dynamic> json) => PlanExercise(
    exerciseId: json['exerciseId'],
    exerciseName: json['exerciseName'],
    defaultSets: json['defaultSets'] ?? 3,
    defaultReps: json['defaultReps'] ?? 10,
    restSeconds: json['restSeconds'] ?? 60,
    muscleGroupName: json['muscleGroupName'] as String?,
  );
}
