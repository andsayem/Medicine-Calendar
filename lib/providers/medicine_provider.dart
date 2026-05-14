import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/medicine_model.dart';
import '../models/medical_document_model.dart';
import '../models/doctor_model.dart';
import '../models/member_model.dart';
import '../services/notification_service.dart';

class MedicineProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  List<MedicalDocument> _prescriptions = [];
  List<MedicalDocument> _testReports = [];
  List<Doctor> _doctors = [];
  List<Member> _members = [];
  bool _isLoading = false;
  bool _isDarkMode = false;
  bool _isGridView = false;
  String _activeProfile = 'Self';

  String get activeProfile => _activeProfile;

  void setActiveProfile(String profile) {
    _activeProfile = profile;
    notifyListeners();
  }

  List<Medicine> get medicines => _filteredMedicines.where((m) => m.patient == _activeProfile).toList();
  List<MedicalDocument> get prescriptions => _prescriptions.where((d) => d.patient == _activeProfile).toList();
  List<MedicalDocument> get testReports => _testReports.where((d) => d.patient == _activeProfile).toList();
  List<Doctor> get doctors => _doctors;
  List<Member> get members => _members;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  bool get isGridView => _isGridView;


  Future<void> initialize() async {
    await fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _medicines = await _databaseHelper.getAllMedicines();
      _filteredMedicines = List<Medicine>.from(_medicines);
      _prescriptions = await _databaseHelper.getAllDocuments('prescriptions');
      _testReports = await _databaseHelper.getAllDocuments('test_reports');
      _doctors = await _databaseHelper.getAllDoctors();
      _members = await _databaseHelper.getAllMembers();
      await _notificationService.rescheduleMedicines(_medicines);
    } catch (_) {
      _medicines = [];
      _filteredMedicines = [];
      _prescriptions = [];
      _testReports = [];
      _doctors = [];
      _members = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    final createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final newMedicine = medicine.copyWith(createdAt: createdAt);
    final id = await _databaseHelper.insertMedicine(newMedicine);
    final inserted = newMedicine.copyWith(id: id);
    _medicines.insert(0, inserted);
    _filteredMedicines = List<Medicine>.from(_medicines);
    await _notificationService.scheduleMedicineReminder(inserted);
    notifyListeners();
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _databaseHelper.updateMedicine(medicine);
    final index = _medicines.indexWhere((item) => item.id == medicine.id);
    if (index >= 0) {
      _medicines[index] = medicine;
      _filteredMedicines = List<Medicine>.from(_medicines);
    }
    await _notificationService.cancelNotification(medicine.id!);
    await _notificationService.scheduleMedicineReminder(medicine);
    notifyListeners();
  }

  Future<void> deleteMedicine(int id) async {
    await _databaseHelper.deleteMedicine(id);
    _medicines.removeWhere((item) => item.id == id);
    _filteredMedicines = List<Medicine>.from(_medicines);
    await _notificationService.cancelNotification(id);
    notifyListeners();
  }

  Future<void> searchMedicines(String query) async {
    if (query.trim().isEmpty) {
      _filteredMedicines = List<Medicine>.from(_medicines);
      notifyListeners();
      return;
    }
    _filteredMedicines = await _databaseHelper.searchMedicines(query);
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleView() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  // --- Medical Documents Methods ---

  Future<void> addPrescription(MedicalDocument doc) async {
    await _databaseHelper.insertDocument('prescriptions', doc);
    _prescriptions = await _databaseHelper.getAllDocuments('prescriptions');
    notifyListeners();
  }

  Future<void> updatePrescription(MedicalDocument doc) async {
    await _databaseHelper.updateDocument('prescriptions', doc);
    _prescriptions = await _databaseHelper.getAllDocuments('prescriptions');
    notifyListeners();
  }

  Future<void> deletePrescription(int id) async {
    await _databaseHelper.deleteDocument('prescriptions', id);
    _prescriptions = await _databaseHelper.getAllDocuments('prescriptions');
    notifyListeners();
  }

  Future<void> addTestReport(MedicalDocument doc) async {
    await _databaseHelper.insertDocument('test_reports', doc);
    _testReports = await _databaseHelper.getAllDocuments('test_reports');
    notifyListeners();
  }

  Future<void> updateTestReport(MedicalDocument doc) async {
    await _databaseHelper.updateDocument('test_reports', doc);
    _testReports = await _databaseHelper.getAllDocuments('test_reports');
    notifyListeners();
  }

  Future<void> deleteTestReport(int id) async {
    await _databaseHelper.deleteDocument('test_reports', id);
    _testReports = await _databaseHelper.getAllDocuments('test_reports');
    notifyListeners();
  }

  // --- Doctors Methods ---

  Future<void> addDoctor(Doctor doctor) async {
    await _databaseHelper.insertDoctor(doctor);
    _doctors = await _databaseHelper.getAllDoctors();
    notifyListeners();
  }

  Future<void> deleteDoctor(int id) async {
    await _databaseHelper.deleteDoctor(id);
    _doctors = await _databaseHelper.getAllDoctors();
    notifyListeners();
  }

  // --- Members Methods ---

  Future<void> addMember(Member member) async {
    await _databaseHelper.insertMember(member);
    _members = await _databaseHelper.getAllMembers();
    notifyListeners();
  }

  Future<void> deleteMember(int id) async {
    await _databaseHelper.deleteMember(id);
    _members = await _databaseHelper.getAllMembers();
    notifyListeners();
  }
}
