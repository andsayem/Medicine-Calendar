import 'package:flutter/material.dart';

import '../services/backup_service.dart';
import '../utils/app_colors.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isProcessing = false;
  String _status = 'Export and restore your app data safely.';

  Future<void> _handleExport() async {
    setState(() {
      _isProcessing = true;
      _status = 'Preparing backup...';
    });

    try {
      final path = await _backupService.exportBackup();
      setState(() => _status = 'Backup finished. Folder:\n$path');
    } catch (e) {
      setState(() => _status = 'Backup failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isProcessing = true;
      _status = 'Restoring backup...';
    });

    try {
      await _backupService.importBackup();
      setState(
        () => _status = 'Restore complete. Restart the app to apply changes.',
      );
    } catch (e) {
      setState(() => _status = 'Restore failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.cloud_done,
                color: AppColors.primary,
                size: 70,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Backup & Restore',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _status,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _handleExport,
                icon: const Icon(Icons.backup),
                label: const Text('Backup Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleRestore,
                icon: const Icon(Icons.restore),
                label: const Text('Restore Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            const Spacer(),
            const Text(
              'Backup files are saved inside the app backup folder. If restore succeeds, restart the app.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
