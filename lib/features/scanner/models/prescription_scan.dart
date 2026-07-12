class PrescriptionScan {
  const PrescriptionScan({
    required this.id,
    required this.prescriptionText,
    required this.detectedMedicines,
    required this.createdAt,
  });

  final String id;
  final String prescriptionText;
  final List<String> detectedMedicines;
  final DateTime createdAt;

  static const sampleText = '''Rx
1. Amoxicillin 500mg
2. Ibuprofen 400mg
3. Paracetamol 500mg
4. Omeprazole 20mg''';

  static const sampleMedicines = [
    'Amoxicillin 500mg',
    'Ibuprofen 400mg',
    'Paracetamol 500mg',
    'Omeprazole 20mg',
  ];

  factory PrescriptionScan.fromMap(String id, Map<String, dynamic> map) {
    return PrescriptionScan(
      id: id,
      prescriptionText: map['prescriptionText'] as String? ?? '',
      detectedMedicines: List<String>.from(
        map['detectedMedicines'] as List? ?? const [],
      ),
      createdAt: _dateFrom(map['createdAt']),
    );
  }

  static DateTime _dateFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
