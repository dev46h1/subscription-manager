import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onTap;

  const SubscriptionCard({
    Key? key,
    required this.subscription,
    required this.onTap,
  }) : super(key: key);

  Color _getCardColor(BuildContext context, int daysRemaining) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (daysRemaining <= 0) return Colors.red.shade100;
    if (daysRemaining <= 2) return Colors.orange.shade100;
    if (daysRemaining <= 7) return Colors.yellow.shade100;
    return colorScheme.surfaceVariant;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Entertainment':
        return Icons.movie;
      case 'Software':
        return Icons.computer;
      case 'Gaming':
        return Icons.games;
      case 'Music':
        return Icons.music_note;
      case 'News':
        return Icons.newspaper;
      case 'Education':
        return Icons.school;
      case 'Health':
        return Icons.favorite;
      case 'Business':
        return Icons.business;
      default:
        return Icons.category;
    }
  }

  Widget _buildBillingPeriodChip(BuildContext context) {
    Color chipColor;
    switch (subscription.billingPeriod) {
      case BillingPeriod.monthly:
        chipColor = Colors.blue;
        break;
      case BillingPeriod.quarterly:
        chipColor = Colors.green;
        break;
      case BillingPeriod.sixMonthly:
        chipColor = Colors.orange;
        break;
      case BillingPeriod.yearly:
        chipColor = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        subscription.billingPeriod.shortDisplayName,
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysRemaining = subscription.daysUntilRenewal;
    final cardColor = _getCardColor(context, daysRemaining);
    final isUrgent = daysRemaining <= 2;

    return Card(
      color: cardColor,
      elevation: isUrgent ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(subscription.category),
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Subscription Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subscription.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildBillingPeriodChip(context),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Main amount on its own line to prevent overflow
                    Text(
                      '${subscription.currency} ${subscription.amount.toStringAsFixed(2)}${subscription.billingPeriodDisplayText}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Monthly equivalent on separate line if different from main amount
                    if (subscription.billingPeriod != BillingPeriod.monthly) ...[
                      const SizedBox(height: 1),
                      Text(
                        '(${subscription.currency} ${subscription.monthlyEquivalent.toStringAsFixed(2)}/mo)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Renews: ${DateFormat('MMM dd, yyyy').format(subscription.renewalDate)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Days Remaining
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            daysRemaining <= 0 ? 'Today!' : '$daysRemaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          '$daysRemaining',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: daysRemaining <= 7 
                                ? Colors.orange 
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'day${daysRemaining == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}