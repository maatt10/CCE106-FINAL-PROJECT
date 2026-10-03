import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import '../widgets/app_background.dart';
import 'reminder_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = UserSettingsService();
  final _auth = FirebaseAuth.instance;

  String _preferredCurrency = 'PHP';
  bool _isLoading = true;
  bool _isSavingCurrency = false;

  final List<String> _currencies = const [
    'PHP', 'USD', 'EUR', 'GBP', 'JPY', 'KRW', 'SGD', 'AUD',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final currency = await _settingsService.getPreferredCurrency();
      if (!mounted) return;
      setState(() {
        _preferredCurrency = currency;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load your settings.')),
      );
    }
  }

  Future<void> _changeCurrency(String currency) async {
    if (_isSavingCurrency) return;
    final previous = _preferredCurrency;
    setState(() {
      _preferredCurrency = currency;
      _isSavingCurrency = true;
    });
    try {
      await _settingsService.setPreferredCurrency(currency);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferred currency changed to $currency.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _preferredCurrency = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save currency preference.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingCurrency = false);
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of SubTrack?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _groupCard({required List<Widget> children}) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) {
        spaced.add(const Divider(height: 1, indent: 60));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Column(children: spaced),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AppBackground(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _sectionHeader('Account'),
                    _groupCard(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.heroGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          title: const Text(
                            'Signed in as',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            user?.email ?? 'Unknown account',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _sectionHeader('Preferences'),
                    _groupCard(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.currency_exchange_rounded,
                            color: AppColors.primary,
                          ),
                          title: const Text(
                            'Preferred Currency',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Used for converted amounts',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: _isSavingCurrency
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _preferredCurrency,
                                    underline: const SizedBox(),
                                    isDense: true,
                                    icon: const Icon(
                                      Icons.expand_more,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                    items: _currencies.map((c) {
                                      return DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          '${CurrencyUtils.getSymbol(c)} $c',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) _changeCurrency(v);
                                    },
                                  ),
                                ),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppColors.primary,
                          ),
                          title: const Text(
                            'Reminder Settings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Control renewal reminders',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textTertiary,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReminderSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _sectionHeader('About'),
                    _groupCard(
                      children: const [
                        ListTile(
                          leading: Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'SubTrack',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Version 1.0.0',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.15),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.danger,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                        subtitle: const Text(
                          'Sign out of your SubTrack account',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.danger,
                        ),
                        onTap: _logout,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}