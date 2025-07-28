import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import 'subscription_detail_screen.dart';

class CancelledSubscriptionsScreen extends StatefulWidget {
  const CancelledSubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<CancelledSubscriptionsScreen> createState() => _CancelledSubscriptionsScreenState();
}

class _CancelledSubscriptionsScreenState extends State<CancelledSubscriptionsScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedSubscriptionIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedSubscriptionIds.length} Selected' : 'Cancelled Subscriptions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.restart_alt),
              onPressed: _selectedSubscriptionIds.isNotEmpty ? _reactivateSelected : null,
              tooltip: 'Reactivate Selected',
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _selectedSubscriptionIds.isNotEmpty ? _deleteSelectedPermanently : null,
              tooltip: 'Delete Forever',
            ),
          ] else ...[
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text('Select Items'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reactivate_all',
                  child: Row(
                    children: [
                      Icon(Icons.restart_alt),
                      SizedBox(width: 8),
                      Text('Reactivate All'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete All', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          final cancelledSubscriptions = provider.cancelledSubscriptions;

          if (cancelledSubscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 100,
                    color: Colors.green.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cancelled subscriptions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All your subscriptions are active!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.archive,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancelled Subscriptions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${cancelledSubscriptions.length} subscription${cancelledSubscriptions.length == 1 ? '' : 's'} cancelled',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isSelectionMode)
                      Text(
                        'Tap to view details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),

              // List of cancelled subscriptions
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: cancelledSubscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = cancelledSubscriptions[index];
                    final isSelected = _selectedSubscriptionIds.contains(subscription.id);

                    return _buildCancelledSubscriptionCard(
                      context,
                      subscription,
                      isSelected,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCancelledSubscriptionCard(
    BuildContext context,
    Subscription subscription,
    bool isSelected,
  ) {
    return Card(
      color: isSelected 
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : Colors.grey.shade50,
      elevation: isSelected ? 2 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        onTap: () => _handleSubscriptionTap(subscription),
        onLongPress: () => _handleSubscriptionLongPress(subscription),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox or subscription icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSelectionMode
                      ? (isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isSelectionMode
                      ? (isSelected ? Icons.check : Icons.radio_button_unchecked)
                      : Icons.cancel,
                  color: _isSelectionMode
                      ? (isSelected ? Colors.white : Colors.grey.shade600)
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Subscription Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subscription name
                    Text(
                      subscription.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.grey.shade400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Amount and billing period
                    Text(
                      '${subscription.currency} ${subscription.amount.toStringAsFixed(2)}${subscription.billingPeriodDisplayText}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Category and cancelled date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            subscription.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Cancelled on ${DateFormat('MMM dd, yyyy').format(subscription.createdDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quick actions
              if (!_isSelectionMode) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _reactivateSingle(subscription),
                      icon: const Icon(Icons.restart_alt),
                      tooltip: 'Reactivate',
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      onPressed: () => _deleteSinglePermanently(subscription),
                      icon: const Icon(Icons.delete_forever),
                      tooltip: 'Delete Forever',
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: const EdgeInsets.all(4),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubscriptionTap(Subscription subscription) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedSubscriptionIds.contains(subscription.id)) {
          _selectedSubscriptionIds.remove(subscription.id);
        } else {
          _selectedSubscriptionIds.add(subscription.id!);
        }
      });
    } else {
      // Navigate to detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionDetailScreen(subscription: subscription),
        ),
      ).then((result) {
        if (result == true) {
          // Refresh if subscription was modified
          setState(() {});
        }
      });
    }
  }

  void _handleSubscriptionLongPress(Subscription subscription) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedSubscriptionIds.add(subscription.id!);
      });
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedSubscriptionIds.clear();
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'select':
        setState(() {
          _isSelectionMode = true;
        });
        break;
      case 'reactivate_all':
        _reactivateAllCancelled();
        break;
      case 'delete_all':
        _deleteAllCancelledPermanently();
        break;
    }
  }

  void _reactivateSingle(Subscription subscription) async {
    try {
      await context.read<SubscriptionProvider>().reactivateSubscription(subscription.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${subscription.name} has been reactivated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reactivating ${subscription.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteSinglePermanently(Subscription subscription) async {
    final confirmed = await _showDeleteConfirmation([subscription.name]);
    if (confirmed == true) {
      try {
        await context.read<SubscriptionProvider>().deleteSubscription(subscription.id!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${subscription.name} has been deleted permanently'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting ${subscription.name}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _reactivateSelected() async {
    try {
      final provider = context.read<SubscriptionProvider>();
      
      for (final id in _selectedSubscriptionIds) {
        await provider.reactivateSubscription(id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedSubscriptionIds.length} subscription${_selectedSubscriptionIds.length == 1 ? '' : 's'} reactivated'),
            backgroundColor: Colors.green,
          ),
        );
        _exitSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reactivating subscriptions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteSelectedPermanently() async {
    final provider = context.read<SubscriptionProvider>();
    final selectedSubscriptions = provider.cancelledSubscriptions
        .where((sub) => _selectedSubscriptionIds.contains(sub.id))
        .map((sub) => sub.name)
        .toList();

    final confirmed = await _showDeleteConfirmation(selectedSubscriptions);
    if (confirmed == true) {
      try {
        for (final id in _selectedSubscriptionIds) {
          await provider.deleteSubscription(id);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedSubscriptionIds.length} subscription${_selectedSubscriptionIds.length == 1 ? '' : 's'} deleted permanently'),
              backgroundColor: Colors.red,
            ),
          );
          _exitSelectionMode();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting subscriptions: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _reactivateAllCancelled() async {
    final provider = context.read<SubscriptionProvider>();
    final cancelledCount = provider.cancelledSubscriptions.length;

    if (cancelledCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivate All Subscriptions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reactivate all $cancelledCount cancelled subscription${cancelledCount == 1 ? '' : 's'}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All subscriptions will be moved back to active status with updated renewal dates.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reactivate All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.reactivateAllCancelledSubscriptions();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All $cancelledCount subscription${cancelledCount == 1 ? '' : 's'} reactivated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error reactivating subscriptions: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deleteAllCancelledPermanently() async {
    final provider = context.read<SubscriptionProvider>();
    final cancelledSubscriptions = provider.cancelledSubscriptions;

    if (cancelledSubscriptions.isEmpty) return;

    final subscriptionNames = cancelledSubscriptions.map((sub) => sub.name).toList();
    final confirmed = await _showDeleteConfirmation(subscriptionNames, isDeleteAll: true);

    if (confirmed == true) {
      try {
        await provider.deleteAllCancelledSubscriptions();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All ${cancelledSubscriptions.length} cancelled subscription${cancelledSubscriptions.length == 1 ? '' : 's'} deleted permanently'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting subscriptions: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(List<String> subscriptionNames, {bool isDeleteAll = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeleteAll ? 'Delete All Subscriptions' : 'Delete Permanently'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDeleteAll
                  ? 'Are you sure you want to permanently delete all ${subscriptionNames.length} cancelled subscriptions?'
                  : subscriptionNames.length == 1
                      ? 'Are you sure you want to permanently delete "${subscriptionNames.first}"?'
                      : 'Are you sure you want to permanently delete these ${subscriptionNames.length} subscriptions?',
            ),
            if (subscriptionNames.length > 1 && !isDeleteAll) ...[
              const SizedBox(height: 12),
              Container(
                height: 120,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subscriptionNames.map((name) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• $name', style: const TextStyle(fontSize: 12)),
                      )
                    ).toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All subscription data will be permanently lost.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}