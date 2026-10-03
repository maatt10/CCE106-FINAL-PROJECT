import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_settings_service.dart';
import '../utils/currency_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserSettingsService _settingsService = UserSettingsService();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _preferredCurrency = 'PHP';
  bool _isLoading = true;
  bool _isSavingCurrency = false;

  final List<String> _currencies = [
    'PHP',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'KRW',
    'SGD',
    'AUD',
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load your settings.')),
      );
    }
  }

  Future<void> _changeCurrency(String currency) async {
    if (_isSavingCurrency) return;

    final previousCurrency = _preferredCurrency;

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _preferredCurrency = previousCurrency;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save currency preference.')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSavingCurrency = false;
      });
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out of SubTrack?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: const Text('Signed in as'),
                    subtitle: Text(user?.email ?? 'Unknown account'),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Preferences',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: const Text('Preferred Currency'),
                    subtitle: Text(
                      'Used when displaying converted subscription amounts.',
                    ),
                    trailing: _isSavingCurrency
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : DropdownButton<String>(
                            value: _preferredCurrency,
                            underline: const SizedBox(),
                            items: _currencies.map((currency) {
                              return DropdownMenuItem<String>(
                                value: currency,
                                child: Text(
                                  '${CurrencyUtils.getSymbol(currency)} '
                                  '$currency',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _changeCurrency(value);
                              }
                            },
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log Out'),
                    subtitle: const Text('Sign out of your SubTrack account.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _logout,
                  ),
                ),
              ],
            ),
    );
  }
}
