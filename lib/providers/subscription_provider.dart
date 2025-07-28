import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Subscription> get subscriptions {
    try {
      // Sort by days until renewal (ascending)
      _subscriptions.sort((a, b) => a.daysUntilRenewal.compareTo(b.daysUntilRenewal));
      return _subscriptions;
    } catch (e) {
      debugPrint('Error sorting subscriptions: $e');
      return _subscriptions;
    }
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Calculate total monthly spend using monthly equivalents
  double get totalMonthlySpend {
    try {
      double total = 0;
      for (var sub in _subscriptions) {
        total += sub.monthlyEquivalent;
      }
      return total;
    } catch (e) {
      debugPrint('Error calculating total monthly spend: $e');
      return 0.0;
    }
  }

  double get totalYearlySpend {
    try {
      return totalMonthlySpend * 12;
    } catch (e) {
      debugPrint('Error calculating total yearly spend: $e');
      return 0.0;
    }
  }

  // Calculate quarterly spend
  double get totalQuarterlySpend {
    try {
      return totalMonthlySpend * 3;
    } catch (e) {
      debugPrint('Error calculating total quarterly spend: $e');
      return 0.0;
    }
  }

  // Calculate 6-monthly spend
  double get totalSixMonthlySpend {
    try {
      return totalMonthlySpend * 6;
    } catch (e) {
      debugPrint('Error calculating total six monthly spend: $e');
      return 0.0;
    }
  }

  // Get spending by category (monthly equivalent)
  Map<String, double> get spendByCategory {
    try {
      final Map<String, double> categorySpend = {};
      
      for (var sub in _subscriptions) {
        categorySpend[sub.category] = (categorySpend[sub.category] ?? 0) + sub.monthlyEquivalent;
      }
      
      return categorySpend;
    } catch (e) {
      debugPrint('Error calculating spend by category: $e');
      return {};
    }
  }

  // Get spending by billing period
  Map<BillingPeriod, double> get spendByBillingPeriod {
    try {
      final Map<BillingPeriod, double> periodSpend = {};
      
      for (var period in BillingPeriod.values) {
        periodSpend[period] = 0;
      }
      
      for (var sub in _subscriptions) {
        periodSpend[sub.billingPeriod] = (periodSpend[sub.billingPeriod] ?? 0) + sub.amount;
      }
      
      return periodSpend;
    } catch (e) {
      debugPrint('Error calculating spend by billing period: $e');
      return {};
    }
  }

  // Get count of subscriptions by billing period
  Map<BillingPeriod, int> get subscriptionCountByPeriod {
    try {
      final Map<BillingPeriod, int> periodCount = {};
      
      for (var period in BillingPeriod.values) {
        periodCount[period] = 0;
      }
      
      for (var sub in _subscriptions) {
        periodCount[sub.billingPeriod] = (periodCount[sub.billingPeriod] ?? 0) + 1;
      }
      
      return periodCount;
    } catch (e) {
      debugPrint('Error calculating subscription count by period: $e');
      return {
        BillingPeriod.monthly: 0,
        BillingPeriod.quarterly: 0,
        BillingPeriod.sixMonthly: 0,
        BillingPeriod.yearly: 0,
      };
    }
  }

  // Get actual spending for different periods (not monthly equivalent)
  double getActualSpendingForPeriod(BillingPeriod period) {
    try {
      return _subscriptions
          .where((sub) => sub.billingPeriod == period)
          .fold(0.0, (sum, sub) => sum + sub.amount);
    } catch (e) {
      debugPrint('Error calculating actual spending for period $period: $e');
      return 0.0;
    }
  }

  // Get subscriptions by billing period
  List<Subscription> getSubscriptionsByPeriod(BillingPeriod period) {
    try {
      return _subscriptions.where((sub) => sub.billingPeriod == period).toList();
    } catch (e) {
      debugPrint('Error getting subscriptions by period $period: $e');
      return [];
    }
  }

  // Get subscriptions by category
  List<Subscription> getSubscriptionsByCategory(String category) {
    try {
      return _subscriptions.where((sub) => sub.category == category).toList();
    } catch (e) {
      debugPrint('Error getting subscriptions by category $category: $e');
      return [];
    }
  }

  // Get all categories
  List<String> get allCategories {
    try {
      return _subscriptions.map((sub) => sub.category).toSet().toList();
    } catch (e) {
      debugPrint('Error getting all categories: $e');
      return [];
    }
  }

  // Get subscriptions expiring in the next N days
  List<Subscription> getUpcomingRenewals(int days) {
    try {
      return _subscriptions.where((s) => s.daysUntilRenewal <= days && s.daysUntilRenewal >= 0).toList();
    } catch (e) {
      debugPrint('Error getting upcoming renewals: $e');
      return [];
    }
  }

  // Get expired subscriptions (overdue)
  List<Subscription> get expiredSubscriptions {
    try {
      return _subscriptions.where((s) => s.daysUntilRenewal < 0).toList();
    } catch (e) {
      debugPrint('Error getting expired subscriptions: $e');
      return [];
    }
  }

  // Get subscription statistics
  Map<String, dynamic> get subscriptionStats {
    try {
      return {
        'totalSubscriptions': _subscriptions.length,
        'totalMonthlySpend': totalMonthlySpend,
        'totalYearlySpend': totalYearlySpend,
        'averageMonthlyPerSubscription': _subscriptions.isNotEmpty ? totalMonthlySpend / _subscriptions.length : 0.0,
        'upcomingRenewalsThisWeek': getUpcomingRenewals(7).length,
        'upcomingRenewalsToday': getUpcomingRenewals(0).length,
        'expiredCount': expiredSubscriptions.length,
        'categoriesCount': allCategories.length,
      };
    } catch (e) {
      debugPrint('Error calculating subscription stats: $e');
      return {
        'totalSubscriptions': 0,
        'totalMonthlySpend': 0.0,
        'totalYearlySpend': 0.0,
        'averageMonthlyPerSubscription': 0.0,
        'upcomingRenewalsThisWeek': 0,
        'upcomingRenewalsToday': 0,
        'expiredCount': 0,
        'categoriesCount': 0,
      };
    }
  }

  Future<void> loadSubscriptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _subscriptions = await DatabaseHelper.instance.readAllSubscriptions();
      
      // Only schedule notifications for all subscriptions during initial app load
      // This prevents showing notifications when returning from add/edit screens
      await _scheduleAllNotificationsQuietly();
      
      debugPrint('Successfully loaded ${_subscriptions.length} subscriptions');
    } catch (e) {
      _errorMessage = 'Failed to load subscriptions: ${e.toString()}';
      debugPrint('Error loading subscriptions: $e');
      // Don't rethrow, let the UI handle the error state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      // Don't throw error, just log it
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    try {
      _errorMessage = null;
      
      final id = await DatabaseHelper.instance.createSubscription(subscription);
      final newSubscription = subscription.copyWith(id: id);
      _subscriptions.add(newSubscription);
      
      // Schedule notification for ONLY this new subscription
      try {
        await NotificationService().scheduleNotification(newSubscription);
        debugPrint('Notification scheduled for new subscription: ${newSubscription.name}');
      } catch (e) {
        debugPrint('Error scheduling notification for new subscription: $e');
        // Don't prevent subscription creation if notification fails
      }
      
      notifyListeners();
      debugPrint('Successfully added subscription: ${newSubscription.name}');
    } catch (e) {
      _errorMessage = 'Failed to add subscription: ${e.toString()}';
      debugPrint('Error adding subscription: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    try {
      _errorMessage = null;
      
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
          // Don't prevent subscription update if notification fails
        }
        
        notifyListeners();
        debugPrint('Successfully updated subscription: ${subscription.name}');
      } else {
        throw Exception('Subscription not found in local list');
      }
    } catch (e) {
      _errorMessage = 'Failed to update subscription: ${e.toString()}';
      debugPrint('Error updating subscription: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscription(int id) async {
    try {
      _errorMessage = null;
      
      // Find the subscription for logging purposes
      final subscription = _subscriptions.firstWhere((s) => s.id == id, orElse: () => throw Exception('Subscription not found'));
      
      await DatabaseHelper.instance.deleteSubscription(id);
      
      // Cancel notification for deleted subscription (but don't show any notifications)
      try {
        await NotificationService().cancelNotification(id);
        debugPrint('Notification cancelled for deleted subscription ID: $id');
      } catch (e) {
        debugPrint('Error cancelling notification for deleted subscription: $e');
        // Don't prevent deletion if notification cancellation fails
      }
      
      _subscriptions.removeWhere((s) => s.id == id);
      notifyListeners();
      debugPrint('Successfully deleted subscription: ${subscription.name}');
    } catch (e) {
      _errorMessage = 'Failed to delete subscription: ${e.toString()}';
      debugPrint('Error deleting subscription: $e');
      rethrow;
    }
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

  // Method to clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Method to force refresh data
  Future<void> forceRefresh() async {
    await loadSubscriptions();
  }

  // Search subscriptions by name
  List<Subscription> searchSubscriptions(String query) {
    try {
      if (query.isEmpty) return subscriptions;
      
      final lowercaseQuery = query.toLowerCase();
      return _subscriptions.where((subscription) {
        return subscription.name.toLowerCase().contains(lowercaseQuery) ||
               subscription.category.toLowerCase().contains(lowercaseQuery) ||
               subscription.notes?.toLowerCase().contains(lowercaseQuery) == true;
      }).toList();
    } catch (e) {
      debugPrint('Error searching subscriptions: $e');
      return [];
    }
  }

  // Filter subscriptions by multiple criteria
  List<Subscription> filterSubscriptions({
    List<String>? categories,
    List<BillingPeriod>? billingPeriods,
    double? minAmount,
    double? maxAmount,
    int? daysUntilRenewal,
  }) {
    try {
      return _subscriptions.where((subscription) {
        // Category filter
        if (categories != null && categories.isNotEmpty) {
          if (!categories.contains(subscription.category)) return false;
        }
        
        // Billing period filter
        if (billingPeriods != null && billingPeriods.isNotEmpty) {
          if (!billingPeriods.contains(subscription.billingPeriod)) return false;
        }
        
        // Amount filter (using monthly equivalent for consistency)
        if (minAmount != null && subscription.monthlyEquivalent < minAmount) return false;
        if (maxAmount != null && subscription.monthlyEquivalent > maxAmount) return false;
        
        // Days until renewal filter
        if (daysUntilRenewal != null && subscription.daysUntilRenewal > daysUntilRenewal) return false;
        
        return true;
      }).toList();
    } catch (e) {
      debugPrint('Error filtering subscriptions: $e');
      return [];
    }
  }

  // Get subscription by ID
  Subscription? getSubscriptionById(int id) {
    try {
      return _subscriptions.firstWhere((sub) => sub.id == id);
    } catch (e) {
      debugPrint('Subscription with ID $id not found');
      return null;
    }
  }

  // Bulk operations
  Future<void> deleteMultipleSubscriptions(List<int> ids) async {
    try {
      _errorMessage = null;
      
      for (final id in ids) {
        await deleteSubscription(id);
      }
      
      debugPrint('Successfully deleted ${ids.length} subscriptions');
    } catch (e) {
      _errorMessage = 'Failed to delete multiple subscriptions: ${e.toString()}';
      debugPrint('Error deleting multiple subscriptions: $e');
      rethrow;
    }
  }

  // Update multiple subscriptions (useful for batch operations)
  Future<void> updateMultipleSubscriptions(List<Subscription> subscriptions) async {
    try {
      _errorMessage = null;
      
      for (final subscription in subscriptions) {
        await updateSubscription(subscription);
      }
      
      debugPrint('Successfully updated ${subscriptions.length} subscriptions');
    } catch (e) {
      _errorMessage = 'Failed to update multiple subscriptions: ${e.toString()}';
      debugPrint('Error updating multiple subscriptions: $e');
      rethrow;
    }
  }

  // Export data (returns a map that can be converted to JSON)
  Map<String, dynamic> exportData() {
    try {
      return {
        'subscriptions': _subscriptions.map((sub) => sub.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'totalSubscriptions': _subscriptions.length,
        'statistics': subscriptionStats,
      };
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return {
        'subscriptions': [],
        'exportDate': DateTime.now().toIso8601String(),
        'totalSubscriptions': 0,
        'statistics': {},
        'error': e.toString(),
      };
    }
  }

  // Import data (from a map, typically from JSON)
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();
      
      final subscriptionsData = data['subscriptions'] as List<dynamic>?;
      if (subscriptionsData == null) {
        throw Exception('Invalid data format: missing subscriptions');
      }
      
      // Clear existing data
      _subscriptions.clear();
      
      // Import new subscriptions
      for (final subData in subscriptionsData) {
        final subscription = Subscription.fromMap(subData as Map<String, dynamic>);
        await addSubscription(subscription);
      }
      
      debugPrint('Successfully imported ${subscriptionsData.length} subscriptions');
    } catch (e) {
      _errorMessage = 'Failed to import data: ${e.toString()}';
      debugPrint('Error importing data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    try {
      // Clean up any resources if needed
      debugPrint('SubscriptionProvider disposed');
    } catch (e) {
      debugPrint('Error disposing SubscriptionProvider: $e');
    }
    super.dispose();
  }
}