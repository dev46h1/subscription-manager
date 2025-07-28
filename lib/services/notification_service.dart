import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/subscription.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._init();
  factory NotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  NotificationService._init();

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
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
      
      final result = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      if (result == true) {
        await _createNotificationChannel();
        _isInitialized = true;
        print('Notifications initialized successfully');
      } else {
        print('Notification initialization failed');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'subscription_reminders',
      'Subscription Reminders',
      description: 'Notifications for subscription renewals',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - you can navigate to specific screen here
  }

 Future<void> scheduleNotification(Subscription subscription) async {
  if (!_isInitialized) {
    print('NotificationService not initialized');
    return;
  }

  try {
    final subscriptionId = subscription.id ?? 0;
    
    // Cancel any existing notifications for this subscription
    await cancelNotification(subscriptionId);
    
    // Use consistent date calculation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final renewalDate = DateTime(
      subscription.renewalDate.year,
      subscription.renewalDate.month,
      subscription.renewalDate.day,
    );
    
    final daysUntilRenewal = renewalDate.difference(today).inDays;
    
    // Handle notification 1 day before renewal
    final oneDayBefore = renewalDate.subtract(const Duration(days: 1));
    
    if (daysUntilRenewal == 1) {
      // If renewal is tomorrow, show notification immediately
      await _showImmediateNotification(
        id: subscriptionId * 10 + 1,
        title: 'Subscription Renewal Tomorrow',
        body: '${subscription.name} will renew tomorrow for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
        payload: 'subscription_${subscription.id}_1day',
      );
      print('Showed immediate 1-day reminder for ${subscription.name}');
    } else if (daysUntilRenewal > 1) {
      // If renewal is more than 1 day away, schedule the 1-day reminder
      final oneDayBeforeTime = DateTime(
        oneDayBefore.year,
        oneDayBefore.month,
        oneDayBefore.day,
        9, // 9 AM
        0,
      );
      
      await _scheduleNotificationAt(
        id: subscriptionId * 10 + 1,
        scheduledDate: oneDayBeforeTime,
        title: 'Subscription Renewal Tomorrow',
        body: '${subscription.name} will renew tomorrow for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
        payload: 'subscription_${subscription.id}_1day',
      );
      print('Scheduled 1-day reminder for ${subscription.name} at $oneDayBeforeTime');
    }
    
    // Handle notification on renewal day
    if (daysUntilRenewal == 0) {
      // If renewal is today, show notification immediately
      await _showImmediateNotification(
        id: subscriptionId * 10 + 2,
        title: 'Subscription Renewing Today',
        body: '${subscription.name} is renewing today for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
        payload: 'subscription_${subscription.id}_today',
      );
      print('Showed immediate renewal day reminder for ${subscription.name}');
    } else if (daysUntilRenewal > 0) {
      // If renewal day hasn't arrived yet, schedule it for 9 AM
      final renewalDayMorning = DateTime(
        renewalDate.year,
        renewalDate.month,
        renewalDate.day,
        9, // 9 AM
        0,
      );
      
      await _scheduleNotificationAt(
        id: subscriptionId * 10 + 2,
        scheduledDate: renewalDayMorning,
        title: 'Subscription Renewing Today',
        body: '${subscription.name} is renewing today for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
        payload: 'subscription_${subscription.id}_today',
      );
      print('Scheduled renewal day reminder for ${subscription.name} at $renewalDayMorning');
    }
    
  } catch (e) {
    print('Error scheduling notification for ${subscription.name}: $e');
  }
}

  Future<void> _showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'subscription_reminders',
        'Subscription Reminders',
        channelDescription: 'Notifications for subscription renewals',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(body),
        category: AndroidNotificationCategory.reminder,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'subscription_reminder',
      );
      
      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(id, title, body, details, payload: payload);
      print('Immediate notification shown with ID: $id');
    } catch (e) {
      print('Error showing immediate notification: $e');
    }
  }

  Future<void> _scheduleNotificationAt({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'subscription_reminders',
        'Subscription Reminders',
        channelDescription: 'Notifications for subscription renewals',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(body),
        category: AndroidNotificationCategory.reminder,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'subscription_reminder',
      );
      
      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      print('Notification scheduled with ID: $id for $scheduledTZDate');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> checkAndScheduleAllNotifications(List<Subscription> subscriptions) async {
    if (!_isInitialized) {
      print('NotificationService not initialized, skipping notification scheduling');
      return;
    }

    try {
      print('Scheduling notifications for ${subscriptions.length} subscriptions');
      
      for (var subscription in subscriptions) {
        await scheduleNotification(subscription);
      }
      
      // Print pending notifications for debugging
      await _printPendingNotifications();
    } catch (e) {
      print('Error in checkAndScheduleAllNotifications: $e');
    }
  }

  Future<void> scheduleAllNotificationsQuietly(List<Subscription> subscriptions) async {
    if (!_isInitialized) {
      print('NotificationService not initialized, skipping notification scheduling');
      return;
    }

    try {
      print('Quietly scheduling notifications for ${subscriptions.length} subscriptions');
      
      for (var subscription in subscriptions) {
        await _scheduleNotificationQuietly(subscription);
      }
      
      // Print pending notifications for debugging
      await _printPendingNotifications();
    } catch (e) {
      print('Error in scheduleAllNotificationsQuietly: $e');
    }
  }

  Future<void> _scheduleNotificationQuietly(Subscription subscription) async {
  if (!_isInitialized) {
    print('NotificationService not initialized');
    return;
  }

  try {
    final subscriptionId = subscription.id ?? 0;
    
    // Cancel any existing notifications for this subscription
    await cancelNotification(subscriptionId);
    
    // Use consistent date calculation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final renewalDate = DateTime(
      subscription.renewalDate.year,
      subscription.renewalDate.month,
      subscription.renewalDate.day,
    );
    
    final daysUntilRenewal = renewalDate.difference(today).inDays;
    
    // Schedule notification 1 day before renewal (only if it's in the future)
    if (daysUntilRenewal > 1) {
      final oneDayBefore = renewalDate.subtract(const Duration(days: 1));
      final oneDayBeforeTime = DateTime(
        oneDayBefore.year,
        oneDayBefore.month,
        oneDayBefore.day,
        9, // 9 AM
        0,
      );
      
      await _scheduleNotificationAt(
        id: subscriptionId * 10 + 1,
        scheduledDate: oneDayBeforeTime,
        title: 'Subscription Renewal Tomorrow',
        body: '${subscription.name} will renew tomorrow for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
        payload: 'subscription_${subscription.id}_1day',
      );
      print('Quietly scheduled 1-day reminder for ${subscription.name} at $oneDayBeforeTime');
    }
    
    // Schedule notification on renewal day (only if it's in the future)
    if (daysUntilRenewal > 0) {
      final renewalDayMorning = DateTime(
        renewalDate.year,
        renewalDate.month,
        renewalDate.day,
        9, // 9 AM
        0,
      );
      
      await _scheduleNotificationAt(
        id: subscriptionId * 10 + 2,
        scheduledDate: renewalDayMorning,
        title: 'Subscription Renewing Today',
        body: '${subscription.name} is renewing today for ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
        payload: 'subscription_${subscription.id}_today',
      );
      print('Quietly scheduled renewal day reminder for ${subscription.name} at $renewalDayMorning');
    }
    
  } catch (e) {
    print('Error quietly scheduling notification for ${subscription.name}: $e');
  }
}

  Future<void> _printPendingNotifications() async {
    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      print('Pending notifications: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        print('ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
      }
    } catch (e) {
      print('Error getting pending notifications: $e');
    }
  }

  Future<void> cancelNotification(int subscriptionId) async {
    try {
      // Cancel both 1-day and same-day notifications for this subscription
      await _notifications.cancel(subscriptionId * 10 + 1);
      await _notifications.cancel(subscriptionId * 10 + 2);
      print('Cancelled notifications for subscription ID: $subscriptionId');
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  // Method to request notification permissions (especially for Android 13+)
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        print('Notification permission granted: $granted');
        return granted ?? false;
      }
      
      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('iOS notification permission granted: $granted');
        return granted ?? false;
      }
      
      return true;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Method to check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? false;
      }
      
      return true; // Assume enabled for other platforms
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }
}