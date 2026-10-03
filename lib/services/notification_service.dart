import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/subscription.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'renewal_reminders';
  static const String _channelName = 'Renewal Reminders';
  static const String _channelDescription =
      'Reminds you before a subscription renews.';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Timezone setup
    tz.initializeTimeZones();
    try {
      final String localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (e) {
      debugPrint('TZ ERROR: $e — falling back to UTC');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Platform init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('NOTIF TAPPED: ${response.payload}');
      },
    );

    // 3. Create Android channel
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );
    }

    _initialized = true;
  }

  /// Request POST_NOTIFICATIONS (Android 13+) and exact alarm (Android 14+).
  /// Call this only when the user enables reminders for the first time.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final granted = await android?.requestNotificationsPermission() ?? false;

      // Ask for exact-alarm special access; if denied we fall back to inexact.
      await android?.requestExactAlarmsPermission();

      return granted;
    }

    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }

    return false;
  }

  /// Deterministic notification id so we can cancel/update the same one.
  int _notificationIdFor(String documentId) => documentId.hashCode & 0x7fffffff;

  /// Schedule (or reschedule) a reminder for [subscription].
  /// Fires [leadTimeDays] before its renewal date at [hour]:[minute].
  Future<void> scheduleRenewalReminder({
    required String documentId,
    required Subscription subscription,
    required int leadTimeDays,
    required int hour,
    required int minute,
  }) async {
    await init();

    final id = _notificationIdFor(documentId);

    // Always cancel the old one first so we don't stack duplicates.
    await _plugin.cancel(id);

    if (!subscription.isActive) return;

    final fireDate = _nextReminderDateTime(
      renewalDate: subscription.renewalDate,
      leadTimeDays: leadTimeDays,
      hour: hour,
      minute: minute,
    );

    // If the fire date is in the past, skip.
    if (fireDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('REMINDER SKIP: $documentId — fire date in past');
      return;
    }

    try {
      await _plugin.zonedSchedule(
        id,
        '🔔 ${subscription.name} renews soon',
        _buildBody(subscription, leadTimeDays),
        fireDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: documentId,
      );

      debugPrint('REMINDER SCHEDULED: $documentId at $fireDate');
    } catch (e) {
      debugPrint('REMINDER ERROR for $documentId: $e');
    }
  }

  Future<void> cancelReminder(String documentId) async {
    await _plugin.cancel(_notificationIdFor(documentId));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ===== Helpers =====

  tz.TZDateTime _nextReminderDateTime({
    required DateTime renewalDate,
    required int leadTimeDays,
    required int hour,
    required int minute,
  }) {
    final reminderDay = renewalDate.subtract(Duration(days: leadTimeDays));

    return tz.TZDateTime(
      tz.local,
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      hour,
      minute,
    );
  }

  String _buildBody(Subscription subscription, int leadTimeDays) {
    final plan = subscription.planName.isNotEmpty
        ? ' (${subscription.planName})'
        : '';
    final when = leadTimeDays == 0
        ? 'today'
        : leadTimeDays == 1
        ? 'tomorrow'
        : 'in $leadTimeDays days';
    return '${subscription.name}$plan renews $when. '
        'Open SubTrack to review before you\'re charged.';
  }
}
