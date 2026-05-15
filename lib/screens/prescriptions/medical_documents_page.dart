import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medi_reminder/screens/prescriptions/add_document_sheet.dart';
import 'package:medi_reminder/screens/prescriptions/document_image_viewer.dart';
import 'package:provider/provider.dart';

import '../../models/medical_document_model.dart';
import '../../providers/medicine_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/empty_widget.dart';

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
      builder: (context) => AddDocumentSheet(table: table, provider: provider),
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
      builder: (context) => AddDocumentSheet(
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
            DocumentImageViewer(images: images, initialIndex: initialIndex),
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
