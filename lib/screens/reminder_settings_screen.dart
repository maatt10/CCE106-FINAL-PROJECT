import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/user_settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final UserSettingsService _settings = UserSettingsService();

  bool _loading = true;
  bool _enabled = false;
  int _leadTimeDays = 3;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _settings.getReminderSettings();
    if (!mounted) return;
    setState(() {
      _enabled = s['remindersEnabled'] as bool;
      _leadTimeDays = s['leadTimeDays'] as int;
      _time = TimeOfDay(
        hour: s['reminderHour'] as int,
        minute: s['reminderMinute'] as int,
      );
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _settings.setReminderSettings(
      enabled: _enabled,
      leadTimeDays: _leadTimeDays,
      hour: _time.hour,
      minute: _time.minute,
    );
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are disabled in system settings. Enable them for SubTrack to receive reminders.',
            ),
          ),
        );
        return;
      }
    }
    setState(() => _enabled = value);
    await _persist();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() => _time = picked);
    await _persist();
  }

  String _leadLabel(int d) {
    if (d == 0) return 'On renewal day';
    if (d == 1) return '1 day before';
    return '$d days before';
  }

  Widget _sectionHeader(String title) => Padding(
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

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppBackground(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    // Status hero card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _enabled
                              ? AppColors.heroGradient
                              : [Colors.grey.shade400, Colors.grey.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: (_enabled
                                    ? AppColors.primary
                                    : Colors.grey)
                                .withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              _enabled
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_off_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _enabled
                                      ? 'Reminders are on'
                                      : 'Reminders are off',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _enabled
                                      ? 'You\'ll be notified before renewals.'
                                      : 'Enable to get renewal notifications.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _enabled,
                            onChanged: _toggle,
                            activeColor: Colors.white,
                            activeTrackColor: Colors.white.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    AnimatedOpacity(
                      opacity: _enabled ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_enabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('Timing'),

                            _card(
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.schedule_rounded,
                                      color: AppColors.primary,
                                    ),
                                    title: const Text(
                                      'Remind me',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _leadLabel(_leadTimeDays),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: DropdownButton<int>(
                                      value: _leadTimeDays,
                                      underline: const SizedBox(),
                                      icon: const Icon(
                                        Icons.expand_more,
                                        color: AppColors.primary,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 0, child: Text('Same day')),
                                        DropdownMenuItem(
                                            value: 1,
                                            child: Text('1 day before')),
                                        DropdownMenuItem(
                                            value: 2,
                                            child: Text('2 days before')),
                                        DropdownMenuItem(
                                            value: 3,
                                            child: Text('3 days before')),
                                        DropdownMenuItem(
                                            value: 5,
                                            child: Text('5 days before')),
                                        DropdownMenuItem(
                                            value: 7,
                                            child: Text('7 days before')),
                                      ],
                                      onChanged: (v) async {
                                        if (v == null) return;
                                        setState(() => _leadTimeDays = v);
                                        await _persist();
                                      },
                                    ),
                                  ),
                                  const Divider(height: 1, indent: 60),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.access_time_rounded,
                                      color: AppColors.primary,
                                    ),
                                    title: const Text(
                                      'Notification time',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _time.format(context),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textTertiary,
                                    ),
                                    onTap: _pickTime,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Footnote
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SubTrack schedules a local notification for each '
                              'active subscription. Cancelled and archived '
                              'subscriptions are skipped.',
                              style: TextStyle(
                                color: AppColors.primary.withOpacity(0.9),
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}