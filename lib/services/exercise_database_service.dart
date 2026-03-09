import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/exercise.dart';

class ExerciseDatabaseService {
  static const _dbName = 'exercises.db';
  static const _dbVersion = 1;
  static const _table = 'exercises';

  static ExerciseDatabaseService? _instance;
  static ExerciseDatabaseService get instance =>
      _instance ??= ExerciseDatabaseService._();
  ExerciseDatabaseService._();

  Database? _db;

  // ── Inicjalizacja ───────────────────────────────────────
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);

    _db = await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id        TEXT PRIMARY KEY,
        name      TEXT NOT NULL,
        muscleGroup TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        imageUrl  TEXT,
        isCustom  INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // Wstaw domyślne ćwiczenia
    final batch = db.batch();
    for (final ex in defaultExercises) {
      batch.insert(_table, _toMap(ex, isCustom: false));
    }
    await batch.commit(noResult: true);
  }

  // ── Pomocnicze ─────────────────────────────────────────
  Map<String, dynamic> _toMap(Exercise ex, {bool isCustom = true}) => {
        'id': ex.id,
        'name': ex.name,
        'muscleGroup': ex.muscleGroup.name,
        'description': ex.description,
        'imageUrl': ex.imageUrl,
        'isCustom': isCustom ? 1 : 0,
      };

  Exercise _fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as String,
        name: map['name'] as String,
        muscleGroup: MuscleGroup.values.byName(map['muscleGroup'] as String),
        description: (map['description'] as String?) ?? '',
        imageUrl: map['imageUrl'] as String?,
      );

  Database get _database {
    if (_db == null) throw StateError('ExerciseDatabaseService.init() nie zostało wywołane');
    return _db!;
  }

  // ── CRUD ───────────────────────────────────────────────
  Future<List<Exercise>> getAllExercises() async {
    final rows = await _database.query(_table, orderBy: 'name ASC');
    return rows.map(_fromMap).toList();
  }

  Future<void> addExercise(Exercise ex) async {
    await _database.insert(
      _table,
      _toMap(ex, isCustom: true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateExercise(Exercise ex) async {
    await _database.update(
      _table,
      _toMap(ex, isCustom: true),
      where: 'id = ?',
      whereArgs: [ex.id],
    );
  }

  Future<void> deleteExercise(String id) async {
    await _database.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Sprawdza czy ćwiczenie jest domyślne (nie można go usunąć)
  Future<bool> isCustom(String id) async {
    final rows = await _database.query(
      _table,
      columns: ['isCustom'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return false;
    return (rows.first['isCustom'] as int) == 1;
  }
}
