import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import '../widgets/app_background.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final String? initialName;
  final String? initialPlanName;
  final String? initialCurrency;
  final String? initialCategory;
  final String? initialLogoUrl;
  final String? initialCardColor;
  final Subscription? initialSubscription;

  /// For popular subs: map of cycle → price.
  /// When provided, the cycle dropdown is filtered to these cycles,
  /// and the price auto-fills when the cycle changes.
  final Map<String, double>? priceByCycle;

  const AddSubscriptionScreen({
    super.key,
    this.initialName,
    this.initialPlanName,
    this.initialCurrency,
    this.initialCategory,
    this.initialLogoUrl,
    this.initialCardColor,
    this.initialSubscription,
    this.priceByCycle,
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

  /// Master list — includes Semi-Annual now.
  static const List<String> _allCycles = [
    'Weekly',
    'Monthly',
    'Semi-Annual',
    'Yearly',
  ];

  /// Display order used when a plan's available cycles are sorted.
  static const List<String> _cycleDisplayOrder = [
    'Weekly',
    'Monthly',
    'Semi-Annual',
    'Yearly',
  ];

  final _colors = const [
    Color(0xFF6C4CE0),
    Color(0xFFEC4899),
    Color(0xFF0EA5E9),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF6366F1),
    Color(0xFF84CC16),
  ];

  /// The cycles the user is allowed to pick.
  /// For catalog plans: only the cycles present in priceByCycle.
  /// For custom subs: everything in _allCycles.
  List<String> get _allowedCycles {
    if (widget.priceByCycle != null && widget.priceByCycle!.isNotEmpty) {
      return _cycleDisplayOrder
          .where((c) => widget.priceByCycle!.containsKey(c))
          .toList();
    }
    return List.from(_allCycles);
  }

  DateTime get _renewalDate {
    final m = _startDate.month;
    final y = _startDate.year;

    // Add N months to the start date, clamping the day to the last
    // valid day of the target month.
    DateTime addMonths(DateTime date, int months) {
      final targetMonth = date.month + months;
      final targetYear = date.year + ((targetMonth - 1) ~/ 12);
      final normalizedMonth = ((targetMonth - 1) % 12) + 1;
      final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
      return DateTime(
        targetYear,
        normalizedMonth,
        date.day > lastDay ? lastDay : date.day,
      );
    }

    switch (_billingCycle) {
      case 'Weekly':
        return _startDate.add(const Duration(days: 7));
      case 'Monthly':
        return addMonths(_startDate, 1);
      case 'Semi-Annual':
        return addMonths(_startDate, 6);
      case 'Yearly':
        return addMonths(_startDate, 12);
      default:
        return addMonths(_startDate, 1);
    }
  }

  bool get _isEditing => widget.initialSubscription != null;

  bool get _isFromCatalog {
    final existing = widget.initialSubscription;
    if (existing != null && existing.logoUrl.isNotEmpty) return true;
    if (_logoUrl.isNotEmpty) return true;
    return false;
  }

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
      _planName = widget.initialPlanName ?? '';
      _currency = widget.initialCurrency ?? 'PHP';
      _category = widget.initialCategory ?? 'Other';
      _logoUrl = widget.initialLogoUrl ?? '';
      _cardColor = widget.initialCardColor;

      if (widget.priceByCycle != null && widget.priceByCycle!.isNotEmpty) {
        final allowed = _allowedCycles;
        if (allowed.contains('Monthly')) {
          _billingCycle = 'Monthly';
        } else if (allowed.isNotEmpty) {
          _billingCycle = allowed.first;
        }

        final price = widget.priceByCycle![_billingCycle];
        if (price != null) {
          _priceController.text = price.toStringAsFixed(2);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// When the cycle changes, swap the price if a catalog price exists.
  void _onCycleChanged(String newCycle) {
    setState(() {
      _billingCycle = newCycle;

      if (widget.priceByCycle != null &&
          widget.priceByCycle!.containsKey(newCycle)) {
        _priceController.text =
            widget.priceByCycle![newCycle]!.toStringAsFixed(2);
      }
    });
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
        cardColor: _isFromCatalog ? null : _cardColor,
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}';

  Color _autoColor() {
    const c = [
      Color(0xFF6C4CE0),
      Color(0xFFEC4899),
      Color(0xFF0EA5E9),
      Color(0xFF16A34A),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
    ];
    int hash = 0;
    for (final x in _nameController.text.codeUnits) {
      hash = x + ((hash << 5) - hash);
    }
    return c[hash.abs() % c.length];
  }

  bool get _isCustomColor => _cardColor != null;

  Color _previewColor() {
    if (_isFromCatalog) {
      return const Color(0xFF6C4CE0);
    }
    if (_cardColor == null) return _autoColor();
    try {
      return Color(
        int.parse('FF${_cardColor!.replaceAll('#', '')}', radix: 16),
      );
    } catch (_) {
      return _autoColor();
    }
  }

  String _colorHex(Color c) =>
      c.toARGB32().toRadixString(16).substring(2).toUpperCase();

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 24),
        child: Text(
          text.toUpperCase(),
          style: AppType.microLabel.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      );

  Widget _lockedField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
  }) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colors.textTertiary),
        filled: true,
        fillColor: isDark
            ? colors.surfaceElevated.withOpacity(0.5)
            : colors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: colors.textTertiary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = _previewColor();
    final allowed = _allowedCycles;
    final cycleLocked = allowed.length == 1;

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
                if (_planName.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? AppColors.heroGradientDark
                            : AppColors.heroGradient,
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

                _sectionLabel(context, 'Basic Information'),

                TextFormField(
                  controller: _nameController,
                  onChanged: (_) {
                    if (!_isFromCatalog && _cardColor == null) {
                      setState(() {});
                    }
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

                _sectionLabel(context, 'Billing'),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _currency,
                        isExpanded: true,
                        dropdownColor: colors.surface,
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
                      child: cycleLocked
                          ? _lockedField(
                              context,
                              label: 'Cycle',
                              icon: Icons.repeat_outlined,
                              value: allowed.first,
                            )
                          : DropdownButtonFormField<String>(
                              value: allowed.contains(_billingCycle)
                                  ? _billingCycle
                                  : allowed.first,
                              isExpanded: true,
                              dropdownColor: colors.surface,
                              decoration: const InputDecoration(
                                labelText: 'Cycle',
                                prefixIcon: Icon(Icons.repeat_outlined),
                              ),
                              items: allowed.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) _onCycleChanged(v);
                              },
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _category,
                  dropdownColor: colors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Category',
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
                    DropdownMenuItem(
                      value: 'Education',
                      child: Text('Education'),
                    ),
                    DropdownMenuItem(
                      value: 'Cloud Storage',
                      child: Text('Cloud Storage'),
                    ),
                    DropdownMenuItem(
                      value: 'Shopping',
                      child: Text('Shopping'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),

                _sectionLabel(context, 'Schedule'),

                InkWell(
                  onTap: _selectStartDate,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      _formatDate(_startDate),
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Next Renewal',
                    prefixIcon: const Icon(Icons.event_repeat_outlined),
                    enabled: false,
                    fillColor: isDark
                        ? colors.surfaceElevated.withOpacity(0.5)
                        : colors.bg,
                  ),
                  child: Text(
                    _formatDate(_renewalDate),
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),

                if (!_isFromCatalog) ...[
                  _sectionLabel(context, 'Card Appearance'),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: preview.withOpacity(isDark ? 0.14 : 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: preview.withOpacity(isDark ? 0.35 : 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                preview,
                                preview.withOpacity(0.75),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: Text(
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
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${CurrencyUtils.getSymbol(_currency)} '
                                '${_priceController.text.isEmpty ? '0.00' : _priceController.text}'
                                ' / ${_billingCycle.toLowerCase()}',
                                style: TextStyle(
                                  color: colors.textSecondary,
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

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.surfaceElevated
                          : colors.bg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _segmentButton(
                            context,
                            label: 'Auto',
                            icon: Icons.auto_awesome_rounded,
                            selected: !_isCustomColor,
                            onTap: () =>
                                setState(() => _cardColor = null),
                          ),
                        ),
                        Expanded(
                          child: _segmentButton(
                            context,
                            label: 'Custom',
                            icon: Icons.palette_outlined,
                            selected: _isCustomColor,
                            onTap: () {
                              if (_cardColor == null) {
                                setState(
                                  () => _cardColor =
                                      _colorHex(_autoColor()),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isCustomColor) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colors.map((c) {
                        final hex = _colorHex(c);
                        final selected = _cardColor == hex;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _cardColor = hex),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? colors.textPrimary
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: c.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
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

  Widget _segmentButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: selected ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                  color: selected ? Colors.white : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}