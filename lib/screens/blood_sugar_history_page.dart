import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/blood_sugar_model.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';

class BloodSugarHistoryPage extends StatefulWidget {
  const BloodSugarHistoryPage({super.key});

  @override
  State<BloodSugarHistoryPage> createState() => _BloodSugarHistoryPageState();
}

class _BloodSugarHistoryPageState extends State<BloodSugarHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MedicineProvider>(context);
    final items = provider.bloodSugars;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Blood Sugar History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _buildSugarCard(context, items[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, provider),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reading'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bloodtype_outlined,
            size: 80,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 18),
          const Text(
            'No blood sugar records yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your glucose readings here.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSugarCard(BuildContext context, BloodSugar sugar) {
    final statusColor = _getStatusColor(sugar.status);
    final dateTime = DateFormat(
      'MMM dd, yyyy - hh:mm a',
    ).format(_parseBloodSugarDateTime(sugar));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.14)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bloodtype_rounded,
                      size: 24,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sugar.displayValue,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sugar.type,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () => _showEditDialog(context, sugar),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () => _showDeleteDialog(context, sugar.id!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.health_and_safety_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sugar.status,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (sugar.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    sugar.notes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Low':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Elevated':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  DateTime _parseBloodSugarDateTime(BloodSugar sugar) {
    final timeValue = sugar.time.trim();
    if (timeValue.contains(RegExp(r'\b(AM|PM)\b', caseSensitive: false))) {
      return DateFormat('yyyy-MM-dd hh:mm a').parse('${sugar.date} $timeValue');
    }
    return DateFormat('yyyy-MM-dd HH:mm').parse('${sugar.date} $timeValue');
  }

  Future<void> _showAddDialog(
    BuildContext context,
    MedicineProvider provider,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => _BloodSugarDialog(
        onSave: (bp) {
          provider.addBloodSugar(bp);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, BloodSugar sugar) async {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    await showDialog(
      context: context,
      builder: (context) => _BloodSugarDialog(
        bloodSugar: sugar,
        onSave: (updated) {
          provider.updateBloodSugar(updated);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, int id) async {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteBloodSugar(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BloodSugarDialog extends StatefulWidget {
  final BloodSugar? bloodSugar;
  final Function(BloodSugar) onSave;

  const _BloodSugarDialog({this.bloodSugar, required this.onSave});

  @override
  State<_BloodSugarDialog> createState() => _BloodSugarDialogState();
}

class _BloodSugarDialogState extends State<_BloodSugarDialog> {
  late TextEditingController _valueController;
  late TextEditingController _notesController;
  late String _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final _types = ['Fasting', 'Before Meal', 'After Meal', 'Other'];

  @override
  void initState() {
    super.initState();
    final sugar = widget.bloodSugar;
    final now = DateTime.now();

    _valueController = TextEditingController(
      text: sugar?.value.toStringAsFixed(1) ?? '',
    );
    _notesController = TextEditingController(text: sugar?.notes ?? '');
    _selectedType = sugar?.type ?? _types[0];
    _selectedDate = sugar != null ? DateTime.parse(sugar.date) : now;
    if (sugar != null) {
      _selectedTime = _parseTimeOfDay(sugar.time);
    } else {
      _selectedTime = TimeOfDay.fromDateTime(now);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.bloodSugar == null ? 'Add Blood Sugar' : 'Edit Blood Sugar',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Value (mg/dL)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _types
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
              decoration: const InputDecoration(
                labelText: 'Reading type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              subtitle: const Text('Date'),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_selectedTime.format(context)),
              subtitle: const Text('Time'),
              trailing: const Icon(Icons.access_time_rounded),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  TimeOfDay _parseTimeOfDay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return TimeOfDay(hour: 0, minute: 0);

    if (trimmed.contains(RegExp(r'\b(AM|PM)\b', caseSensitive: false))) {
      final parsed = DateFormat.jm().parse(trimmed);
      return TimeOfDay.fromDateTime(parsed);
    }

    final parts = trimmed.split(':');
    final hour = int.tryParse(parts[0].trim()) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _parseBloodSugarDateTime(BloodSugar sugar) {
    final timeValue = sugar.time.trim();
    if (timeValue.contains(RegExp(r'\b(AM|PM)\b', caseSensitive: false))) {
      return DateFormat('yyyy-MM-dd hh:mm a').parse('${sugar.date} $timeValue');
    }
    return DateFormat('yyyy-MM-dd HH:mm').parse('${sugar.date} $timeValue');
  }

  void _save() {
    final value = double.tryParse(_valueController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid blood sugar value.')),
      );
      return;
    }

    final sugar = BloodSugar(
      id: widget.bloodSugar?.id,
      value: value,
      type: _selectedType,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      time:
          _selectedTime.hour.toString().padLeft(2, '0') +
          ':' +
          _selectedTime.minute.toString().padLeft(2, '0'),
      notes: _notesController.text.trim(),
      patient: Provider.of<MedicineProvider>(
        context,
        listen: false,
      ).activeProfile,
      createdAt:
          widget.bloodSugar?.createdAt ??
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );

    widget.onSave(sugar);
  }
}
