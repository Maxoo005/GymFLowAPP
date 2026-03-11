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
  Exercise(name: 'Wyciskanie hantli na ławce skosnej dodatniej', muscleGroup: MuscleGroup.chest, description: 'Kładzie nacisk na górną (obojczykową) część mięśni piersiowych [4, 8]'),
  Exercise(name: 'Rozpiętki z hantlami na ławce płaskiej', muscleGroup: MuscleGroup.chest, description: 'Ćwiczenie izolowane pozwalające na głębokie rozciągnięcie włókien mięśniowych klatki [5, 25]'),
  Exercise(name: 'Pompki na poręczach (Dips)', muscleGroup: MuscleGroup.chest, description: 'Złożony ruch angażujący dół klatki piersiowej i tricepsy; wymaga dużej siły bazowej [6, 26]'),
  Exercise(name: 'Butterfly (Pec Deck)', muscleGroup: MuscleGroup.chest, description: 'Maszyna izolująca mięśnie piersiowe; zapewnia stałe napięcie w całym zakresie ruchu [9, 11]'),
  Exercise(name: 'Wyciskanie hantli na ławce poziomej', muscleGroup: MuscleGroup.chest, description: 'Pozwala na większy zakres ruchu niż sztanga i wymaga stabilizacji każdej strony [4, 6]'),

  // PLECY (Back)
  Exercise(name: 'Martwy ciąg (Deadlift)', muscleGroup: MuscleGroup.back, description: 'Globalne ćwiczenie angażujące plecy, nogi i core; król budowania siły absolutnej [8, 13]'),
  Exercise(name: 'Podciąganie na drążku (Pull-ups)', muscleGroup: MuscleGroup.back, description: 'Najskuteczniejszy ruch budujący szerokość pleców (V-taper) [2, 13]'),
  Exercise(name: 'Wiosłowanie sztangą w opadzie', muscleGroup: MuscleGroup.back, description: 'Kluczowe ćwiczenie na grubość pleców; angażuje najszersze i czworoboczne [1, 14]'),
  Exercise(name: 'Ściąganie drążka wyciągu górnego', muscleGroup: MuscleGroup.back, description: 'Bezpieczna alternatywa dla podciągania, pozwalająca na precyzyjną izolację latsów [5, 27]'),
  Exercise(name: 'Wiosłowanie hantlem jednorącz', muscleGroup: MuscleGroup.back, description: 'Pozwala na korygowanie asymetrii i pracę w dużym zakresie ruchu [6, 15]'),
  Exercise(name: 'Przyciąganie linki wyciągu dolnego', muscleGroup: MuscleGroup.back, description: 'Skupia się na środkowej części pleców i retrakcji łopatek [5, 25]'),
  Exercise(name: 'Unoszenie tułowia na ławce rzymskiej', muscleGroup: MuscleGroup.back, description: 'Wzmacnia prostowniki grzbietu i dolny odcinek pleców [5, 16]'),

  // BARKI (Shoulders)
  Exercise(name: 'Wyciskanie żołnierskie (OHP)', muscleGroup: MuscleGroup.shoulders, description: 'Podstawowy ruch wertykalny budujący masę barków i stabilność core [1, 13]'),
  Exercise(name: 'Unoszenie hantli bokiem stojąc', muscleGroup: MuscleGroup.shoulders, description: 'Izolacja bocznego aktonu barku, kluczowa dla szerokości sylwetki [5, 6]'),
  Exercise(name: 'Wyciskanie hantli nad głowę siedząc', muscleGroup: MuscleGroup.shoulders, description: 'Pozwala na stabilną pracę nad siłą naramiennych bez udziału nóg [4, 8]'),
  Exercise(name: 'Unoszenie hantli w opadzie tułowia', muscleGroup: MuscleGroup.shoulders, description: 'Angażuje tylny akton barku, poprawiając postawę i zdrowie stawów [4, 5]'),
  Exercise(name: 'Arnoldki', muscleGroup: MuscleGroup.shoulders, description: 'Unikalna rotacja dłoni angażuje wszystkie trzy głowy mięśnia naramiennego [4, 5]'),
  Exercise(name: 'Podciąganie sztangi wzdłuż tułowia', muscleGroup: MuscleGroup.shoulders, description: 'Buduje boki barków oraz kaptury (mięśnie czworoboczne) [5, 25]'),
  Exercise(name: 'Face Pulls', muscleGroup: MuscleGroup.shoulders, description: 'Ćwiczenie korekcyjne i wzmacniające tył barku oraz rotator [3, 6]'),

  // NOGI I POŚLADKI (Legs / Glutes)
  Exercise(name: 'Przysiady ze sztangą na karku', muscleGroup: MuscleGroup.legs, description: 'Najważniejsze ćwiczenie nóg, angażuje czworogłowe, pośladki i brzuch [2, 8]'),
  Exercise(name: 'Hip Thrust ze sztangą', muscleGroup: MuscleGroup.legs, description: 'Bezkonkurencyjne ćwiczenie budujące masę i siłę mięśni pośladkowych [6, 8]'),
  Exercise(name: 'Wykroki z hantlami', muscleGroup: MuscleGroup.legs, description: 'Praca unilateralna poprawiająca stabilność i rzeźbę nóg [15, 16]'),
  Exercise(name: 'Rumuński martwy ciąg (RDL)', muscleGroup: MuscleGroup.legs, description: 'Koncentruje się na tylnej taśmie: dwugłowych ud i pośladkach [4, 13]'),
  Exercise(name: 'Wypychanie na suwnicy (Leg Press)', muscleGroup: MuscleGroup.legs, description: 'Pozwala na pracę z dużym obciążeniem przy odciążeniu kręgosłupa [5, 6]'),
  Exercise(name: 'Przysiad bułgarski', muscleGroup: MuscleGroup.legs, description: 'Intensywny wariant przysiadu na jednej nodze, kładzie nacisk na pośladki [4, 8]'),
  Exercise(name: 'Prostowanie nóg na maszynie', muscleGroup: MuscleGroup.legs, description: 'Czysta izolacja mięśni czworogłowych uda [5, 27]'),
  Exercise(name: 'Uginanie nóg leżąc/siedząc', muscleGroup: MuscleGroup.legs, description: 'Izolacja mięśni dwugłowych uda (hamstrings) [5, 27]'),
  Exercise(name: 'Wspięcia na palce stojąc', muscleGroup: MuscleGroup.legs, description: 'Podstawowe ćwiczenie budujące mięśnie łydek [5, 6]'),

  // RAMIONA (Biceps / Triceps)
  Exercise(name: 'Uginanie ramion ze sztangą', muscleGroup: MuscleGroup.biceps, description: 'Klasyk budujący masę bicepsów przy użyciu dużych ciężarów [1]'),
  Exercise(name: 'Uginanie ramion z hantlami (supinacja)', muscleGroup: MuscleGroup.biceps, description: 'Wykorzystuje pełną funkcję bicepsa, w tym skręt przedramienia [4, 8]'),
  Exercise(name: 'Uginanie młotkowe', muscleGroup: MuscleGroup.biceps, description: 'Angażuje mięsień ramienny i ramienno-promieniowy (grubość ramienia) [4, 25]'),
  Exercise(name: 'Wyciskanie francuskie leżąc', muscleGroup: MuscleGroup.triceps, description: 'Skutecznie buduje wszystkie głowy tricepsa, szczególnie długą [8, 15]'),
  Exercise(name: 'Prostowanie ramion na wyciągu górnym', muscleGroup: MuscleGroup.triceps, description: 'Stałe napięcie izolujące triceps; świetne na zakończenie treningu [1, 27]'),
  Exercise(name: 'Wyciskanie sztangi wąskim chwytem', muscleGroup: MuscleGroup.triceps, description: 'Złożony ruch pozwalający na użycie dużego ciężaru na tricepsy [4, 5]'),
  Exercise(name: 'Pompki diamentowe', muscleGroup: MuscleGroup.triceps, description: 'Wariant pompek silnie angażujący triceps przy użyciu masy ciała [4]'),

  // BRZUCH I CORE (Abs / Core)
  Exercise(name: 'Plank (Deska)', muscleGroup: MuscleGroup.abs, description: 'Statyczne wzmacnianie całego gorsetu mięśniowego i stabilności [2, 13]'),
  Exercise(name: 'Unoszenie nóg w zwisie', muscleGroup: MuscleGroup.abs, description: 'Zaawansowane ćwiczenie na dolne partie brzucha i mięśnie głębokie [4, 8]'),
  Exercise(name: 'Russian Twist (Rosyjski skręt)', muscleGroup: MuscleGroup.abs, description: 'Buduje siłę rotacyjną i rzeźbi mięśnie skośne brzucha [17, 19]'),
  Exercise(name: 'Allahy (Spięcia na wyciągu)', muscleGroup: MuscleGroup.abs, description: 'Pozwala na progresywne dociążenie mięśni brzucha (hipertrofia) [8, 27]'),
  Exercise(name: 'Ab Wheel Rollout', muscleGroup: MuscleGroup.abs, description: 'Ekstremalne wyzwanie dla stabilizacji core i siły brzucha [4, 6]'),
  Exercise(name: 'Dead Bug', muscleGroup: MuscleGroup.abs, description: 'Nauka kontroli kręgosłupa i miednicy poprzez ruchy kończyn [3]'),

  // CARDIO / WYTRZYMAŁOŚĆ
  Exercise(name: 'Bieganie na bieżni', muscleGroup: MuscleGroup.cardio, description: 'Najbardziej naturalna forma cardio; świetnie spala kalorie [20, 21]'),
  Exercise(name: 'Orbitrek (Trenażer eliptyczny)', muscleGroup: MuscleGroup.cardio, description: 'Efektywny trening całego ciała o niskim wpływie na stawy [21, 23]'),
  Exercise(name: 'Jazda na rowerze stacjonarnym', muscleGroup: MuscleGroup.cardio, description: 'Bezpieczne cardio budujące kondycję i wytrzymałość nóg [20, 24]'),
  Exercise(name: 'Wchodzenie po schodach (Stepper)', muscleGroup: MuscleGroup.cardio, description: 'Intensywny wysiłek budujący kondycję i rzeźbiący pośladki [21, 24]'),
  Exercise(name: 'Wioślarz (Ergometr)', muscleGroup: MuscleGroup.cardio, description: 'Kompleksowy trening angażujący plecy, nogi i układ krążenia [21, 28]'),
  Exercise(name: 'Skakanie na skakance', muscleGroup: MuscleGroup.cardio, description: 'Dynamiczny trening poprawiający koordynację i wydolność [20, 22]'),
];
