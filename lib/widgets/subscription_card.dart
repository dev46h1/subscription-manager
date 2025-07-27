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
                    Text(
                      subscription.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subscription.currency} ${subscription.amount.toStringAsFixed(2)}/month',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Renews: ${DateFormat('MMM dd, yyyy').format(subscription.renewalDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
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