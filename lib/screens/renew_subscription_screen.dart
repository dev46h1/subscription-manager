import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';

class RenewSubscriptionScreen extends StatefulWidget {
  final Subscription subscription;

  const RenewSubscriptionScreen({
    Key? key,
    required this.subscription,
  }) : super(key: key);

  @override
  State<RenewSubscriptionScreen> createState() => _RenewSubscriptionScreenState();
}

class _RenewSubscriptionScreenState extends State<RenewSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  
  DateTime? _selectedRenewalDate;
  bool _isRenewing = false;
  bool _useSmartDate = true;
  bool _keepSameAmount = true;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.subscription.amount.toString(),
    );
    _notesController = TextEditingController(text: widget.subscription.notes ?? '');
    
    // Initialize with smart renewal date
    _selectedRenewalDate = widget.subscription.getSmartRenewalDate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectRenewalDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedRenewalDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Select Next Renewal Date',
    );
    
    if (picked != null) {
      setState(() {
        _selectedRenewalDate = picked;
        _useSmartDate = false; // User manually selected a date
      });
    }
  }

  void _useSmartRenewalDate() {
    setState(() {
      _selectedRenewalDate = widget.subscription.getSmartRenewalDate();
      _useSmartDate = true;
    });
  }

  int _calculateDaysUntilRenewal(DateTime renewalDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final renewal = DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
    return renewal.difference(today).inDays;
  }

  void _renewSubscription() async {
    if (_formKey.currentState!.validate() && _selectedRenewalDate != null) {
      setState(() {
        _isRenewing = true;
      });

      try {
        final newAmount = _keepSameAmount 
            ? widget.subscription.amount 
            : double.parse(_amountController.text);
        
        final renewedSubscription = widget.subscription.createRenewed(
          newRenewalDate: _selectedRenewalDate!,
          newAmount: newAmount,
          newNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        final provider = context.read<SubscriptionProvider>();
        await provider.updateSubscription(renewedSubscription);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.subscription.name} renewed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate successful renewal
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error renewing subscription: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRenewing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.subscription.isOverdue;
    final currentDaysRemaining = widget.subscription.daysUntilRenewal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renew Subscription'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current subscription info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOverdue 
                    ? Colors.red.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOverdue 
                      ? Colors.red.withOpacity(0.3)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.warning : Icons.subscriptions,
                        color: isOverdue ? Colors.red : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.subscription.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current: ${widget.subscription.currency} ${widget.subscription.amount.toStringAsFixed(2)}${widget.subscription.billingPeriodDisplayText}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOverdue
                        ? 'Overdue by ${currentDaysRemaining.abs()} day${currentDaysRemaining.abs() == 1 ? '' : 's'}'
                        : currentDaysRemaining == 0
                            ? 'Due today'
                            : 'Due in $currentDaysRemaining day${currentDaysRemaining == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Renewal date selection
            Text(
              'Renewal Date',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Smart date suggestion
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Suggestion',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Next ${widget.subscription.billingPeriod.displayName.toLowerCase()} cycle: ${DateFormat('MMMM dd, yyyy').format(widget.subscription.getSmartRenewalDate())}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _useSmartRenewalDate,
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          label: const Text('Use Smart Date'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manual date selection
            InkWell(
              onTap: _selectRenewalDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Custom Renewal Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  fillColor: _useSmartDate 
                      ? Colors.grey.withOpacity(0.1) 
                      : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                  filled: true,
                ),
                child: Text(
                  _selectedRenewalDate != null
                      ? DateFormat('MMMM dd, yyyy').format(_selectedRenewalDate!)
                      : 'Select date',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _selectedRenewalDate != null 
                        ? null 
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),

            if (_selectedRenewalDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        () {
                          final days = _calculateDaysUntilRenewal(_selectedRenewalDate!);
                          if (days == 0) {
                            return 'Will be due today';
                          } else if (days == 1) {
                            return 'Will be due in 1 day';
                          } else {
                            return 'Will be due in $days days';
                          }
                        }(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Amount section
            Text(
              'Renewal Amount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Keep same amount toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keep Same Amount',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.subscription.currency} ${widget.subscription.amount.toStringAsFixed(2)}${widget.subscription.billingPeriodDisplayText}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _keepSameAmount,
                    onChanged: (value) {
                      setState(() {
                        _keepSameAmount = value;
                        if (value) {
                          _amountController.text = widget.subscription.amount.toString();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            if (!_keepSameAmount) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'New Amount',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: const OutlineInputBorder(),
                  suffix: Text(widget.subscription.currency),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Invalid amount';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            // Notes section
            Text(
              'Renewal Notes (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Add any notes about this renewal...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRenewing ? null : _renewSubscription,
                    icon: _isRenewing 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isRenewing ? 'Renewing...' : 'Renew Subscription',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}