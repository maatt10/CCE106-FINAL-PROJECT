import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import '../widgets/app_background.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final String? initialName;
  final String? initialPlanName;
  final double? initialPrice;
  final String? initialCurrency;
  final String? initialBillingCycle;
  final String? initialCategory;
  final String? initialLogoUrl;
  final String? initialCardColor;
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
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String _planName = '';
  String _currency = 'PHP';
  String _billingCycle = 'Monthly';
  String _category = 'Other';
  String _logoUrl = '';
  String? _cardColor;
  DateTime _startDate = DateTime.now();

  final _colors = const [
    Colors.blue, Colors.purple, Colors.green, Colors.orange,
    Colors.teal, Colors.indigo, Colors.pink, Colors.cyan,
    Colors.deepOrange, Colors.deepPurple, Colors.red, Colors.amber,
  ];

  DateTime get _renewalDate {
    if (_billingCycle == 'Weekly') {
      return _startDate.add(const Duration(days: 7));
    }
    if (_billingCycle == 'Yearly') {
      final y = _startDate.year + 1;
      final lastDay = DateTime(y, _startDate.month + 1, 0).day;
      return DateTime(
        y,
        _startDate.month,
        _startDate.day > lastDay ? lastDay : _startDate.day,
      );
    }
    final m = _startDate.month == 12 ? 1 : _startDate.month + 1;
    final y = _startDate.month == 12 ? _startDate.year + 1 : _startDate.year;
    final lastDay = DateTime(y, m + 1, 0).day;
    return DateTime(
      y,
      m,
      _startDate.day > lastDay ? lastDay : _startDate.day,
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
    if (picked != null) setState(() => _startDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceController.text.trim());
    if (price == null) return;

    Navigator.pop(
      context,
      Subscription(
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
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}';

  Color _autoColor() {
    const c = [
      Color(0xFF6C4CE0), Color(0xFFEC4899), Color(0xFF0EA5E9),
      Color(0xFF16A34A), Color(0xFFF59E0B), Color(0xFF8B5CF6),
    ];
    int hash = 0;
    for (final x in _nameController.text.codeUnits) {
      hash = x + ((hash << 5) - hash);
    }
    return c[hash.abs() % c.length];
  }

  Color _previewColor() {
    if (_cardColor == null) return _autoColor();
    try {
      return Color(int.parse('FF${_cardColor!.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _autoColor();
    }
  }

  String _colorHex(Color c) =>
      c.toARGB32().toRadixString(16).substring(2).toUpperCase();

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 24),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textTertiary,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final preview = _previewColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Subscription' : 'Add Subscription'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // Plan chip (only when from catalog)
                if (_planName.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.heroGradient,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.layers_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _planName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                _sectionLabel('Basic Information'),

                TextFormField(
                  controller: _nameController,
                  onChanged: (_) {
                    if (_cardColor == null) setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Subscription Name',
                    prefixIcon: Icon(Icons.subscriptions_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    prefixText: '${CurrencyUtils.getSymbol(_currency)} ',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final p = double.tryParse(v.trim());
                    if (p == null || p < 0) return 'Invalid price';
                    return null;
                  },
                ),

                _sectionLabel('Billing'),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _currency,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          prefixIcon: Icon(Icons.currency_exchange),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'PHP', child: Text('PHP')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                          DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                          DropdownMenuItem(value: 'KRW', child: Text('KRW')),
                          DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                          DropdownMenuItem(value: 'AUD', child: Text('AUD')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _currency = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _billingCycle,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cycle',
                          prefixIcon: Icon(Icons.repeat_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _billingCycle = v);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                    DropdownMenuItem(value: 'Music', child: Text('Music')),
                    DropdownMenuItem(value: 'Gaming', child: Text('Gaming')),
                    DropdownMenuItem(value: 'Productivity', child: Text('Productivity')),
                    DropdownMenuItem(value: 'Education', child: Text('Education')),
                    DropdownMenuItem(value: 'Cloud Storage', child: Text('Cloud Storage')),
                    DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),

                _sectionLabel('Schedule'),

                InkWell(
                  onTap: _selectStartDate,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(_formatDate(_startDate)),
                  ),
                ),

                const SizedBox(height: 12),

                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Next Renewal',
                    prefixIcon: Icon(Icons.event_repeat_outlined),
                    enabled: false,
                  ),
                  child: Text(_formatDate(_renewalDate)),
                ),

                _sectionLabel('Card Appearance'),

                // Preview card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: preview.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: preview.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [preview, preview.withOpacity(0.75)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        alignment: Alignment.center,
                        child: _logoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                child: Image.network(
                                  _logoUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    _nameController.text.isEmpty
                                        ? '?'
                                        : _nameController.text[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                _nameController.text.isEmpty
                                    ? '?'
                                    : _nameController.text[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.trim().isEmpty
                                  ? 'Preview'
                                  : _nameController.text.trim(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${CurrencyUtils.getSymbol(_currency)} '
                              '${_priceController.text.isEmpty ? '0.00' : _priceController.text}'
                              ' / ${_billingCycle.toLowerCase()}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _card(
                  child: Column(
                    children: [
                      RadioListTile<String?>(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        value: null,
                        groupValue: _cardColor,
                        title: const Text(
                          'Auto-fill color',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Let SubTrack choose automatically',
                          style: TextStyle(fontSize: 12),
                        ),
                        onChanged: (_) => setState(() => _cardColor = null),
                      ),
                      const Divider(height: 1, indent: 60),
                      RadioListTile<String?>(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        value: 'custom',
                        groupValue: _cardColor == null ? null : 'custom',
                        title: const Text(
                          'Choose a color',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Use your own card color',
                          style: TextStyle(fontSize: 12),
                        ),
                        onChanged: (_) {
                          if (_cardColor == null) {
                            setState(
                              () => _cardColor = _colorHex(_autoColor()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                if (_cardColor != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colors.map((c) {
                      final hex = _colorHex(c);
                      final selected = _cardColor == hex;
                      return GestureDetector(
                        onTap: () => setState(() => _cardColor = hex),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.textPrimary
                                  : Colors.transparent,
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

                const SizedBox(height: 28),

                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      _isEditing ? Icons.save_outlined : Icons.add_rounded,
                    ),
                    label: Text(
                      _isEditing ? 'Save Changes' : 'Add Subscription',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        ),
        child: child,
      );
}