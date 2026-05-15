import 'package:flutter/material.dart';
import 'package:medi_reminder/models/medicine_model.dart';
import 'package:medi_reminder/providers/medicine_provider.dart';
import 'package:medi_reminder/services/prescription_ocr_service.dart';
import 'package:medi_reminder/utils/app_colors.dart';

class OcrMedicineImportSheet extends StatefulWidget {
  final List<OcrMedicineSuggestion> suggestions;
  final String prescriptionTitle;
  final MedicineProvider provider;

  const OcrMedicineImportSheet({
    required this.suggestions,
    required this.prescriptionTitle,
    required this.provider,
  });

  @override
  State<OcrMedicineImportSheet> createState() => OcrMedicineImportSheetState();
}

class OcrMedicineImportSheetState extends State<OcrMedicineImportSheet> {
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
