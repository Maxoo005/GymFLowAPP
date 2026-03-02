import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String name;
  int? age;
  double? heightCm;
  double? weightKg;
  String goal; // 'mass' | 'cut' | 'strength' | 'cardio'

  UserProfile({
    this.name = '',
    this.age,
    this.heightCm,
    this.weightKg,
    this.goal = 'strength',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'goal': goal,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] ?? '',
    age: j['age'],
    heightCm: (j['heightCm'] as num?)?.toDouble(),
    weightKg: (j['weightKg'] as num?)?.toDouble(),
    goal: j['goal'] ?? 'strength',
  );
}

class ProfileService {
  static const _key = 'user_profile';
  static ProfileService? _instance;
  static ProfileService get instance => _instance ??= ProfileService._();
  ProfileService._();

  UserProfile _profile = UserProfile();
  UserProfile get profile => _profile;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) _profile = UserProfile.fromJson(jsonDecode(raw));
  }

  Future<void> save(UserProfile p) async {
    _profile = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(p.toJson()));
  }
}
