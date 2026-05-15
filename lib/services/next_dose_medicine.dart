import '../models/medicine_model.dart';

class NextDoseMedicine {
  final Medicine medicine;
  final DateTime nextDoseTime;

  NextDoseMedicine({required this.medicine, required this.nextDoseTime});

  String get name => medicine.name;
  String get dosage => medicine.dosage;
  String get type => medicine.type;
}
