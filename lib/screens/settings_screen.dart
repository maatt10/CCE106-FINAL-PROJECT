import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/theme_service.dart';
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
  final _themeService = ThemeService();
  final _auth = FirebaseAuth.instance;

  String _preferredCurrency = 'PHP';
  bool _darkMode = false;
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
      final results = await Future.wait([
        _settingsService.getPreferredCurrency(),
        _themeService.getDarkMode(),
      ]);
      if (!mounted) return;
      setState(() {
        _preferredCurrency = results[0] as String;
        _darkMode = results[1] as bool;
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

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _darkMode = value);
    try {
      await _themeService.setDarkMode(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _darkMode = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save theme preference.')),
      );
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

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
        child: Text(
          title.toUpperCase(),
          style: AppType.microLabel.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      );

  Widget _groupCard({required List<Widget> children}) {
    final colors = context.colors;
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) {
        spaced.add(Divider(height: 1, color: colors.border));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(children: spaced),
    );
  }

  TextStyle _titleStyle(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: context.colors.textPrimary,
      );

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final colors = context.colors;

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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.heroGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            'SIGNED IN AS',
                            style: AppType.microLabel.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              user?.email ?? 'Unknown account',
                              style: _titleStyle(context),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _sectionHeader('Appearance'),
                    _groupCard(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          secondary: Icon(
                            _darkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: AppColors.primaryLight,
                          ),
                          title: Text(
                            'Dark Mode',
                            style: _titleStyle(context),
                          ),
                          subtitle: const Text(
                            'Use a darker theme at night',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _darkMode,
                          onChanged: _toggleDarkMode,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _sectionHeader('Preferences'),
                    _groupCard(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: const Icon(
                            Icons.currency_exchange_rounded,
                            color: AppColors.primaryLight,
                          ),
                          title: Text(
                            'Preferred Currency',
                            style: _titleStyle(context),
                          ),
                          subtitle: const Text(
                            'Used for converted amounts',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: _isSavingCurrency
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primarySoft,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _preferredCurrency,
                                    underline: const SizedBox(),
                                    isDense: true,
                                    dropdownColor: colors.surface,
                                    icon: const Icon(
                                      Icons.expand_more,
                                      size: 18,
                                      color: AppColors.primaryLight,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppColors.primaryLight,
                          ),
                          title: Text(
                            'Reminder Settings',
                            style: _titleStyle(context),
                          ),
                          subtitle: const Text(
                            'Control renewal reminders',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: colors.textTertiary,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ReminderSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _sectionHeader('About'),
                    _groupCard(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primaryLight,
                          ),
                          title: Text(
                            'SubTrack',
                            style: _titleStyle(context),
                          ),
                          subtitle: const Text(
                            'Version 1.0.0',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow:
                            Theme.of(context).brightness == Brightness.dark
                                ? null
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.danger.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: colors.danger,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.danger,
                          ),
                        ),
                        subtitle: const Text(
                          'Sign out of your SubTrack account',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.danger,
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