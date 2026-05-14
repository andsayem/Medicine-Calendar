import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/medical_document_model.dart';
import '../models/medicine_model.dart';
import '../providers/medicine_provider.dart';
import '../services/prescription_ocr_service.dart';
import '../utils/app_colors.dart';
import '../widgets/empty_widget.dart';
import '../widgets/custom_textfield.dart';

class MedicalDocumentsPage extends StatelessWidget {
  final String title;
  final String table;

  const MedicalDocumentsPage({
    super.key,
    required this.title,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();
    final docs = table == 'prescriptions'
        ? provider.prescriptions
        : provider.testReports;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: docs.isEmpty
          ? EmptyWidget(
              title: 'No ${title.toLowerCase()} found',
              subtitle:
                  'Keep your medical records organized by adding them here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doc = docs[index];
                return _buildDocumentCard(context, doc, provider);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDocumentSheet(context, provider),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add ${title.split(' ')[0]}'),
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    MedicalDocument doc,
    MedicineProvider provider,
  ) {
    final images = doc.imagePaths;
    final primaryImage = doc.primaryImage;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: images.isEmpty
                      ? null
                      : () => _openImageViewer(context, images),
                  child:
                      primaryImage.isNotEmpty && File(primaryImage).existsSync()
                      ? Image.file(
                          File(primaryImage),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryLight,
                                AppColors.secondaryLight,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                if (images.length > 1)
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.collections_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${images.length}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        doc.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _showEditDocumentSheet(context, provider, doc),
                      icon: Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (table == 'prescriptions') {
                          provider.deletePrescription(doc.id!);
                        } else {
                          provider.deleteTestReport(doc.id!);
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc.date,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _daysAgoLabel(doc.date),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (doc.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    doc.notes,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
                if (doc.doctor.isNotEmpty || doc.testReport.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (doc.doctor.isNotEmpty)
                        _buildRelationChip(
                          Icons.person_outline_rounded,
                          doc.doctor,
                        ),
                      if (doc.testReport.isNotEmpty)
                        _buildRelationChip(
                          Icons.assignment_outlined,
                          doc.testReport,
                        ),
                    ],
                  ),
                ],
                if (images.length > 1) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 54,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final imagePath = images[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: () => _openImageViewer(
                              context,
                              images,
                              initialIndex: index,
                            ),
                            child: File(imagePath).existsSync()
                                ? Image.file(
                                    File(imagePath),
                                    height: 54,
                                    width: 54,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 54,
                                    width: 54,
                                    color: AppColors.primaryLight,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentSheet(BuildContext context, MedicineProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddDocumentSheet(table: table, provider: provider),
    );
  }

  Widget _buildRelationChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDocumentSheet(
    BuildContext context,
    MedicineProvider provider,
    MedicalDocument doc,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddDocumentSheet(
        table: table,
        provider: provider,
        existingDocument: doc,
      ),
    );
  }

  void _openImageViewer(
    BuildContext context,
    List<String> images, {
    int initialIndex = 0,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _DocumentImageViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  String _daysAgoLabel(String dateText) {
    try {
      final date = DateFormat('MMM dd, yyyy').parse(dateText);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      final days = todayOnly.difference(dateOnly).inDays;

      if (days == 0) return 'Today';
      if (days == 1) return '1 day ago';
      if (days > 1) return '$days days ago';
      if (days == -1) return 'Tomorrow';
      return 'In ${days.abs()} days';
    } catch (_) {
      return '';
    }
  }
}

class _AddDocumentSheet extends StatefulWidget {
  final String table;
  final MedicineProvider provider;
  final MedicalDocument? existingDocument;

  const _AddDocumentSheet({
    required this.table,
    required this.provider,
    this.existingDocument,
  });

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
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
        return _OcrMedicineImportSheet(
          suggestions: suggestions,
          prescriptionTitle: prescription.title,
          provider: widget.provider,
        );
      },
    );
  }
}

class _OcrMedicineImportSheet extends StatefulWidget {
  final List<OcrMedicineSuggestion> suggestions;
  final String prescriptionTitle;
  final MedicineProvider provider;

  const _OcrMedicineImportSheet({
    required this.suggestions,
    required this.prescriptionTitle,
    required this.provider,
  });

  @override
  State<_OcrMedicineImportSheet> createState() => _OcrMedicineImportSheetState();
}

class _OcrMedicineImportSheetState extends State<_OcrMedicineImportSheet> {
  late final List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(widget.suggestions.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.where((selected) => selected).length;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Detected Medicines',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Review OCR results before adding.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.suggestions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final suggestion = widget.suggestions[index];
                  return CheckboxListTile(
                    value: _selected[index],
                    onChanged: (value) {
                      setState(() => _selected[index] = value ?? false);
                    },
                    title: Text(
                      suggestion.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      suggestion.dosage,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: selectedCount == 0 ? null : _addSelectedMedicines,
              child: Text('Add $selectedCount Medicine'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSelectedMedicines() async {
    for (var i = 0; i < widget.suggestions.length; i++) {
      if (!_selected[i]) continue;

      final suggestion = widget.suggestions[i];
      final medicine = Medicine(
        name: suggestion.name,
        type: 'Medicine',
        dosage: suggestion.dosage,
        quantity: '',
        doctor: '',
        notes: 'Imported from prescription OCR: ${suggestion.rawText}',
        image: '',
        reminderTime: '',
        expiryDate: '',
        patient: widget.provider.activeProfile,
        createdAt: DateTime.now().toIso8601String(),
        prescription: widget.prescriptionTitle,
      );
      await widget.provider.addMedicine(medicine);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _DocumentImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _DocumentImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_DocumentImageViewer> createState() => _DocumentImageViewerState();
}

class _DocumentImageViewerState extends State<_DocumentImageViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final path = widget.images[index];
          if (!File(path).existsSync()) {
            return const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 64,
              ),
            );
          }

          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(child: Image.file(File(path), fit: BoxFit.contain)),
          );
        },
      ),
    );
  }
}
