import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../utils/currency_utils.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final String? initialName;
  final String? initialPlanName;
  final double? initialPrice;
  final String? initialCurrency;
  final String? initialBillingCycle;
  final String? initialCategory;
  final String? initialLogoUrl;
  final String? initialCardColor;

  // Used when editing an existing subscription.
  final Subscription? initialSubscription;

  const AddSubscriptionScreen({
    super.key,
    this.initialName,
    this.initialPlanName,
    this.initialPrice,
    this.initialCurrency,
    this.initialBillingCycle,
    this.initialCategory,
    this.initialLogoUrl,
    this.initialCardColor,
    this.initialSubscription,
  });

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _priceController = TextEditingController();

  String _planName = '';
  String _currency = 'PHP';
  String _billingCycle = 'Monthly';
  String _category = 'Other';

  String _logoUrl = '';

  // Null means automatic color.
  String? _cardColor;

  DateTime _startDate = DateTime.now();

  final List<Color> _availableColors = const [
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.red,
    Colors.amber,
  ];

  DateTime get _renewalDate {
    if (_billingCycle == 'Weekly') {
      return _startDate.add(const Duration(days: 7));
    }

    if (_billingCycle == 'Yearly') {
      final nextYear = _startDate.year + 1;

      final lastDayOfMonth = DateTime(nextYear, _startDate.month + 1, 0).day;

      return DateTime(
        nextYear,
        _startDate.month,
        _startDate.day > lastDayOfMonth ? lastDayOfMonth : _startDate.day,
      );
    }

    final nextMonth = _startDate.month == 12 ? 1 : _startDate.month + 1;

    final nextYear = _startDate.month == 12
        ? _startDate.year + 1
        : _startDate.year;

    final lastDayOfMonth = DateTime(nextYear, nextMonth + 1, 0).day;

    return DateTime(
      nextYear,
      nextMonth,
      _startDate.day > lastDayOfMonth ? lastDayOfMonth : _startDate.day,
    );
  }

  bool get _isEditing => widget.initialSubscription != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.initialSubscription;

    if (existing != null) {
      _nameController.text = existing.name;

      _priceController.text = existing.price.toStringAsFixed(2);

      _planName = existing.planName;
      _currency = existing.currency;
      _billingCycle = existing.billingCycle;
      _category = existing.category;

      _logoUrl = existing.logoUrl;
      _cardColor = existing.cardColor;

      _startDate = existing.startDate;
    } else {
      _nameController.text = widget.initialName ?? '';

      if (widget.initialPrice != null) {
        _priceController.text = widget.initialPrice!.toStringAsFixed(2);
      }

      _planName = widget.initialPlanName ?? '';

      _currency = widget.initialCurrency ?? 'PHP';

      _billingCycle = widget.initialBillingCycle ?? 'Monthly';

      _category = widget.initialCategory ?? 'Other';

      _logoUrl = widget.initialLogoUrl ?? '';

      _cardColor = widget.initialCardColor;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _saveSubscription() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = double.tryParse(_priceController.text.trim());

    if (price == null) {
      return;
    }

    final subscription = Subscription(
      name: _nameController.text.trim(),
      planName: _planName,
      price: price,
      currency: _currency,
      billingCycle: _billingCycle,
      startDate: _startDate,
      renewalDate: _renewalDate,
      category: _category,
      logoUrl: _logoUrl,
      cardColor: _cardColor,
    );

    debugPrint(
      'SAVING SUBSCRIPTION: ${subscription.name} | '
      'logoUrl=${subscription.logoUrl}',
    );

    Navigator.pop(context, subscription);
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _autoPreviewColor() {
    const colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.deepOrange,
      Colors.deepPurple,
    ];

    int hash = 0;

    for (final character in _nameController.text.codeUnits) {
      hash = character + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  Color _previewColor() {
    if (_cardColor == null) {
      return _autoPreviewColor();
    }

    try {
      return Color(
        int.parse('FF${_cardColor!.replaceAll('#', '')}', radix: 16),
      );
    } catch (_) {
      return _autoPreviewColor();
    }
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32();

    return value.toRadixString(16).substring(2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = _previewColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Subscription' : 'Add Subscription'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              onChanged: (_) {
                if (_cardColor == null) {
                  setState(() {});
                }
              },
              decoration: const InputDecoration(
                labelText: 'Subscription Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subscriptions_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subscription name.';
                }

                return null;
              },
            ),

            if (_planName.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _planName,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Plan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.layers_outlined),
                ),
              ),
            ],

            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Price',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.payments_outlined),
                prefixText: '${CurrencyUtils.getSymbol(_currency)} ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price.';
                }

                final price = double.tryParse(value.trim());

                if (price == null || price < 0) {
                  return 'Please enter a valid price.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'PHP',
                  child: Text('PHP — Philippine Peso'),
                ),
                DropdownMenuItem(value: 'USD', child: Text('USD — US Dollar')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR — Euro')),
                DropdownMenuItem(
                  value: 'GBP',
                  child: Text('GBP — British Pound'),
                ),
                DropdownMenuItem(
                  value: 'JPY',
                  child: Text('JPY — Japanese Yen'),
                ),
                DropdownMenuItem(value: 'KRW', child: Text('KRW — Korean Won')),
                DropdownMenuItem(
                  value: 'SGD',
                  child: Text('SGD — Singapore Dollar'),
                ),
                DropdownMenuItem(
                  value: 'AUD',
                  child: Text('AUD — Australian Dollar'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _currency = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _billingCycle,
              decoration: const InputDecoration(
                labelText: 'Billing Cycle',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _billingCycle = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Entertainment',
                  child: Text('Entertainment'),
                ),
                DropdownMenuItem(value: 'Music', child: Text('Music')),
                DropdownMenuItem(value: 'Gaming', child: Text('Gaming')),
                DropdownMenuItem(
                  value: 'Productivity',
                  child: Text('Productivity'),
                ),
                DropdownMenuItem(value: 'Education', child: Text('Education')),
                DropdownMenuItem(
                  value: 'Cloud Storage',
                  child: Text('Cloud Storage'),
                ),
                DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _category = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // Card appearance
            const Text(
              'Card Appearance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: previewColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: previewColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: previewColor.withOpacity(0.18),
                    child: _logoUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              _logoUrl,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return Text(
                                  _nameController.text.isEmpty
                                      ? '?'
                                      : _nameController.text[0].toUpperCase(),
                                  style: TextStyle(
                                    color: previewColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            _nameController.text.isEmpty
                                ? '?'
                                : _nameController.text[0].toUpperCase(),
                            style: TextStyle(
                              color: previewColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.trim().isEmpty
                              ? 'Subscription Preview'
                              : _nameController.text.trim(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _cardColor == null
                              ? 'Automatic color'
                              : 'Custom color',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            RadioListTile<String?>(
              contentPadding: EdgeInsets.zero,
              value: null,
              groupValue: _cardColor,
              title: const Text('Auto-fill color'),
              subtitle: const Text(
                'Let SubTrack choose a color automatically.',
              ),
              onChanged: (_) {
                setState(() {
                  _cardColor = null;
                });
              },
            ),

            RadioListTile<String?>(
              contentPadding: EdgeInsets.zero,
              value: 'custom',
              groupValue: _cardColor == null ? null : 'custom',
              title: const Text('Choose a color'),
              subtitle: const Text('Use your own card color.'),
              onChanged: (_) {
                if (_cardColor == null) {
                  setState(() {
                    _cardColor = _colorToHex(_autoPreviewColor());
                  });
                }
              },
            ),

            if (_cardColor != null) ...[
              const SizedBox(height: 4),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableColors.map((color) {
                  final hex = _colorToHex(color);

                  final selected = _cardColor == hex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _cardColor = hex;
                      });
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            InkWell(
              onTap: _selectStartDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(_formatDate(_startDate)),
              ),
            ),

            const SizedBox(height: 16),

            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Next Renewal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event_repeat_outlined),
              ),
              child: Text(_formatDate(_renewalDate)),
            ),

            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: _saveSubscription,
              icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
              label: Text(_isEditing ? 'Save Changes' : 'Add Subscription'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
