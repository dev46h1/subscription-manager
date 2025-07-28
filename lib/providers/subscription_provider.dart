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
      // Only return active subscriptions, sorted by days until renewal
      final activeSubscriptions = _subscriptions
          .where((sub) => sub.status == SubscriptionStatus.active)
          .toList();
      activeSubscriptions.sort((a, b) => a.daysUntilRenewal.compareTo(b.daysUntilRenewal));
      return activeSubscriptions;
    } catch (e) {
      debugPrint('Error getting active subscriptions: $e');
      return [];
    }
  }

  List<Subscription> get allSubscriptions => _subscriptions;

  List<Subscription> get cancelledSubscriptions {
    try {
      return _subscriptions
          .where((sub) => sub.status == SubscriptionStatus.cancelled)
          .toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate)); // Latest first
    } catch (e) {
      debugPrint('Error getting cancelled subscriptions: $e');
      return [];
    }
  }

  List<Subscription> get pausedSubscriptions {
    try {
      return _subscriptions
          .where((sub) => sub.status == SubscriptionStatus.paused)
          .toList()
        ..sort((a, b) => a.daysUntilRenewal.compareTo(b.daysUntilRenewal));
    } catch (e) {
      debugPrint('Error getting paused subscriptions: $e');
      return [];
    }
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Calculate total monthly spend using monthly equivalents (active only)
  double get totalMonthlySpend {
    try {
      double total = 0;
      for (var sub in subscriptions) { // This already filters active subscriptions
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

  double get totalQuarterlySpend {
    try {
      return totalMonthlySpend * 3;
    } catch (e) {
      debugPrint('Error calculating total quarterly spend: $e');
      return 0.0;
    }
  }

  double get totalSixMonthlySpend {
    try {
      return totalMonthlySpend * 6;
    } catch (e) {
      debugPrint('Error calculating total six monthly spend: $e');
      return 0.0;
    }
  }

  // Get spending by category (monthly equivalent, active only)
  Map<String, double> get spendByCategory {
    try {
      final Map<String, double> categorySpend = {};
      
      for (var sub in subscriptions) { // This already filters active subscriptions
        categorySpend[sub.category] = (categorySpend[sub.category] ?? 0) + sub.monthlyEquivalent;
      }
      
      return categorySpend;
    } catch (e) {
      debugPrint('Error calculating spend by category: $e');
      return {};
    }
  }

  // Get spending by billing period (active only)
  Map<BillingPeriod, double> get spendByBillingPeriod {
    try {
      final Map<BillingPeriod, double> periodSpend = {};
      
      for (var period in BillingPeriod.values) {
        periodSpend[period] = 0;
      }
      
      for (var sub in subscriptions) { // This already filters active subscriptions
        periodSpend[sub.billingPeriod] = (periodSpend[sub.billingPeriod] ?? 0) + sub.amount;
      }
      
      return periodSpend;
    } catch (e) {
      debugPrint('Error calculating spend by billing period: $e');
      return {};
    }
  }

  // Get count of subscriptions by billing period (active only)
  Map<BillingPeriod, int> get subscriptionCountByPeriod {
    try {
      final Map<BillingPeriod, int> periodCount = {};
      
      for (var period in BillingPeriod.values) {
        periodCount[period] = 0;
      }
      
      for (var sub in subscriptions) { // This already filters active subscriptions
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

  // Get actual spending for different periods (not monthly equivalent, active only)
  double getActualSpendingForPeriod(BillingPeriod period) {
    try {
      return subscriptions // This already filters active subscriptions
          .where((sub) => sub.billingPeriod == period)
          .fold(0.0, (sum, sub) => sum + sub.amount);
    } catch (e) {
      debugPrint('Error calculating actual spending for period $period: $e');
      return 0.0;
    }
  }

  // Get subscriptions by billing period (active only)
  List<Subscription> getSubscriptionsByPeriod(BillingPeriod period) {
    try {
      return subscriptions.where((sub) => sub.billingPeriod == period).toList();
    } catch (e) {
      debugPrint('Error getting subscriptions by period $period: $e');
      return [];
    }
  }

  // Get subscriptions by category (active only)
  List<Subscription> getSubscriptionsByCategory(String category) {
    try {
      return subscriptions.where((sub) => sub.category == category).toList();
    } catch (e) {
      debugPrint('Error getting subscriptions by category $category: $e');
      return [];
    }
  }

  // Get subscriptions by status
  List<Subscription> getSubscriptionsByStatus(SubscriptionStatus status) {
    try {
      return _subscriptions.where((sub) => sub.status == status).toList();
    } catch (e) {
      debugPrint('Error getting subscriptions by status $status: $e');
      return [];
    }
  }

  // Get all categories (active only)
  List<String> get allCategories {
    try {
      return subscriptions.map((sub) => sub.category).toSet().toList();
    } catch (e) {
      debugPrint('Error getting all categories: $e');
      return [];
    }
  }

  // Get subscriptions expiring in the next N days (active only)
  List<Subscription> getUpcomingRenewals(int days) {
    try {
      return subscriptions.where((s) => s.daysUntilRenewal <= days && s.daysUntilRenewal >= 0).toList();
    } catch (e) {
      debugPrint('Error getting upcoming renewals: $e');
      return [];
    }
  }

  // Get expired subscriptions (overdue, active only)
  List<Subscription> get expiredSubscriptions {
    try {
      return subscriptions.where((s) => s.daysUntilRenewal < 0).toList();
    } catch (e) {
      debugPrint('Error getting expired subscriptions: $e');
      return [];
    }
  }

  // Get subscription statistics
  Map<String, dynamic> get subscriptionStats {
    try {
      return {
        'totalActiveSubscriptions': subscriptions.length,
        'totalCancelledSubscriptions': cancelledSubscriptions.length,
        'totalAllSubscriptions': _subscriptions.length,
        'totalMonthlySpend': totalMonthlySpend,
        'totalYearlySpend': totalYearlySpend,
        'averageMonthlyPerSubscription': subscriptions.isNotEmpty ? totalMonthlySpend / subscriptions.length : 0.0,
        'upcomingRenewalsThisWeek': getUpcomingRenewals(7).length,
        'upcomingRenewalsToday': getUpcomingRenewals(0).length,
        'expiredCount': expiredSubscriptions.length,
        'categoriesCount': allCategories.length,
      };
    } catch (e) {
      debugPrint('Error calculating subscription stats: $e');
      return {
        'totalActiveSubscriptions': 0,
        'totalCancelledSubscriptions': 0,
        'totalAllSubscriptions': 0,
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
      
      // Only schedule notifications for active subscriptions during initial app load
      await _scheduleAllNotificationsQuietly();
      
      debugPrint('Successfully loaded ${_subscriptions.length} subscriptions (${subscriptions.length} active)');
    } catch (e) {
      _errorMessage = 'Failed to load subscriptions: ${e.toString()}';
      debugPrint('Error loading subscriptions: $e');
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
      
      // Schedule notifications quietly (only for active subscriptions)
      await notificationService.scheduleAllNotificationsQuietly(subscriptions);
      debugPrint('Successfully scheduled notifications for ${subscriptions.length} active subscriptions (quietly)');
      
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    try {
      _errorMessage = null;
      
      final id = await DatabaseHelper.instance.createSubscription(subscription);
      final newSubscription = subscription.copyWith(id: id);
      _subscriptions.add(newSubscription);
      
      // Schedule notification for ONLY this new subscription (if active)
      if (newSubscription.status == SubscriptionStatus.active) {
        try {
          await NotificationService().scheduleNotification(newSubscription);
          debugPrint('Notification scheduled for new subscription: ${newSubscription.name}');
        } catch (e) {
          debugPrint('Error scheduling notification for new subscription: $e');
        }
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
        
        // Reschedule notification for ONLY this updated subscription (if active)
        if (subscription.status == SubscriptionStatus.active) {
          try {
            await NotificationService().scheduleNotification(subscription);
            debugPrint('Notification rescheduled for updated subscription: ${subscription.name}');
          } catch (e) {
            debugPrint('Error rescheduling notification for updated subscription: $e');
          }
        } else {
          // Cancel notification if subscription is no longer active
          try {
            await NotificationService().cancelNotification(subscription.id!);
            debugPrint('Notification cancelled for inactive subscription: ${subscription.name}');
          } catch (e) {
            debugPrint('Error cancelling notification for inactive subscription: $e');
          }
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

  Future<void> cancelSubscription(int id) async {
    try {
      _errorMessage = null;
      
      final subscription = _subscriptions.firstWhere((s) => s.id == id);
      final cancelledSubscription = subscription.createCancelled();
      
      await updateSubscription(cancelledSubscription);
      debugPrint('Successfully cancelled subscription: ${subscription.name}');
    } catch (e) {
      _errorMessage = 'Failed to cancel subscription: ${e.toString()}';
      debugPrint('Error cancelling subscription: $e');
      rethrow;
    }
  }

  Future<void> reactivateSubscription(int id) async {
    try {
      _errorMessage = null;
      
      final subscription = _subscriptions.firstWhere((s) => s.id == id);
      final reactivatedSubscription = subscription.copyWith(
        status: SubscriptionStatus.active,
        renewalDate: subscription.getSmartRenewalDate(), // Update renewal date to smart suggestion
      );
      
      await updateSubscription(reactivatedSubscription);
      debugPrint('Successfully reactivated subscription: ${subscription.name}');
    } catch (e) {
      _errorMessage = 'Failed to reactivate subscription: ${e.toString()}';
      debugPrint('Error reactivating subscription: $e');
      rethrow;
    }
  }

  Future<void> pauseSubscription(int id) async {
    try {
      _errorMessage = null;
      
      final subscription = _subscriptions.firstWhere((s) => s.id == id);
      final pausedSubscription = subscription.copyWith(status: SubscriptionStatus.paused);
      
      await updateSubscription(pausedSubscription);
      debugPrint('Successfully paused subscription: ${subscription.name}');
    } catch (e) {
      _errorMessage = 'Failed to pause subscription: ${e.toString()}';
      debugPrint('Error pausing subscription: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscription(int id) async {
    try {
      _errorMessage = null;
      
      final subscription = _subscriptions.firstWhere((s) => s.id == id);
      
      await DatabaseHelper.instance.deleteSubscription(id);
      
      // Cancel notification for deleted subscription
      try {
        await NotificationService().cancelNotification(id);
        debugPrint('Notification cancelled for deleted subscription ID: $id');
      } catch (e) {
        debugPrint('Error cancelling notification for deleted subscription: $e');
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

  // Bulk operations for cancelled subscriptions
  Future<void> deleteAllCancelledSubscriptions() async {
    try {
      _errorMessage = null;
      
      final cancelledIds = cancelledSubscriptions.map((s) => s.id!).toList();
      
      for (final id in cancelledIds) {
        await DatabaseHelper.instance.deleteSubscription(id);
        await NotificationService().cancelNotification(id);
      }
      
      _subscriptions.removeWhere((s) => s.status == SubscriptionStatus.cancelled);
      notifyListeners();
      debugPrint('Successfully deleted ${cancelledIds.length} cancelled subscriptions');
    } catch (e) {
      _errorMessage = 'Failed to delete cancelled subscriptions: ${e.toString()}';
      debugPrint('Error deleting cancelled subscriptions: $e');
      rethrow;
    }
  }

  Future<void> reactivateAllCancelledSubscriptions() async {
    try {
      _errorMessage = null;
      
      final cancelled = cancelledSubscriptions;
      
      for (final subscription in cancelled) {
        await reactivateSubscription(subscription.id!);
      }
      
      debugPrint('Successfully reactivated ${cancelled.length} cancelled subscriptions');
    } catch (e) {
      _errorMessage = 'Failed to reactivate cancelled subscriptions: ${e.toString()}';
      debugPrint('Error reactivating cancelled subscriptions: $e');
      rethrow;
    }
  }

  // Method to manually refresh notifications
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

  // Search subscriptions by name (all statuses)
  List<Subscription> searchSubscriptions(String query, {SubscriptionStatus? status}) {
    try {
      if (query.isEmpty) {
        return status != null 
            ? getSubscriptionsByStatus(status)
            : _subscriptions;
      }
      
      final lowercaseQuery = query.toLowerCase();
      final searchPool = status != null 
          ? getSubscriptionsByStatus(status)
          : _subscriptions;
          
      return searchPool.where((subscription) {
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
    List<SubscriptionStatus>? statuses,
    double? minAmount,
    double? maxAmount,
    int? daysUntilRenewal,
  }) {
    try {
      final searchPool = statuses != null 
          ? _subscriptions.where((s) => statuses.contains(s.status)).toList()
          : _subscriptions;
          
      return searchPool.where((subscription) {
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
        
        // Days until renewal filter (only applies to active subscriptions)
        if (daysUntilRenewal != null && 
            subscription.status == SubscriptionStatus.active && 
            subscription.daysUntilRenewal > daysUntilRenewal) return false;
        
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

  // Export data with status information
  Map<String, dynamic> exportData({bool includeInactive = false}) {
    try {
      final dataToExport = includeInactive ? _subscriptions : subscriptions;
      
      return {
        'subscriptions': dataToExport.map((sub) => sub.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'totalSubscriptions': dataToExport.length,
        'includeInactive': includeInactive,
        'statistics': {
          'active': subscriptions.length,
          'cancelled': cancelledSubscriptions.length,
          'paused': pausedSubscriptions.length,
          'totalMonthlySpend': totalMonthlySpend,
          'totalYearlySpend': totalYearlySpend,
        },
      };
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return {
        'subscriptions': [],
        'exportDate': DateTime.now().toIso8601String(),
        'totalSubscriptions': 0,
        'includeInactive': includeInactive,
        'statistics': {},
        'error': e.toString(),
      };
    }
  }

  @override
  void dispose() {
    try {
      debugPrint('SubscriptionProvider disposed');
    } catch (e) {
      debugPrint('Error disposing SubscriptionProvider: $e');
    }
    super.dispose();
  }
}