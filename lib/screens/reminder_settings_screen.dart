import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/user_settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
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

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
        child: Text(
          title.toUpperCase(),
          style: AppType.microLabel.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      );

  Widget _card(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: colors.textPrimary,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppBackground(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _enabled
                              ? (isDark
                                  ? AppColors.heroGradientDark
                                  : AppColors.heroGradient)
                              : (isDark
                                  ? const [
                                      Color(0xFF3A3A55),
                                      Color(0xFF4A4A66),
                                    ]
                                  : const [
                                      Color(0xFF8E8EA8),
                                      Color(0xFFB0B0C4),
                                    ]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: (_enabled
                                    ? AppColors.primary
                                    : Colors.grey)
                                .withOpacity(0.28),
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
                                  _enabled ? 'REMINDERS ON' : 'REMINDERS OFF',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _enabled
                                      ? 'You\'ll be notified before renewals.'
                                      : 'Enable to get renewal notifications.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _enabled,
                            onChanged: _toggle,
                            activeColor: Colors.white,
                            activeTrackColor:
                                Colors.white.withOpacity(0.4),
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
                            _sectionHeader(context, 'Timing'),
                            _card(
                              context,
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Icon(
                                      Icons.schedule_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    title: Text('Remind me',
                                        style: titleStyle),
                                    subtitle: Text(
                                      _leadLabel(_leadTimeDays),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    trailing: DropdownButton<int>(
                                      value: _leadTimeDays,
                                      underline: const SizedBox(),
                                      dropdownColor: colors.surface,
                                      icon: Icon(
                                        Icons.expand_more,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 0,
                                          child: Text('Same day'),
                                        ),
                                        DropdownMenuItem(
                                          value: 1,
                                          child: Text('1 day before'),
                                        ),
                                        DropdownMenuItem(
                                          value: 2,
                                          child: Text('2 days before'),
                                        ),
                                        DropdownMenuItem(
                                          value: 3,
                                          child: Text('3 days before'),
                                        ),
                                        DropdownMenuItem(
                                          value: 5,
                                          child: Text('5 days before'),
                                        ),
                                        DropdownMenuItem(
                                          value: 7,
                                          child: Text('7 days before'),
                                        ),
                                      ],
                                      onChanged: (v) async {
                                        if (v == null) return;
                                        setState(() => _leadTimeDays = v);
                                        await _persist();
                                      },
                                    ),
                                  ),
                                  Divider(height: 1, color: colors.border),
                                  ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Icon(
                                      Icons.access_time_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    title: Text('Notification time',
                                        style: titleStyle),
                                    subtitle: Text(
                                      _time.format(context),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: colors.textTertiary,
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

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SubTrack schedules a local notification for '
                              'each active subscription. Cancelled and '
                              'archived subscriptions are skipped.',
                              style: TextStyle(
                                color: isDark
                                    ? colors.textPrimary
                                    : AppColors.primary.withOpacity(0.9),
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
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