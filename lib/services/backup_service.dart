import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_helper.dart';
import '../utils/constants.dart';

class BackupService {
  static const _backupFolderName = 'MediReminder_Backup';
  static const _relativeImageFolder = 'backup_images';

  Future<Directory> _getBackupDirectory() async {
    Directory baseDirectory;

    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      baseDirectory = directory ?? await getApplicationDocumentsDirectory();
    } else {
      baseDirectory = await getApplicationDocumentsDirectory();
    }

    final backupDirectory = Directory(
      join(baseDirectory.path, _backupFolderName),
    );
    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }
    return backupDirectory;
  }

  Future<String> exportBackup() async {
    final backupDirectory = await _getBackupDirectory();
    final dbPath = join(await getDatabasesPath(), 'my_medicine_note.db');
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.copy(join(backupDirectory.path, basename(dbPath)));
    }

    final db = await DatabaseHelper.instance.database;
    final data = <String, dynamic>{};

    data['medicines'] = await _readTable(db, Constants.medicinesTable);
    data['prescriptions'] = await _readTable(db, 'prescriptions');
    data['test_reports'] = await _readTable(db, 'test_reports');
    data['doctors'] = await _readTable(db, 'doctors');
    data['members'] = await _readTable(db, 'members');
    data['blood_pressure'] = await _readTable(db, 'blood_pressure');
    data['blood_sugar'] = await _readTable(db, 'blood_sugar');

    data['settings'] = await _readSettings();

    await _copyReferencedImages(backupDirectory, data);

    final jsonFile = File(join(backupDirectory.path, 'backup_data.json'));
    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );

    return backupDirectory.path;
  }

  Future<void> importBackup() async {
    final backupDirectory = await _getBackupDirectory();
    final backupJson = File(join(backupDirectory.path, 'backup_data.json'));
    if (!await backupJson.exists()) {
      throw Exception('Backup file not found: ${backupJson.path}');
    }

    final content = await backupJson.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    final db = await DatabaseHelper.instance.database;
    await _clearAllTables(db);

    await _restoreTable(
      db,
      Constants.medicinesTable,
      data['medicines'] as List<dynamic>? ?? [],
    );
    await _restoreTable(
      db,
      'prescriptions',
      data['prescriptions'] as List<dynamic>? ?? [],
    );
    await _restoreTable(
      db,
      'test_reports',
      data['test_reports'] as List<dynamic>? ?? [],
    );
    await _restoreTable(db, 'doctors', data['doctors'] as List<dynamic>? ?? []);
    await _restoreTable(db, 'members', data['members'] as List<dynamic>? ?? []);
    await _restoreTable(
      db,
      'blood_pressure',
      data['blood_pressure'] as List<dynamic>? ?? [],
    );
    await _restoreTable(
      db,
      'blood_sugar',
      data['blood_sugar'] as List<dynamic>? ?? [],
    );

    await _restoreSettings(data['settings'] as Map<String, dynamic>? ?? {});
  }

  Future<List<Map<String, dynamic>>> _readTable(
    Database db,
    String table,
  ) async {
    return await db.query(table);
  }

  Future<Map<String, dynamic>> _readSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderTimes = <String, String>{};

    for (var index = 0; index < 3; index++) {
      final value = prefs.getString('reminder_time_$index');
      if (value != null) {
        reminderTimes['reminder_time_$index'] = value;
      }
    }

    return {
      'reminder_times': reminderTimes,
      'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
      'notification_sound_enabled':
          prefs.getBool('notification_sound_enabled') ?? true,
    };
  }

  Future<void> _restoreSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    final reminderTimes = settings['reminder_times'] as Map<String, dynamic>?;
    if (reminderTimes != null) {
      for (final entry in reminderTimes.entries) {
        await prefs.setString(entry.key, entry.value as String);
      }
    }

    final notificationsEnabled = settings['notifications_enabled'] as bool?;
    if (notificationsEnabled != null) {
      await prefs.setBool('notifications_enabled', notificationsEnabled);
    }

    final soundEnabled = settings['notification_sound_enabled'] as bool?;
    if (soundEnabled != null) {
      await prefs.setBool('notification_sound_enabled', soundEnabled);
    }
  }

  Future<void> _copyReferencedImages(
    Directory backupDirectory,
    Map<String, dynamic> data,
  ) async {
    final imagesDir = Directory(
      join(backupDirectory.path, _relativeImageFolder),
    );
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    await _copyMedicineImages(backupDirectory, data);
    await _copyDocumentImages(data, imagesDir, 'prescriptions');
    await _copyDocumentImages(data, imagesDir, 'test_reports');
  }

  Future<void> _copyMedicineImages(
    Directory backupDirectory,
    Map<String, dynamic> data,
  ) async {
    final medicines = data['medicines'] as List<dynamic>? ?? [];
    final imagesDir = Directory(
      join(backupDirectory.path, _relativeImageFolder, 'medicines'),
    );
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

    for (var i = 0; i < medicines.length; i++) {
      final item = medicines[i] as Map<String, dynamic>;
      final imagePath = item['image'] as String? ?? '';
      if (imagePath.trim().isEmpty) continue;

      final copiedPath = await _copyFileToFolder(imagePath, imagesDir);
      if (copiedPath != null) {
        item['image'] = relative(copiedPath, from: backupDirectory.path);
        medicines[i] = item;
      }
    }
  }

  Future<void> _copyDocumentImages(
    Map<String, dynamic> data,
    Directory backupDirectory,
    String tableName,
  ) async {
    final documents = data[tableName] as List<dynamic>? ?? [];
    final imagesDir = Directory(
      join(backupDirectory.path, _relativeImageFolder, tableName),
    );
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

    for (var i = 0; i < documents.length; i++) {
      final item = documents[i] as Map<String, dynamic>;
      final imageField = item['image'] as String? ?? '';
      final imagePaths = _parseImageField(imageField);
      final newPaths = <String>[];

      for (final path in imagePaths) {
        final copiedPath = await _copyFileToFolder(path, imagesDir);
        if (copiedPath != null) {
          newPaths.add(relative(copiedPath, from: backupDirectory.path));
        }
      }

      if (newPaths.isEmpty) {
        item['image'] = '';
      } else if (newPaths.length == 1) {
        item['image'] = newPaths.first;
      } else {
        item['image'] = jsonEncode(newPaths);
      }
      documents[i] = item;
    }
  }

  Future<String?> _copyFileToFolder(
    String sourcePath,
    Directory targetDirectory,
  ) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return null;

    final destinationPath = join(targetDirectory.path, basename(sourcePath));
    await sourceFile.copy(destinationPath);
    return destinationPath;
  }

  List<String> _parseImageField(String imageField) {
    if (imageField.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(imageField);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .where((path) => path.trim().isNotEmpty)
            .toList();
      }
    } catch (_) {
      // field is not JSON array
    }

    return [imageField];
  }

  Future<void> _clearAllTables(Database db) async {
    final tables = [
      Constants.medicinesTable,
      'prescriptions',
      'test_reports',
      'doctors',
      'members',
      'blood_pressure',
      'blood_sugar',
    ];

    for (final table in tables) {
      await db.delete(table);
    }
  }

  Future<void> _restoreTable(
    Database db,
    String table,
    List<dynamic> rows,
  ) async {
    if (rows.isEmpty) return;

    final appDocuments = await getApplicationDocumentsDirectory();
    final restoreImageRoot = Directory(
      join(appDocuments.path, 'restored_images', table),
    );
    if (!await restoreImageRoot.exists()) {
      await restoreImageRoot.create(recursive: true);
    }

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      if (table == Constants.medicinesTable) {
        final imagePath = map['image'] as String? ?? '';
        final restoredPath = await _restoreBackupImage(
          imagePath,
          restoreImageRoot,
        );
        if (restoredPath != null) {
          map['image'] = restoredPath;
        }
      } else if (table == 'prescriptions' || table == 'test_reports') {
        final imageField = map['image'] as String? ?? '';
        final imagePaths = _parseImageField(imageField);
        final restoredPaths = <String>[];

        for (final path in imagePaths) {
          final restoredPath = await _restoreBackupImage(
            path,
            restoreImageRoot,
          );
          if (restoredPath != null) {
            restoredPaths.add(restoredPath);
          }
        }

        if (restoredPaths.isEmpty) {
          map['image'] = '';
        } else if (restoredPaths.length == 1) {
          map['image'] = restoredPaths.first;
        } else {
          map['image'] = jsonEncode(restoredPaths);
        }
      }

      await db.insert(table, map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<String?> _restoreBackupImage(
    String imageField,
    Directory restoreDir,
  ) async {
    if (imageField.trim().isEmpty) return null;

    final inputPath = Platform.isAndroid || Platform.isIOS
        ? imageField
        : imageField;

    final sourceFile = File(inputPath);
    if (await sourceFile.exists()) {
      final destinationPath = join(restoreDir.path, basename(inputPath));
      return await sourceFile.copy(destinationPath).then((file) => file.path);
    }

    // If path is relative inside backup folder, try to locate it there.
    final backupDirectory = await _getBackupDirectory();
    final backupFile = File(join(backupDirectory.path, imageField));
    if (await backupFile.exists()) {
      final destinationPath = join(restoreDir.path, basename(imageField));
      return await backupFile.copy(destinationPath).then((file) => file.path);
    }

    return null;
  }
}
