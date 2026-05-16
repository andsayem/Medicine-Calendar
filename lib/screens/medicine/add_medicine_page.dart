import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medi_reminder/models/medicine_model.dart';
import 'package:medi_reminder/providers/medicine_provider.dart';
import 'package:medi_reminder/screens/prescriptions/medical_documents_page.dart';
import 'package:medi_reminder/utils/app_colors.dart';
import 'package:medi_reminder/widgets/custom_textfield.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medi_reminder/services/notification_service.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedPrescription = '';
  String _selectedReminder = '';
  String _selectedExpiry = '';
  List<String> _savedReminderTimes = [];
  List<String> _perDoseTimes = [];
  String _imagePath = '';
  bool _showSchedule = false;
  bool _showOtherDetails = false;

  // Quick Dosage Pattern (Morning + Afternoon + Evening)
  int _morning = 1;
  int _afternoon = 0;
  int _evening = 1;
  bool _useQuickDosage = true;

  final List<String> _types = [
    'Tablet',
    'Syrup',
    'Capsule',
    'Injection',
    'Cream',
    'Drops',
  ];
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = _types[0];
    _loadReminderSchedule();
    _dosageController.addListener(() {
      _syncPerDoseTimes();
    });
  }

  Future<void> _loadReminderSchedule() async {
    final schedule = await NotificationService.instance.getReminderSchedule();
    setState(() {
      _savedReminderTimes = schedule.map((e) {
        final hour = (e['hour'] as int).toString().padLeft(2, '0');
        final minute = (e['minute'] as int).toString().padLeft(2, '0');
        return '$hour:$minute';
      }).toList();
    });
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
      // ignore image picker failure and remain stable
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final formatted = DateFormat(
      'HH:mm',
    ).format(DateTime(0, 0, 0, time.hour, time.minute));
    setState(() {
      _selectedReminder = formatted;
    });
  }

  Future<void> _pickTimeForIndex(int idx) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final formatted = DateFormat(
      'HH:mm',
    ).format(DateTime(0, 0, 0, time.hour, time.minute));
    setState(() {
      if (idx < 0) return;
      while (_perDoseTimes.length <= idx) _perDoseTimes.add('');
      _perDoseTimes[idx] = formatted;
    });
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
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
        ? '$_morning+$_afternoon+$_evening'
        : _dosageController.text.trim();

    // persist per-dose times as CSV in reminderTime
    final reminderCsv = _perDoseTimes
        .where((t) => t.trim().isNotEmpty)
        .join(',');

    final medicine = Medicine(
      name: _nameController.text.trim(),
      type: _selectedType, // Use the selected type from chips
      dosage: finalDosage,
      quantity: _quantityController.text.trim(),
      doctor: '',
      prescription: _selectedPrescription,
      patient: provider.activeProfile,
      notes: _notesController.text.trim(),
      image: _imagePath,
      reminderTime: reminderCsv.isNotEmpty ? reminderCsv : _selectedReminder,
      expiryDate: _selectedExpiry,
      createdAt: DateTime.now().toIso8601String(),
    );

    await provider.addMedicine(medicine);
    if (mounted) {
      Navigator.pop(context);
    }
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
                          // ignore: deprecated_member_use
                          activeColor: AppColors.primary,
                          onChanged: (val) =>
                              setState(() => _useQuickDosage = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _useQuickDosage
                        ? _buildDosagePattern()
                        : CustomTextField(
                            controller: _dosageController,
                            label: 'Custom Dosage',
                            hintText: 'e.g., 500mg - 1 pill',
                            validator: (value) =>
                                !_useQuickDosage &&
                                    (value?.trim().isEmpty ?? true)
                                ? 'Dosage is required'
                                : null,
                          ),
                    const SizedBox(height: 32),
                    _buildExpandableHeader(
                      title: 'Schedule',
                      isExpanded: _showSchedule,
                      onTap: () =>
                          setState(() => _showSchedule = !_showSchedule),
                    ),

                    if (_showSchedule) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildActionPicker(
                                  label: 'Reminder Time',
                                  value: _selectedReminder,
                                  onTap: _selectReminderTime,
                                  showCountBadge: true,
                                  icon: Icons.access_time_rounded,
                                ),
                                const SizedBox(height: 12),
                                if (_getDoseCount() > 0)
                                  Column(children: _buildPerDoseRows()),
                              ],
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
                    ],

                    const SizedBox(height: 24),
                    _buildExpandableHeader(
                      title: 'Other Details',
                      isExpanded: _showOtherDetails,
                      onTap: () => setState(
                        () => _showOtherDetails = !_showOtherDetails,
                      ),
                    ),

                    if (_showOtherDetails) ...[
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _quantityController,
                        label: 'Total Quantity',
                        hintText: 'e.g., 30 pills',
                      ),
                      const SizedBox(height: 20),
                      _buildPrescriptionSelection(provider),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _notesController,
                        label: 'Additional Notes',
                        hintText: 'Special instructions...',
                        maxLines: 4,
                      ),
                    ],

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
                        'Add Medicine to Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -54,
                top: -44,
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
              ),
              const Positioned(
                bottom: 24,
                left: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Medicine',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Keep your records updated',
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

  Widget _buildPrescriptionSelection(MedicineProvider provider) {
    if (provider.prescriptions.isEmpty) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MedicalDocumentsPage(
                title: 'My Prescriptions',
                table: 'prescriptions',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.secondary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No prescription found. Tap to add one if needed.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final prescriptions = [
      if (_selectedPrescription.trim().isNotEmpty) _selectedPrescription,
      ...provider.prescriptions.map((doc) => doc.title),
    ].where((title) => title.trim().isNotEmpty).toSet().toList();

    final value = prescriptions.contains(_selectedPrescription)
        ? _selectedPrescription
        : '';

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Related Prescription (Optional)',
        prefixIcon: Icon(Icons.description_outlined, color: AppColors.primary),
      ),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text('No prescription linked'),
        ),
        ...prescriptions.map(
          (title) => DropdownMenuItem(value: title, child: Text(title)),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedPrescription = value ?? '');
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
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDosageItem(
            'Morning',
            _morning,
            (val) => setState(() => _morning = val),
          ),
          _buildDosageItem(
            'Noon',
            _afternoon,
            (val) => setState(() => _afternoon = val),
          ),
          _buildDosageItem(
            'Night',
            _evening,
            (val) => setState(() => _evening = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDosageItem(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _dosageButton(
              Icons.remove,
              () => value > 0 ? onChanged(value - 1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          border: Border.all(color: AppColors.border),
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

  Widget _buildExpandableHeader({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(child: _buildHeader(title)),
            Icon(
              isExpanded
                  ? Icons.remove_circle_rounded
                  : Icons.add_circle_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPicker({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
    bool showCountBadge = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (showCountBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getDoseCount().toString(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
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
                      color: value.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontWeight: value.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showCountBadge && _savedReminderTimes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedReminder.isNotEmpty)
                  Text(
                    _selectedReminder,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (_selectedReminder.isEmpty) ...[
                  if (_useQuickDosage) ...[
                    if (_morning > 0 && _savedReminderTimes.length > 0)
                      _buildDoseTimeRow('Morning', _savedReminderTimes[0]),
                    if (_afternoon > 0 && _savedReminderTimes.length > 1)
                      _buildDoseTimeRow('Noon', _savedReminderTimes[1]),
                    if (_evening > 0 && _savedReminderTimes.length > 2)
                      _buildDoseTimeRow('Night', _savedReminderTimes[2]),
                  ] else ...[
                    for (
                      var i = 0;
                      i < _getDoseCount() && i < _savedReminderTimes.length;
                      i++
                    )
                      _buildDoseTimeRow(
                        'Dose ${i + 1}',
                        _savedReminderTimes[i],
                      ),
                  ],
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDoseTimeRow(String label, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  int _getDoseCount() {
    if (_useQuickDosage) {
      var c = 0;
      if (_morning > 0) c++;
      if (_afternoon > 0) c++;
      if (_evening > 0) c++;
      return c;
    }

    final text = _dosageController.text.trim();
    if (text.isEmpty) return 0;
    final parts = text.split('+');
    return parts.where((p) => p.trim() != '0' && p.trim().isNotEmpty).length;
  }

  void _syncPerDoseTimes() {
    final count = _getDoseCount();
    // ensure list length
    while (_perDoseTimes.length < count) {
      _perDoseTimes.add('');
    }
    if (_perDoseTimes.length > count) {
      _perDoseTimes = _perDoseTimes.take(count).toList();
    }
    // populate defaults from saved schedule where empty
    for (var i = 0; i < count; i++) {
      if (_perDoseTimes[i].trim().isEmpty && i < _savedReminderTimes.length) {
        _perDoseTimes[i] = _savedReminderTimes[i];
      }
    }
    setState(() {});
  }

  List<Widget> _buildPerDoseRows() {
    final rows = <Widget>[];
    if (_useQuickDosage) {
      var idx = 0;
      if (_morning > 0) {
        rows.add(_editableDoseRow('Morning', idx));
        idx++;
      }
      if (_afternoon > 0) {
        rows.add(_editableDoseRow('Noon', idx));
        idx++;
      }
      if (_evening > 0) {
        rows.add(_editableDoseRow('Night', idx));
        idx++;
      }
    } else {
      final cnt = _getDoseCount();
      for (var i = 0; i < cnt; i++)
        rows.add(_editableDoseRow('Dose ${i + 1}', i));
    }
    return rows;
  }

  Widget _editableDoseRow(String label, int index) {
    final time =
        (index < _perDoseTimes.length && _perDoseTimes[index].isNotEmpty)
        ? _perDoseTimes[index]
        : (index < _savedReminderTimes.length
              ? _savedReminderTimes[index]
              : 'Select');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: () => _pickTimeForIndex(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
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
