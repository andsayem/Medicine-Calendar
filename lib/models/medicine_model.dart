class Medicine {
  final int? id;
  final String name;
  final String type;
  final String dosage;
  final String quantity;
  final String doctor;
  final String notes;
  final String image;
  final String reminderTime;
  final String expiryDate;
  final String patient;
  final String createdAt;

  const Medicine({
    this.id,
    required this.name,
    required this.type,
    required this.dosage,
    required this.quantity,
    required this.doctor,
    required this.notes,
    required this.image,
    required this.reminderTime,
    required this.expiryDate,
    this.patient = 'Self',
    required this.createdAt,
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      quantity: map['quantity'] as String? ?? '',
      doctor: map['doctor'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      image: map['image'] as String? ?? '',
      reminderTime: map['reminder_time'] as String? ?? '',
      expiryDate: map['expiry_date'] as String? ?? '',
      patient: map['patient'] as String? ?? 'Self',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'dosage': dosage,
      'quantity': quantity,
      'doctor': doctor,
      'notes': notes,
      'image': image,
      'reminder_time': reminderTime,
      'expiry_date': expiryDate,
      'patient': patient,
      'created_at': createdAt,
    };
  }

  Medicine copyWith({
    int? id,
    String? name,
    String? type,
    String? dosage,
    String? quantity,
    String? doctor,
    String? notes,
    String? image,
    String? reminderTime,
    String? expiryDate,
    String? patient,
    String? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      doctor: doctor ?? this.doctor,
      notes: notes ?? this.notes,
      image: image ?? this.image,
      reminderTime: reminderTime ?? this.reminderTime,
      expiryDate: expiryDate ?? this.expiryDate,
      patient: patient ?? this.patient,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
