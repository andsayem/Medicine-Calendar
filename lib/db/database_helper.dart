import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/medicine_model.dart';
import '../models/medical_document_model.dart';
import '../models/doctor_model.dart';
import '../models/member_model.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase('my_medicine_note.db');
    return _database!;
  }

  Future<Database> _initDatabase(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables for version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS prescriptions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          image TEXT,
          date TEXT,
          notes TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS test_reports(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          image TEXT,
          date TEXT,
          notes TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS doctors(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          specialty TEXT,
          phone TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE ${Constants.medicinesTable} ADD COLUMN patient TEXT DEFAULT 'Self'
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS members(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          relation TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE prescriptions ADD COLUMN patient TEXT DEFAULT 'Self'
      ''');
      await db.execute('''
        ALTER TABLE test_reports ADD COLUMN patient TEXT DEFAULT 'Self'
      ''');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${Constants.medicinesTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT,
        dosage TEXT,
        quantity TEXT,
        doctor TEXT,
        notes TEXT,
        image TEXT,
        reminder_time TEXT,
        expiry_date TEXT,
        patient TEXT DEFAULT 'Self',
        created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE prescriptions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        image TEXT,
        date TEXT,
        notes TEXT,
        patient TEXT DEFAULT 'Self'
      )
    ''');
    await db.execute('''
      CREATE TABLE test_reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        image TEXT,
        date TEXT,
        notes TEXT,
        patient TEXT DEFAULT 'Self'
      )
    ''');
    await db.execute('''
      CREATE TABLE doctors(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        specialty TEXT,
        phone TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        relation TEXT
      )
    ''');
  }

  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    return await db.insert(Constants.medicinesTable, medicine.toMap());
  }

  Future<List<Medicine>> getAllMedicines() async {
    final db = await database;
    final results = await db.query(
      Constants.medicinesTable,
      orderBy: 'created_at DESC',
    );
    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  Future<int> updateMedicine(Medicine medicine) async {
    final db = await database;
    return await db.update(
      Constants.medicinesTable,
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> deleteMedicine(int id) async {
    final db = await database;
    return await db.delete(
      Constants.medicinesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    final db = await database;
    if (query.trim().isEmpty) {
      return getAllMedicines();
    }
    final sanitized = '%${query.trim()}%';
    final results = await db.query(
      Constants.medicinesTable,
      where: 'name LIKE ? OR type LIKE ? OR dosage LIKE ? OR notes LIKE ?',
      whereArgs: [sanitized, sanitized, sanitized, sanitized],
      orderBy: 'created_at DESC',
    );
    return results.map((row) => Medicine.fromMap(row)).toList();
  }

  // --- Medical Documents (Prescriptions & Test Reports) ---

  Future<int> insertDocument(String table, MedicalDocument doc) async {
    final db = await database;
    return await db.insert(table, doc.toMap());
  }

  Future<List<MedicalDocument>> getAllDocuments(String table) async {
    final db = await database;
    final results = await db.query(table, orderBy: 'date DESC');
    return results.map((row) => MedicalDocument.fromMap(row)).toList();
  }

  Future<int> deleteDocument(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // --- Doctors ---

  Future<int> insertDoctor(Doctor doctor) async {
    final db = await database;
    return await db.insert('doctors', doctor.toMap());
  }

  Future<List<Doctor>> getAllDoctors() async {
    final db = await database;
    final results = await db.query('doctors', orderBy: 'name ASC');
    return results.map((row) => Doctor.fromMap(row)).toList();
  }

  Future<int> deleteDoctor(int id) async {
    final db = await database;
    return await db.delete('doctors', where: 'id = ?', whereArgs: [id]);
  }

  // --- Members ---

  Future<int> insertMember(Member member) async {
    final db = await database;
    return await db.insert('members', member.toMap());
  }

  Future<List<Member>> getAllMembers() async {
    final db = await database;
    final results = await db.query('members', orderBy: 'name ASC');
    return results.map((row) => Member.fromMap(row)).toList();
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }
}
