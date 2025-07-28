import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  
  List<Subscription> get subscriptions {
    // Sort by days until renewal (ascending)
    _subscriptions.sort((a, b) => a.daysUntilRenewal.compareTo(b.daysUntilRenewal));
    return _subscriptions;
  }

  bool get isLoading => _isLoading;

  double get totalMonthlySpend {
    double total = 0;
    for (var sub in _subscriptions) {
      // Convert to USD for calculation (you might want to add real conversion rates)
      double amountInUSD = sub.amount;
      total += amountInUSD;
    }
    return total;
  }

  double get totalYearlySpend => totalMonthlySpend * 12;

  Map<String, double> get spendByCategory {
    final Map<String, double> categorySpend = {};
    
    for (var sub in _subscriptions) {
      categorySpend[sub.category] = (categorySpend[sub.category] ?? 0) + sub.amount;
    }
    
    return categorySpend;
  }

  Future<void> loadSubscriptions() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _subscriptions = await DatabaseHelper.instance.readAllSubscriptions();
      
      // Only schedule notifications for all subscriptions during initial app load
      // This prevents showing notifications when returning from add/edit screens
      await _scheduleAllNotificationsQuietly();
      
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _scheduleAllNotificationsQuietly() async {
    try {
      final notificationService = NotificationService();
      
      // Check if notifications are enabled
      final enabled = await notificationService.areNotificationsEnabled();
      if (!enabled) {
        debugPrint('Notifications are disabled, skipping scheduling');
        return;
      }
      
      // Add a small delay to ensure the app is fully initialized
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Schedule notifications quietly (without showing immediate notifications for existing subscriptions)
      await notificationService.scheduleAllNotificationsQuietly(_subscriptions);
      debugPrint('Successfully scheduled notifications for ${_subscriptions.length} subscriptions (quietly)');
      
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    try {
      final id = await DatabaseHelper.instance.createSubscription(subscription);
      final newSubscription = subscription.copyWith(id: id);
      _subscriptions.add(newSubscription);
      
      // Schedule notification for ONLY this new subscription
      try {
        await NotificationService().scheduleNotification(newSubscription);
        debugPrint('Notification scheduled for new subscription: ${newSubscription.name}');
      } catch (e) {
        debugPrint('Error scheduling notification for new subscription: $e');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding subscription: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    try {
      await DatabaseHelper.instance.updateSubscription(subscription);
      
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = subscription;
        
        // Reschedule notification for ONLY this updated subscription
        try {
          await NotificationService().scheduleNotification(subscription);
          debugPrint('Notification rescheduled for updated subscription: ${subscription.name}');
        } catch (e) {
          debugPrint('Error rescheduling notification for updated subscription: $e');
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscription(int id) async {
    try {
      await DatabaseHelper.instance.deleteSubscription(id);
      
      // Cancel notification for deleted subscription (but don't show any notifications)
      try {
        await NotificationService().cancelNotification(id);
        debugPrint('Notification cancelled for deleted subscription ID: $id');
      } catch (e) {
        debugPrint('Error cancelling notification for deleted subscription: $e');
      }
      
      _subscriptions.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
      rethrow;
    }
  }

  List<Subscription> getUpcomingRenewals(int days) {
    return _subscriptions.where((s) => s.daysUntilRenewal <= days).toList();
  }

  // Method to manually refresh notifications (useful for debugging or settings)
  Future<void> refreshNotifications() async {
    try {
      await _scheduleAllNotificationsQuietly();
      debugPrint('Notifications refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    }
  }
}