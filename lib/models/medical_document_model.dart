import 'dart:convert';

class MedicalDocument {
  final int? id;
  final String title;
  final String image;
  final String date;
  final String notes;
  final String patient;
  final String doctor;
  final String medicine;
  final String testReport;

  MedicalDocument({
    this.id,
    required this.title,
    required this.image,
    required this.date,
    this.notes = '',
    this.patient = 'Self',
    this.doctor = '',
    this.medicine = '',
    this.testReport = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'image': image,
      'date': date,
      'notes': notes,
      'patient': patient,
      'doctor': doctor,
      'medicine': medicine,
      'test_report': testReport,
    };
  }

  List<String> get imagePaths {
    if (image.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(image);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .where((path) => path.trim().isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Older records store one image path directly.
    }

    return [image];
  }

  String get primaryImage => imagePaths.isEmpty ? '' : imagePaths.first;

  static String encodeImages(List<String> paths) {
    final cleaned = paths
        .where((path) => path.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return '';
    if (cleaned.length == 1) return cleaned.first;
    return jsonEncode(cleaned);
  }

  factory MedicalDocument.fromMap(Map<String, dynamic> map) {
    return MedicalDocument(
      id: map['id'] as int?,
      title: map['title'] as String,
      image: map['image'] as String? ?? '',
      date: map['date'] as String,
      notes: map['notes'] as String? ?? '',
      patient: map['patient'] as String? ?? 'Self',
      doctor: map['doctor'] as String? ?? '',
      medicine: map['medicine'] as String? ?? '',
      testReport: map['test_report'] as String? ?? '',
    );
  }

  MedicalDocument copyWith({
    int? id,
    String? title,
    String? image,
    String? date,
    String? notes,
    String? patient,
    String? doctor,
    String? medicine,
    String? testReport,
  }) {
    return MedicalDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      patient: patient ?? this.patient,
      doctor: doctor ?? this.doctor,
      medicine: medicine ?? this.medicine,
      testReport: testReport ?? this.testReport,
    );
  }
}
