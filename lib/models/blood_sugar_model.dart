class BloodSugar {
  final int? id;
  final double value;
  final String type;
  final String date;
  final String time;
  final String notes;
  final String patient;
  final String createdAt;

  const BloodSugar({
    this.id,
    required this.value,
    required this.type,
    required this.date,
    required this.time,
    this.notes = '',
    this.patient = 'Self',
    required this.createdAt,
  });

  factory BloodSugar.fromMap(Map<String, dynamic> map) {
    return BloodSugar(
      id: map['id'] as int?,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'Fasting',
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
      'value': value,
      'type': type,
      'date': date,
      'time': time,
      'notes': notes,
      'patient': patient,
      'created_at': createdAt,
    };
  }

  BloodSugar copyWith({
    int? id,
    double? value,
    String? type,
    String? date,
    String? time,
    String? notes,
    String? patient,
    String? createdAt,
  }) {
    return BloodSugar(
      id: id ?? this.id,
      value: value ?? this.value,
      type: type ?? this.type,
      date: date ?? this.date,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      patient: patient ?? this.patient,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayValue => '${value.toStringAsFixed(1)} mg/dL';

  String get status {
    if (value < 70) return 'Low';
    if (value < 100) return 'Normal';
    if (value <= 140) return 'Elevated';
    return 'High';
  }
}
