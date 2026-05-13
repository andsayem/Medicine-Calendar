class Doctor {
  final int? id;
  final String name;
  final String specialty;
  final String phone;

  Doctor({
    this.id,
    required this.name,
    this.specialty = '',
    this.phone = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'specialty': specialty,
      'phone': phone,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] as int?,
      name: map['name'] as String,
      specialty: map['specialty'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }
}
