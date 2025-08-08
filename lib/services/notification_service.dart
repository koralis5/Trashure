import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (!kIsWeb) {
      // Request permissions for iOS
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Handle notification taps - navigate to specific screens
  }

  Future<void> showNewListingNotification({
    required String title,
    required String sellerName,
    required double price,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'new_listings',
      'New Listings',
      channelDescription: 'Notifications for new marketplace listings',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🛍️ New Item Available',
      '$title - SGD \$${price.toStringAsFixed(2)} by $sellerName',
      notificationDetails,
      payload: 'new_listing',
    );
  }

  Future<void> showPickupReminderNotification({
    required String title,
    required String location,
    required String time,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pickup_reminders',
      'Pickup Reminders',
      channelDescription: 'Reminders for scheduled pickups',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '📅 Pickup Reminder',
      'Don\'t forget to pickup "$title" at $location ($time)',
      notificationDetails,
      payload: 'pickup_reminder',
    );
  }

  Future<void> showPaymentSuccessNotification({
    required String orderId,
    required double amount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'payments',
      'Payment Notifications',
      channelDescription: 'Payment success and failure notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '✅ Payment Successful',
      'Your payment of SGD \$${amount.toStringAsFixed(2)} was processed successfully. Order: $orderId',
      notificationDetails,
      payload: 'payment_success',
    );
  }

  Future<void> showChatMessageNotification({
    required String senderName,
    required String message,
    required String listingTitle,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'New chat messages from buyers and sellers',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '💬 New Message from $senderName',
      'About "$listingTitle": $message',
      notificationDetails,
      payload: 'chat_message',
    );
  }

  Future<void> schedulePickupReminder({
    required DateTime scheduledTime,
    required String title,
    required String location,
  }) async {
    // Schedule notification for 30 minutes before pickup
    final notificationTime = scheduledTime.subtract(const Duration(minutes: 30));

    if (notificationTime.isAfter(DateTime.now())) {
      const androidDetails = AndroidNotificationDetails(
        'scheduled_pickups',
        'Scheduled Pickup Reminders',
        channelDescription: 'Scheduled reminders for upcoming pickups',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        // Convert DateTime to TZDateTime for zonedSchedule
        final scheduledTZTime = tz.TZDateTime.from(notificationTime, tz.local);

        await _notifications.zonedSchedule(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          '⏰ Pickup in 30 minutes',
          'Remember to pickup "$title" at $location',
          scheduledTZTime,
          notificationDetails,
          payload: 'scheduled_pickup',
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        print('Error scheduling notification: $e');
        // Fallback to immediate notification for demo
        await showPickupReminderNotification(
          title: title,
          location: location,
          time: 'Now (Demo)',
        );
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}