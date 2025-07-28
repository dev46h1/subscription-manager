import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import 'renew_subscription_screen.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionDetailScreen({
    Key? key,
    required this.subscription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOverdue = subscription.isOverdue;
    final daysRemaining = subscription.daysUntilRenewal;

    return Scaffold(
      appBar: AppBar(
        title: Text(subscription.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _showMoreOptions(context),
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(context, isOverdue, daysRemaining),
            const SizedBox(height: 24),

            // Subscription Details
            _buildDetailSection(context, 'Subscription Details', [
              _buildDetailRow(context, 'Name', subscription.name),
              _buildDetailRow(
                context,
                'Amount',
                '${subscription.currency} ${subscription.amount.toStringAsFixed(2)}${subscription.billingPeriodDisplayText}',
              ),
              if (subscription.billingPeriod != BillingPeriod.monthly)
                _buildDetailRow(
                  context,
                  'Monthly Equivalent',
                  '${subscription.currency} ${subscription.monthlyEquivalent.toStringAsFixed(2)}/month',
                ),
              _buildDetailRow(context, 'Category', subscription.category),
              _buildDetailRow(context, 'Billing Period', subscription.billingPeriod.displayName),
              _buildDetailRow(context, 'Status', subscription.statusDisplayText),
            ]),

            const SizedBox(height: 24),

            // Renewal Information
            _buildDetailSection(context, 'Renewal Information', [
              _buildDetailRow(
                context,
                'Next Renewal',
                DateFormat('EEEE, MMMM dd, yyyy').format(subscription.renewalDate),
              ),
              _buildDetailRow(
                context,
                'Days Until Renewal',
                isOverdue
                    ? 'Overdue by ${daysRemaining.abs()} day${daysRemaining.abs() == 1 ? '' : 's'}'
                    : daysRemaining == 0
                        ? 'Due Today'
                        : '$daysRemaining day${daysRemaining == 1 ? '' : 's'}',
              ),
              if (subscription.lastRenewDate != null)
                _buildDetailRow(
                  context,
                  'Last Renewed',
                  DateFormat('MMMM dd, yyyy').format(subscription.lastRenewDate!),
                ),
            ]),

            const SizedBox(height: 24),

            // Subscription History
            _buildDetailSection(context, 'Subscription History', [
              _buildDetailRow(
                context,
                'Created On',
                DateFormat('MMMM dd, yyyy').format(subscription.createdDate),
              ),
              _buildDetailRow(context, 'Renewal Count', '${subscription.renewalCount} times'),
              _buildDetailRow(
                context,
                'Total Amount Spent',
                '${subscription.currency} ${subscription.totalAmountSpent.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                context,
                'Subscription Duration',
                '${subscription.subscriptionDurationInMonths} months',
              ),
            ]),

            if (subscription.notes != null && subscription.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDetailSection(context, 'Notes', [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    subscription.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            if (subscription.status == SubscriptionStatus.active) ...[
              _buildActionButtons(context),
            ] else if (subscription.status == SubscriptionStatus.cancelled) ...[
              _buildCancelledActions(context),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isOverdue, int daysRemaining) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (subscription.status != SubscriptionStatus.active) {
      statusColor = Colors.grey;
      statusIcon = Icons.cancel;
      statusText = subscription.statusDisplayText;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'Overdue';
    } else if (daysRemaining <= 2) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = daysRemaining == 0 ? 'Due Today' : 'Due Soon';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Active';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 48,
            color: statusColor,
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${subscription.currency} ${subscription.amount.toStringAsFixed(2)}${subscription.billingPeriodDisplayText}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleRenewSubscription(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Renew'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleCancelSubscription(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Secondary Actions
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _handleEditSubscription(context),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Details'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledActions(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey.shade600,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'This subscription has been cancelled',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleReactivateSubscription(context),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reactivate'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleDeletePermanently(context),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleRenewSubscription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RenewSubscriptionScreen(subscription: subscription),
      ),
    ).then((renewed) {
      if (renewed == true) {
        Navigator.pop(context, true); // Go back to home screen with refresh
      }
    });
  }

  void _handleCancelSubscription(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel "${subscription.name}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will move the subscription to cancelled items. You can reactivate it later if needed.',
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
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = context.read<SubscriptionProvider>();
        await provider.cancelSubscription(subscription.id!);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${subscription.name} has been cancelled'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  try {
                    await provider.reactivateSubscription(subscription.id!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${subscription.name} reactivated')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error reactivating: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling subscription: $e')),
          );
        }
      }
    }
  }

  void _handleEditSubscription(BuildContext context) {
    // Navigate to edit screen (your existing AddEditSubscriptionScreen)
    // You'll need to import and use your existing screen
    Navigator.pushNamed(
      context,
      '/edit-subscription',
      arguments: subscription,
    ).then((updated) {
      if (updated == true) {
        Navigator.pop(context, true);
      }
    });
  }

  void _handleReactivateSubscription(BuildContext context) async {
    try {
      final provider = context.read<SubscriptionProvider>();
      await provider.reactivateSubscription(subscription.id!);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${subscription.name} has been reactivated')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reactivating subscription: $e')),
        );
      }
    }
  }

  void _handleDeletePermanently(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to permanently delete "${subscription.name}"?'),
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

    if (confirmed == true) {
      try {
        final provider = context.read<SubscriptionProvider>();
        await provider.deleteSubscription(subscription.id!);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${subscription.name} has been deleted permanently')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting subscription: $e')),
          );
        }
      }
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Subscription Details'),
              onTap: () {
                Navigator.pop(context);
                _shareSubscriptionDetails(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Renewal History'),
              onTap: () {
                Navigator.pop(context);
                _showRenewalHistory(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate Subscription'),
              onTap: () {
                Navigator.pop(context);
                _duplicateSubscription(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Close'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _shareSubscriptionDetails(BuildContext context) {
    final details = '''
Subscription Details:
${subscription.name}
Amount: ${subscription.currency} ${subscription.amount.toStringAsFixed(2)}${subscription.billingPeriodDisplayText}
Next Renewal: ${DateFormat('MMMM dd, yyyy').format(subscription.renewalDate)}
Category: ${subscription.category}
Status: ${subscription.statusDisplayText}
${subscription.notes != null ? 'Notes: ${subscription.notes}' : ''}
''';
    
    // You would implement actual sharing here using share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality would be implemented here')),
    );
  }

  void _showRenewalHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Renewal History',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: subscription.renewalCount == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No renewal history yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Renewals will appear here once you renew this subscription',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        // Current subscription
                        _buildHistoryItem(
                          context,
                          'Current Period',
                          subscription.createdDate,
                          subscription.amount,
                          subscription.currency,
                          isActive: true,
                        ),
                        // Previous renewals would be loaded from database
                        if (subscription.lastRenewDate != null)
                          _buildHistoryItem(
                            context,
                            'Last Renewal',
                            subscription.lastRenewDate!,
                            subscription.amount,
                            subscription.currency,
                          ),
                        // You would load more history items from database here
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    String title,
    DateTime date,
    double amount,
    String currency, {
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.history,
              color: isActive ? Colors.green : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('MMMM dd, yyyy').format(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _duplicateSubscription(BuildContext context) async {
    try {
      final provider = context.read<SubscriptionProvider>();
      
      // Create a copy with modified name and reset dates
      final duplicatedSubscription = subscription.copyWith(
        id: null, // Remove ID so it creates a new entry
        name: '${subscription.name} (Copy)',
        renewalDate: subscription.getSmartRenewalDate(),
        createdDate: DateTime.now(),
        lastRenewDate: null,
        renewalCount: 0,
        status: SubscriptionStatus.active,
      );
      
      await provider.addSubscription(duplicatedSubscription);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${subscription.name} has been duplicated'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.pop(context, true); // Go back to home to see the new subscription
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating subscription: $e')),
        );
      }
    }
  }
}