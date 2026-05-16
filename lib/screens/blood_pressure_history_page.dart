import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/blood_pressure_model.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';

class BloodPressureHistoryPage extends StatefulWidget {
  const BloodPressureHistoryPage({super.key});

  @override
  State<BloodPressureHistoryPage> createState() =>
      _BloodPressureHistoryPageState();
}

class _BloodPressureHistoryPageState extends State<BloodPressureHistoryPage> {
  bool _showForm = false;
  BloodPressure? _editBp;

  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _pulse = TextEditingController();
  final _notes = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  void _startAdd() {
    setState(() {
      _editBp = null;
      _showForm = true;
      _clear();
    });
  }

  void _startEdit(BloodPressure bp) {
    setState(() {
      _editBp = bp;
      _showForm = true;

      _sys.text = bp.systolic.toString();
      _dia.text = bp.diastolic.toString();
      _pulse.text = bp.pulse?.toString() ?? '';
      _notes.text = bp.notes;

      _date = DateTime.parse(bp.date);

      final t = bp.time.split(':');
      _time = TimeOfDay(
        hour: int.tryParse(t[0]) ?? 0,
        minute: int.tryParse(t[1]) ?? 0,
      );
    });
  }

  void _clear() {
    _sys.clear();
    _dia.clear();
    _pulse.clear();
    _notes.clear();
    _date = DateTime.now();
    _time = TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MedicineProvider>(context);
    final list = provider.bloodPressures;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Blood Pressure History',
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

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _startAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reading'),
      ),

      body: Column(
        children: [
          if (_showForm) _buildForm(provider),

          Expanded(
            child: list.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final bp = list[i];
                      final prev = i + 1 < list.length ? list[i + 1] : null;
                      return _premiumCard(bp, prev);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ================= PREMIUM CARD =================
  Widget _premiumCard(BloodPressure bp, BloodPressure? prev) {
    final statusColor = bp.pulse != null ? Colors.red : AppColors.primary;
    final diffSys = prev != null ? bp.systolic - prev.systolic : null;
    final dateTime = DateFormat(
      'MMM dd, yyyy - hh:mm a',
    ).format(DateTime.parse('${bp.date} ${bp.time}'));

    return GestureDetector(
      onTap: () => _popup(bp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                color: statusColor.withOpacity(0.14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.monitor_heart_rounded,
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
                            '${bp.systolic}/${bp.diastolic}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pulse: ${bp.pulse ?? 'N/A'} BPM',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (diffSys != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (diffSys >= 0 ? Colors.red : Colors.green)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${diffSys >= 0 ? '+' : ''}$diffSys',
                          style: TextStyle(
                            color: diffSys >= 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                  if (bp.notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bp.notes,
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
      ),
    );
  }

  // ================= PILL UI =================
  Widget _pill(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.primary)),
          Text("$value", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 80,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 18),
          const Text(
            'No blood pressure records yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monitor your blood pressure readings here.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ================= POPUP =================
  void _popup(BloodPressure bp) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Blood Pressure Details",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _row("Systolic", bp.systolic.toString()),
              _row("Diastolic", bp.diastolic.toString()),
              _row("Pulse", bp.pulse?.toString() ?? "N/A"),
              _row("Date", bp.date),
              _row("Time", bp.time),

              const SizedBox(height: 12),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(a), Text(b)],
      ),
    );
  }

  // ================= FORM =================
  Widget _buildForm(MedicineProvider provider) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _editBp == null ? "Add Blood Pressure" : "Edit Blood Pressure",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showForm = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(child: _input(_sys, "Systolic", true)),
              const SizedBox(width: 10),
              Expanded(child: _input(_dia, "Diastolic", true)),
            ],
          ),

          const SizedBox(height: 10),

          _input(_pulse, "Pulse (optional)", true),
          const SizedBox(height: 10),
          _input(_notes, "Notes"),
        ],
      ),
    );
  }

  // ================= INPUT =================
  Widget _input(TextEditingController c, String h, [bool number = false]) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: h,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
