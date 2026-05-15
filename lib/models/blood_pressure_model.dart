class BloodPressure {
  final int? id;
  final int systolic;
  final int diastolic;
  final int? pulse; // ✅ optional now
  final String date;
  final String time;
  final String notes;
  final String patient;
  final String createdAt;

  const BloodPressure({
    this.id,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    required this.date,
    required this.time,
    this.notes = '',
    this.patient = 'Self',
    required this.createdAt,
  });

  factory BloodPressure.fromMap(Map<String, dynamic> map) {
    return BloodPressure(
      id: map['id'] as int?,
      systolic: map['systolic'] as int? ?? 0,
      diastolic: map['diastolic'] as int? ?? 0,
      pulse: map['pulse'] as int?, // ✅ nullable safe
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      patient: map['patient'] as String? ?? 'Self',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'date': date,
      'time': time,
      'notes': notes,
      'patient': patient,
      'created_at': createdAt,
    };
  }

  BloodPressure copyWith({
    int? id,
    int? systolic,
    int? diastolic,
    int? pulse,
    String? date,
    String? time,
    String? notes,
    String? patient,
    String? createdAt,
  }) {
    return BloodPressure(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      date: date ?? this.date,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      patient: patient ?? this.patient,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayValue => '$systolic/$diastolic';

  String get status {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 || diastolic < 90) return 'Stage 1 Hypertension';
    if (systolic >= 180 || diastolic >= 120) return 'Crisis';
    return 'Stage 2 Hypertension';
  }
}
