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
      
      // Delay notification check to ensure platform is ready
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          await NotificationService().checkAndScheduleAllNotifications(_subscriptions);
        } catch (e) {
          debugPrint('Error scheduling notifications: $e');
        }
      });
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSubscription(Subscription subscription) async {
    try {
      final id = await DatabaseHelper.instance.createSubscription(subscription);
      final newSubscription = subscription.copyWith(id: id);
      _subscriptions.add(newSubscription);
      
      // Schedule notification for new subscription
      await NotificationService().scheduleNotification(newSubscription);
      
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
        
        // Reschedule notification for updated subscription
        await NotificationService().scheduleNotification(subscription);
        
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
      
      // Cancel notification for deleted subscription
      await NotificationService().cancelNotification(id);
      
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
}