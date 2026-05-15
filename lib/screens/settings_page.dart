import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<List<Map<String, dynamic>>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() {
    _scheduleFuture = NotificationService.instance.getReminderSchedule();
  }

  Future<void> _changeReminderTime({
    required BuildContext context,
    required Map<String, dynamic> item,
    required MedicineProvider provider,
  }) async {
    final hour = item['hour'] as int;
    final minute = item['minute'] as int;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (selectedTime == null) return;

    /// SAVE NEW TIME
    await NotificationService.instance.saveReminderTime(
      index: item['index'] as int,
      hour: selectedTime.hour,
      minute: selectedTime.minute,
    );

    /// CANCEL OLD NOTIFICATIONS
    await NotificationService.instance.cancelAll();

    /// RESCHEDULE
    await NotificationService.instance.rescheduleMedicines(provider.medicines);

    /// RELOAD UI
    _loadSchedules();

    setState(() {});

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${item['label']} reminder updated to '
          '${selectedTime.format(context)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MedicineProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text('Settings'), centerTitle: true),

      body: ListView(
        padding: const EdgeInsets.all(24),

        children: [
          /// =========================
          /// HEADER
          /// =========================
          Container(
            padding: const EdgeInsets.all(22),

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,

                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),

              borderRadius: BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),

            child: const Row(
              children: [
                Icon(Icons.tune_rounded, color: Colors.white, size: 34),

                SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'App Preferences',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Personalize your medicine notebook.',

                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          /// =========================
          /// APPEARANCE
          /// =========================
          _buildSectionHeader('Appearance'),

          const SizedBox(height: 12),

          _buildPremiumPanel(
            child: SwitchListTile(
              title: const Text(
                'Dark Mode',

                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              subtitle: const Text('Use a darker theme for the app.'),

              value: provider.isDarkMode,

              activeThumbColor: AppColors.primary,

              onChanged: (_) {
                provider.toggleTheme();
              },
            ),
          ),

          const SizedBox(height: 32),

          /// =========================
          /// REMINDER SCHEDULE
          /// =========================
          _buildSectionHeader('Reminder Schedule'),

          const SizedBox(height: 12),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _scheduleFuture,

            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildPremiumPanel(
                  child: const Padding(
                    padding: EdgeInsets.all(30),

                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final scheduleMap = snapshot.data!;

              return _buildPremiumPanel(
                child: Column(
                  children: List.generate(scheduleMap.length, (i) {
                    final item = scheduleMap[i];

                    final hour = item['hour'] as int;

                    final minute = item['minute'] as int;

                    final timeText =
                        '${hour.toString().padLeft(2, '0')}:'
                        '${minute.toString().padLeft(2, '0')}';

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),

                          leading: Container(
                            padding: const EdgeInsets.all(10),

                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,

                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Icon(
                              Icons.access_time_rounded,
                              color: AppColors.primary,
                            ),
                          ),

                          title: Text(
                            item['label'].toString(),

                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),

                          subtitle: Text('$timeText Reminder Time'),

                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),

                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),

                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Text(
                              timeText,

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,

                                color: AppColors.primary,
                              ),
                            ),
                          ),

                          onTap: () async {
                            await _changeReminderTime(
                              context: context,
                              item: item,
                              provider: provider,
                            );
                          },
                        ),

                        if (i != scheduleMap.length - 1)
                          const Divider(
                            height: 1,
                            indent: 70,
                            endIndent: 20,
                            color: AppColors.border,
                          ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          /// =========================
          /// DATA MANAGEMENT
          /// =========================
          _buildSectionHeader('Data Management'),

          const SizedBox(height: 12),

          _buildPremiumPanel(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Icon(
                      Icons.backup_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),

                  title: const Text(
                    'Backup & Restore',

                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),

                  trailing: const Icon(Icons.chevron_right_rounded),

                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon!')),
                    );
                  },
                ),

                const Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 20,
                  color: AppColors.border,
                ),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.amber.shade700,
                    ),
                  ),

                  title: const Text(
                    'About App',

                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),

                  trailing: const Icon(Icons.chevron_right_rounded),

                  onTap: () {
                    showAboutDialog(
                      context: context,

                      applicationName: 'My Medicine Note',

                      applicationVersion: '1.0.0',

                      applicationLegalese:
                          'Offline medication tracking with reminders.',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),

      child: Text(
        title.toUpperCase(),

        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPremiumPanel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: AppColors.border.withOpacity(0.7)),

        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: child,
    );
  }
}
