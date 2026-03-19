import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/router/app_router.dart';
import '../models/memory_entry.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    try {
      const platform = MethodChannel('com.remi.remi/timezone');
      final String timeZoneName = await platform.invokeMethod('getTimeZoneName');
      debugPrint('NotificationService: Local timezone detected: $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: Timezone detection failed, using fallback Europe/Berlin. Error: $e');
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }
    
    // Request permissions early for Android 13+ and iOS
    await requestPermissions();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'quick_record' || response.actionId == 'quick_record') {
          _handleQuickRecordIntent();
        } else if (response.payload == 'daily_wrap') {
          _handleDailyWrapIntent();
        }
      },
    );

    // Request permissions for Android 13+
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      // On Android 13+, exact alarms require special permission handling
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  void _handleQuickRecordIntent() {
    AppRouter.router.push('/?quick=true');
  }

  void _handleDailyWrapIntent() {
    AppRouter.router.push('/evening_wrap');
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'remi_echoes',
          'Remi Impulse',
          channelDescription: 'Proaktive Erinnerungen und tÃ¤gliche Zusammenfassungen',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF10B981),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,summaryText: 'Speech Healing',
          ),
          actions: [
            const AndroidNotificationAction(
              'quick_record',
              'Schnell-Notiz',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'quick_record_category',
        ),
      ),
      payload: 'quick_record',
    );
  }

  Future<void> scheduleDailyNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'remi_daily_wrap',
          'Tagesabschluss',
          channelDescription: 'Zusammenfassungen am Abend',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF10B981),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,summaryText: 'Speech Healing',
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'daily_wrap',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleNudge({
    required int id,
    required String title,
    required String body,
    required int delayInHours,
  }) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(hours: delayInHours));
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'remi_nudges',
          'Erinnerungen',
          channelDescription: 'Sanfte Erinnerungen an offene Aufgaben',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF10B981),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,summaryText: 'Speech Healing',
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleSpecificNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'remi_nudges',
          'Erinnerungen',
          channelDescription: 'Sanfte Erinnerungen an offene Aufgaben',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF10B981),
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,summaryText: 'Speech Healing',
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Scheduled a precise reminder for a specific MemoryEntry.
  /// Used for "Erinnere mich um 14 Uhr" style prompts.
  Future<void> scheduleMemoryReminder(MemoryEntry entry) async {
    if (entry.id == null || entry.remindAt == null) {
      debugPrint('NotificationService: Skip schedule (missing info)');
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime.from(entry.remindAt!, tz.local);
    
    tz.TZDateTime finalDate = scheduledDate;

    if (finalDate.isBefore(now)) {
      final diff = now.difference(finalDate);
      if (diff.inMinutes < 5) {
        // AI was slow, or user said "now". Fire in 5 seconds.
        debugPrint('NotificationService: Target time passed slightly (${diff.inSeconds}s ago), rescheduling to +5s for safety');
        finalDate = now.add(const Duration(seconds: 5));
      } else {
        debugPrint('NotificationService: Skip schedule (too far in past: ${diff.inMinutes}m)');
        return;
      }
    }

    debugPrint('NotificationService: Scheduling at $finalDate (local: ${tz.local})');

    try {
      final body = entry.spinoNotification ?? 'Tippe hier, um deinen Gedanken zu sehen.';
      final title = entry.spinoNotification != null ? 'Remi' : 'Erinnerung: ${entry.summary}';

      await _notificationsPlugin.zonedSchedule(
        entry.id!,
        title,
        body,
        finalDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'remi_reminders',
            'Geplante Erinnerungen',
            channelDescription: 'PrÃ¤zise Alarme fÃ¼r deine Aufgaben',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: Color(0xFF10B981),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'memory_${entry.id}',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('NotificationService: ZonedSchedule call finished');
    } catch (e) {
      debugPrint('NotificationService ERROR: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}


