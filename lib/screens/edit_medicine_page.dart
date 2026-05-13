import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/medicine_model.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_textfield.dart';
import 'doctors_page.dart';

class EditMedicinePage extends StatefulWidget {
  final Medicine medicine;

  const EditMedicinePage({super.key, required this.medicine});

  @override
  State<EditMedicinePage> createState() => _EditMedicinePageState();
}

class _EditMedicinePageState extends State<EditMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  String? _selectedDoctorName;
  late String _selectedReminder;
  late String _selectedExpiry;
  late String _imagePath;

  // Quick Dosage Pattern
  int _morning = 0;
  int _afternoon = 0;
  int _evening = 0;
  bool _useQuickDosage = false;

  final List<String> _types = ['Tablet', 'Syrup', 'Capsule', 'Injection', 'Cream', 'Drops'];
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine.name);
    _dosageController = TextEditingController(text: widget.medicine.dosage);
    _quantityController = TextEditingController(text: widget.medicine.quantity);
    _notesController = TextEditingController(text: widget.medicine.notes);
    _selectedDoctorName = widget.medicine.doctor.isNotEmpty ? widget.medicine.doctor : null;
    _selectedReminder = widget.medicine.reminderTime;
    _selectedExpiry = widget.medicine.expiryDate;
    _imagePath = widget.medicine.image;
    
    _selectedType = _types.contains(widget.medicine.type) 
        ? widget.medicine.type 
        : _types[0];

    _parseDosage(widget.medicine.dosage);
  }

  void _parseDosage(String dosage) {
    if (RegExp(r'^\d+\+\d+\+\d+$').hasMatch(dosage)) {
      final parts = dosage.split('+');
      setState(() {
        _morning = int.parse(parts[0]);
        _afternoon = int.parse(parts[1]);
        _evening = int.parse(parts[2]);
        _useQuickDosage = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: widget.medicine.reminderTime.isNotEmpty
          ? TimeOfDay.fromDateTime(
              DateFormat.jm().parse(widget.medicine.reminderTime),
            )
          : TimeOfDay.now(),
    );
    if (time == null) return;
    final formatted = DateFormat.jm().format(
      DateTime(0, 0, 0, time.hour, time.minute),
    );
    setState(() {
      _selectedReminder = formatted;
    });
  }

  Future<void> _selectExpiryDate() async {
    final current = widget.medicine.expiryDate.isNotEmpty
        ? DateTime.tryParse(widget.medicine.expiryDate) ?? DateTime.now()
        : DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;
    setState(() {
      _selectedExpiry = DateFormat('yyyy-MM-dd').format(date);
    });
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<MedicineProvider>(context, listen: false);

    // Auto-construct dosage string from pattern if enabled
    final finalDosage = _useQuickDosage 
        ? '${_morning}+${_afternoon}+${_evening}' 
        : _dosageController.text.trim();

    final updated = widget.medicine.copyWith(
      name: _nameController.text.trim(),
      type: _selectedType,
      dosage: finalDosage,
      quantity: _quantityController.text.trim(),
      doctor: _selectedDoctorName ?? '',
      patient: provider.activeProfile,
      notes: _notesController.text.trim(),
      image: _imagePath,
      reminderTime: _selectedReminder,
      expiryDate: _selectedExpiry,
    );
    await provider.updateMedicine(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildHeader('General Information'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Medicine Name',
                hintText: 'e.g., Amoxicillin',
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Medicine name is required'
                    : null,
              ),
              const SizedBox(height: 24),
              _buildHeader('Medicine Type'),
              const SizedBox(height: 12),
              _buildTypeChips(),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeader('Dosage Pattern (1+0+1)'),
                  Switch.adaptive(
                    value: _useQuickDosage,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _useQuickDosage = val),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _useQuickDosage ? _buildDosagePattern() : CustomTextField(
                controller: _dosageController,
                label: 'Custom Dosage',
                hintText: 'e.g., 500mg - 1 pill',
                validator: (value) =>
                    !_useQuickDosage && (value?.trim().isEmpty ?? true) ? 'Dosage is required' : null,
              ),
              const SizedBox(height: 32),
              _buildHeader('Schedule'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionPicker(
                      label: 'Reminder Time',
                      value: _selectedReminder,
                      onTap: _selectReminderTime,
                      icon: Icons.access_time_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionPicker(
                      label: 'Expiry Date',
                      value: _selectedExpiry,
                      onTap: _selectExpiryDate,
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildHeader('Other Details'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _quantityController,
                label: 'Total Quantity',
                hintText: 'e.g., 30 pills',
              ),
              const SizedBox(height: 20),
              _buildDoctorSelection(provider),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _notesController,
                label: 'Additional Notes',
                hintText: 'Special instructions...',
                maxLines: 4,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _saveMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Update Medicine Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, const Color(0xFF6366F1)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              const Positioned(
                bottom: 24,
                left: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Medicine',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Update your medicine records',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorSelection(MedicineProvider provider) {
    if (provider.doctors.isEmpty) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctorsPage()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.person_add_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No doctors found. Tap to add a prescribing doctor.',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Ensure the selected doctor still exists in the provider's list, otherwise reset it
    if (_selectedDoctorName != null && !provider.doctors.any((d) => d.name == _selectedDoctorName)) {
      _selectedDoctorName = null;
    }

    return DropdownButtonFormField<String>(
      value: _selectedDoctorName,
      decoration: InputDecoration(
        labelText: 'Prescribing Doctor',
        hintText: 'Select a doctor',
        prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: [
        ...provider.doctors.map((doc) => DropdownMenuItem(
              value: doc.name,
              child: Text(doc.name),
            )),
        DropdownMenuItem(
          value: 'ADD_NEW',
          child: Text(
            '+ Add New Doctor',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == 'ADD_NEW') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctorsPage()),
          );
        } else {
          setState(() {
            _selectedDoctorName = value;
          });
        }
      },
    );
  }

  Widget _buildTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _types.map((type) {
        final isSelected = _selectedType == type;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _selectedType = type);
          },
          selectedColor: AppColors.primaryLight,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildDosagePattern() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDosageItem('Morning', _morning, (val) => setState(() => _morning = val)),
          _buildDosageItem('Noon', _afternoon, (val) => setState(() => _afternoon = val)),
          _buildDosageItem('Night', _evening, (val) => setState(() => _evening = val)),
        ],
      ),
    );
  }

  Widget _buildDosageItem(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            _dosageButton(Icons.remove, () => value > 0 ? onChanged(value - 1) : null),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _dosageButton(Icons.add, () => onChanged(value + 1)),
          ],
        ),
      ],
    );
  }

  Widget _dosageButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildActionPicker({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Select' : value,
                    style: TextStyle(
                      fontSize: 14,
                      color: value.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medicine Image',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImageSourceSheet(),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: _imagePath.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(File(_imagePath), fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Image Source',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
