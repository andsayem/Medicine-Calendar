class MedicalDocument {
  final int? id;
  final String title;
  final String image;
  final String date;
  final String notes;
  final String patient;

  MedicalDocument({
    this.id,
    required this.title,
    required this.image,
    required this.date,
    this.notes = '',
    this.patient = 'Self',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'image': image,
      'date': date,
      'notes': notes,
      'patient': patient,
    };
  }

  factory MedicalDocument.fromMap(Map<String, dynamic> map) {
    return MedicalDocument(
      id: map['id'] as int?,
      title: map['title'] as String,
      image: map['image'] as String,
      date: map['date'] as String,
      notes: map['notes'] as String? ?? '',
      patient: map['patient'] as String? ?? 'Self',
    );
  }

  MedicalDocument copyWith({
    int? id,
    String? title,
    String? image,
    String? date,
    String? notes,
    String? patient,
  }) {
    return MedicalDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      patient: patient ?? this.patient,
    );
  }
}
