import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ID powiadomień
  static const _timerNotifId = 0;
  static const _workoutNotifId = 1;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  // ── Powiadomienie o końcu przerwy ─────────────────────────
  Future<void> showTimerFinishedNotification({
    String title = 'Koniec przerwy!',
    String body = 'Czas wrócić do ćwiczeń. Dajesz!',
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Powiadomienia o końcu przerwy między seriami',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _timerNotifId,
      title,
      body,
      details,
    );
  }

  // ── Stałe powiadomienie o trwającym treningu (lock screen) ──
  /// Wyświetla / aktualizuje powiadomienie widoczne na ekranie blokady.
  /// [workoutName] – nazwa treningu
  /// [startTimestamp] – czas startu treningu (do chronometru)
  /// [exerciseCount] – ile ćwiczeń w treningu
  /// [setsDone] – ile serii ukończono
  Future<void> showWorkoutNotification({
    required String workoutName,
    required DateTime startTimestamp,
    int exerciseCount = 0,
    int setsDone = 0,
  }) async {
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      'workout_channel',
      'Aktywny trening',
      channelDescription: 'Powiadomienie wyświetlane podczas trwania treningu',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,             // nie można zamknąć gestem
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      showWhen: true,
      usesChronometer: true,     // systemowy timer
      when: startTimestamp.millisecondsSinceEpoch,
      visibility: NotificationVisibility.public, // widoczne na lock screenie
      category: AndroidNotificationCategory.workout,
      subText: 'GymLoom',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = '$exerciseCount ćw.  •  $setsDone serii ukończonych';

    await _notifications.show(
      _workoutNotifId,
      '🏋️ $workoutName',
      body,
      details,
    );
  }

  /// Kasuje powiadomienie o trwającym treningu.
  Future<void> cancelWorkoutNotification() async {
    await _notifications.cancel(_workoutNotifId);
  }
}

