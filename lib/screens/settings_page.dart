import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_provider.dart';
import '../screens/backup_screen.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<List<Map<String, dynamic>>> _scheduleFuture;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    _loadNotificationPreferences();
  }

  void _loadSchedules() {
    _scheduleFuture = NotificationService.instance.getReminderSchedule();
  }

  Future<void> _loadNotificationPreferences() async {
    final enabled = await NotificationService.instance
        .getNotificationsEnabled();
    final sound = await NotificationService.instance.getSoundEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _soundEnabled = sound;
    });
  }

  Future<void> _setNotificationsEnabled(
    bool enabled,
    MedicineProvider provider,
  ) async {
    await NotificationService.instance.setNotificationsEnabled(enabled);

    if (!enabled) {
      await NotificationService.instance.cancelAll();
    } else {
      await NotificationService.instance.rescheduleMedicines(
        provider.medicines,
      );
      await provider.refreshNextDoseMedicines();
    }

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _setSoundEnabled(bool enabled, MedicineProvider provider) async {
    await NotificationService.instance.setSoundEnabled(enabled);
    await NotificationService.instance.cancelAll();
    await NotificationService.instance.rescheduleMedicines(provider.medicines);

    if (!mounted) return;
    setState(() {
      _soundEnabled = enabled;
    });
  }

  Future<void> _changeReminderTime({
    required BuildContext context,
    required Map<String, dynamic> item,
    required MedicineProvider provider,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: item['hour'], minute: item['minute']),
    );

    if (selected == null) return;

    try {
      /// 1. SAVE NEW TIME
      await NotificationService.instance.saveReminderTime(
        index: item['index'],
        hour: selected.hour,
        minute: selected.minute,
      );

      /// 2. CLEAR OLD NOTIFICATIONS
      await NotificationService.instance.cancelAll();

      /// 3. RESCHEDULE ALL MEDICINES
      await NotificationService.instance.rescheduleMedicines(
        provider.medicines,
      );

      /// 4. REFRESH NEXT DOSE
      await provider.refreshNextDoseMedicines();

      /// 5. REFRESH UI
      _loadSchedules();

      setState(() {});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          content: Text(
            "${item['label']} updated → ${selected.format(context)}",
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MedicineProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),

        children: [
          _header(),

          const SizedBox(height: 18),

          _sectionTitle("Appearance"),

          const SizedBox(height: 10),

          _card(
            child: SwitchListTile(
              value: provider.isDarkMode,

              onChanged: (_) {
                provider.toggleTheme();
              },

              activeThumbColor: AppColors.primary,

              title: const Text(
                "Dark Mode",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              subtitle: const Text("Enable dark theme"),
            ),
          ),

          const SizedBox(height: 20),

          _sectionTitle("Notifications"),

          const SizedBox(height: 10),

          _card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  activeThumbColor: AppColors.primary,
                  title: const Text(
                    "Medicine Notifications",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Enable or disable reminder alerts"),
                  onChanged: (value) =>
                      _setNotificationsEnabled(value, provider),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _soundEnabled,
                  activeThumbColor: AppColors.primary,
                  title: const Text(
                    "Notification Sound",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Turn notification sound on or off"),
                  onChanged: _notificationsEnabled
                      ? (value) => _setSoundEnabled(value, provider)
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _sectionTitle("Reminder Schedule"),

          const SizedBox(height: 10),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _scheduleFuture,

            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _card(
                  child: const Padding(
                    padding: EdgeInsets.all(24),

                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final data = snapshot.data!;

              return _card(
                child: Column(
                  children: List.generate(data.length, (i) {
                    final item = data[i];

                    final time =
                        "${item['hour'].toString().padLeft(2, '0')}:"
                        "${item['minute'].toString().padLeft(2, '0')}";

                    return InkWell(
                      onTap: () => _changeReminderTime(
                        context: context,
                        item: item,
                        provider: provider,
                      ),

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),

                        decoration: BoxDecoration(
                          border: i != data.length - 1
                              ? const Border(
                                  bottom: BorderSide(color: Colors.black12),
                                )
                              : null,
                        ),

                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),

                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),

                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: const Icon(
                                Icons.alarm,
                                color: AppColors.primary,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    item['label'],

                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    "Tap to change time",

                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),

                                borderRadius: BorderRadius.circular(8),
                              ),

                              child: Text(
                                time,

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,

                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          _sectionTitle("Data"),

          const SizedBox(height: 10),

          _card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Icon(Icons.backup, color: AppColors.primary),
                  ),

                  title: const Text("Backup & Restore"),

                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BackupScreen()),
                    );
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Icon(Icons.info_outline, color: Colors.orange),
                  ),

                  title: const Text("About App"),

                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),

                  onTap: () {
                    showAboutDialog(
                      context: context,

                      applicationName: "Medi Reminder",

                      applicationVersion: "1.0.0",

                      applicationLegalese:
                          "Offline medication tracking with reminders.",
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

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: const Row(
        children: [
          Icon(Icons.settings, color: Colors.white, size: 30),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              "App Settings",

              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),

      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),

      child: child,
    );
  }
}
