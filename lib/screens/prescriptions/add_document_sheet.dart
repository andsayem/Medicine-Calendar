import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_medicine_note/models/medical_document_model.dart';
import 'package:my_medicine_note/providers/medicine_provider.dart';
import 'package:my_medicine_note/screens/prescriptions/ocr_medicineImport_sheet.dart';
import 'package:my_medicine_note/services/prescription_ocr_service.dart';
import 'package:my_medicine_note/utils/app_colors.dart';
import 'package:my_medicine_note/widgets/custom_textfield.dart';

class AddDocumentSheet extends StatefulWidget {
  final String table;
  final MedicineProvider provider;
  final MedicalDocument? existingDocument;

  const AddDocumentSheet({
    required this.table,
    required this.provider,
    this.existingDocument,
  });

  @override
  State<AddDocumentSheet> createState() => AddDocumentSheetState();
}

class AddDocumentSheetState extends State<AddDocumentSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _imagePaths = [];
  String _selectedDoctor = '';
  String _selectedTestReport = '';
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.existingDocument != null;
  bool get _isPrescription => widget.table == 'prescriptions';
  String get _recordName => _isPrescription ? 'Prescription' : 'Test Report';

  @override
  void initState() {
    super.initState();
    final existing = widget.existingDocument;
    if (existing == null) return;

    _titleController.text = existing.title;
    _notesController.text = existing.notes;
    _imagePaths.addAll(existing.imagePaths);
    _selectedDoctor = existing.doctor;
    _selectedTestReport = existing.testReport;
    _selectedDate = _parseDocumentDate(existing.date);
  }

  DateTime _parseDocumentDate(String value) {
    try {
      return DateFormat('MMM dd, yyyy').parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(pickedFiles.map((file) => file.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit $_recordName' : 'Add New $_recordName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: _imagePaths.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add Photo',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _imagePaths.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemBuilder: (context, index) {
                              final imagePath = _imagePaths[index];
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _imagePaths.removeAt(index);
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_imagePaths.length} image${_imagePaths.length == 1 ? '' : 's'} selected. Tap to add more.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _titleController,
              label: 'Title',
              hintText: 'e.g., General Checkup',
            ),
            const SizedBox(height: 16),
            if (_isPrescription) ...[
              _buildRelationPicker(
                label: 'Prescription Doctor (Optional)',
                value: _selectedDoctor,
                icon: Icons.person_outline_rounded,
                items: widget.provider.doctors.map((d) => d.name).toList(),
                emptyText: 'No doctor linked',
                onChanged: (value) => setState(() => _selectedDoctor = value),
              ),
              const SizedBox(height: 12),
              _buildRelationPicker(
                label: 'Related Test Report (Optional)',
                value: _selectedTestReport,
                icon: Icons.assignment_outlined,
                items: widget.provider.testReports.map((d) => d.title).toList(),
                emptyText: 'No test report linked',
                onChanged: (value) =>
                    setState(() => _selectedTestReport = value),
              ),
              const SizedBox(height: 16),
            ],
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _notesController,
              label: 'Notes',
              hintText: 'Additional details...',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) return;
                final doc = MedicalDocument(
                  id: widget.existingDocument?.id,
                  title: _titleController.text.trim(),
                  image: MedicalDocument.encodeImages(_imagePaths),
                  date: DateFormat('MMM dd, yyyy').format(_selectedDate),
                  notes: _notesController.text.trim(),
                  patient:
                      widget.existingDocument?.patient ??
                      widget.provider.activeProfile,
                  doctor: _isPrescription ? _selectedDoctor : '',
                  testReport: _isPrescription ? _selectedTestReport : '',
                );
                if (widget.table == 'prescriptions') {
                  if (_isEditing) {
                    await widget.provider.updatePrescription(doc);
                  } else {
                    await widget.provider.addPrescription(doc);
                    await _maybeImportMedicinesFromPrescription(doc);
                  }
                } else if (_isEditing) {
                  await widget.provider.updateTestReport(doc);
                } else {
                  await widget.provider.addTestReport(doc);
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isEditing ? 'Update $_recordName' : 'Save $_recordName',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationPicker({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required String emptyText,
    required ValueChanged<String> onChanged,
  }) {
    final uniqueItems = [
      if (value.trim().isNotEmpty) value,
      ...items,
    ].where((item) => item.trim().isNotEmpty).toSet().toList(growable: false);
    final dropdownValue = value.isNotEmpty && uniqueItems.contains(value)
        ? value
        : '';

    return DropdownButtonFormField<String>(
      initialValue: dropdownValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      items: [
        DropdownMenuItem(value: '', child: Text(emptyText)),
        ...uniqueItems.map(
          (item) => DropdownMenuItem(value: item, child: Text(item)),
        ),
      ],
      onChanged: (value) => onChanged(value ?? ''),
    );
  }

  Future<void> _maybeImportMedicinesFromPrescription(
    MedicalDocument prescription,
  ) async {
    if (!_isPrescription || _isEditing || _imagePaths.isEmpty) return;

    final List<OcrMedicineSuggestion> suggestions;
    try {
      suggestions = await PrescriptionOcrService.scanImages(_imagePaths);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR scan failed. Prescription saved.')),
        );
      }
      return;
    }

    if (!mounted || suggestions.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return OcrMedicineImportSheet(
          suggestions: suggestions,
          prescriptionTitle: prescription.title,
          provider: widget.provider,
        );
      },
    );
  }
}
