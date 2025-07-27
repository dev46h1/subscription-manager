import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/subscription.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._init();
  factory NotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  NotificationService._init();

  Future<void> init() async {
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
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to specific screen here
  }

  Future<void> scheduleNotification(Subscription subscription) async {
    final daysUntil = subscription.daysUntilRenewal;
    
    // Cancel any existing notifications for this subscription
    await _notifications.cancel(subscription.id ?? 0);
    
    if (daysUntil == 1 || daysUntil == 2) {
      await _showNotification(
        id: subscription.id ?? 0,
        title: 'Subscription Renewal Reminder',
        body: '${subscription.name} will renew in $daysUntil day${daysUntil == 1 ? '' : 's'} for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
      );
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'subscription_reminders',
      'Subscription Reminders',
      channelDescription: 'Notifications for subscription renewals',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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
    
    await _notifications.show(id, title, body, details);
  }

  Future<void> checkAndScheduleAllNotifications(List<Subscription> subscriptions) async {
    for (var subscription in subscriptions) {
      await scheduleNotification(subscription);
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}