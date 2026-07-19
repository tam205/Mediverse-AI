class InteractionRule {
  const InteractionRule({
    required this.id,
    required this.medicineAId,
    required this.medicineBId,
    required this.severity,
    required this.explanation,
    required this.recommendedAction,
    required this.evidenceSource,
    required this.reviewStatus,
    required this.version,
  });

  final String id;
  final String medicineAId;
  final String medicineBId;
  final String severity;
  final String explanation;
  final String recommendedAction;
  final String evidenceSource;
  final String reviewStatus;
  final int version;

  bool get approved => reviewStatus.toLowerCase() == 'approved';

  static String keyFor(String medicineAId, String medicineBId) {
    final ids = [medicineAId, medicineBId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  factory InteractionRule.fromMap(String id, Map<String, dynamic> map) {
    return InteractionRule(
      id: id,
      medicineAId:
          map['medicineAId'] as String? ?? map['drugA'] as String? ?? '',
      medicineBId:
          map['medicineBId'] as String? ?? map['drugB'] as String? ?? '',
      severity: map['severity'] as String? ?? 'Informational',
      explanation:
          map['explanation'] as String? ?? map['message'] as String? ?? '',
      recommendedAction:
          map['recommendedAction'] as String? ??
          map['recommendation'] as String? ??
          'Ask a doctor or pharmacist if you are unsure.',
      evidenceSource:
          map['evidenceSource'] as String? ?? 'Reviewed rule database',
      reviewStatus: map['reviewStatus'] as String? ?? 'draft',
      version: (map['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineAId': medicineAId,
      'medicineBId': medicineBId,
      'severity': severity,
      'explanation': explanation,
      'recommendedAction': recommendedAction,
      'evidenceSource': evidenceSource,
      'reviewStatus': reviewStatus,
      'version': version,
    };
  }

  static const demo = [
    InteractionRule(
      id: 'aspirin_warfarin',
      medicineAId: 'aspirin',
      medicineBId: 'warfarin',
      severity: 'Major',
      explanation:
          'Aspirin may increase bleeding risk when taken with warfarin.',
      recommendedAction:
          'Consult a doctor or pharmacist before using this combination. Seek urgent care for unusual bleeding, black stool, vomiting blood, or severe weakness.',
      evidenceSource: 'Clinical review required before patient release',
      reviewStatus: 'approved',
      version: 1,
    ),
    InteractionRule(
      id: 'ibuprofen_warfarin',
      medicineAId: 'ibuprofen',
      medicineBId: 'warfarin',
      severity: 'Major',
      explanation:
          'Ibuprofen can increase bleeding risk and may affect kidney function when used with warfarin.',
      recommendedAction:
          'Avoid repeated use unless a clinician has reviewed it. Ask about safer pain-relief options.',
      evidenceSource: 'Clinical review required before patient release',
      reviewStatus: 'approved',
      version: 1,
    ),
    InteractionRule(
      id: 'aspirin_ibuprofen',
      medicineAId: 'aspirin',
      medicineBId: 'ibuprofen',
      severity: 'Moderate',
      explanation:
          'Ibuprofen may increase stomach bleeding risk and can interfere with low-dose aspirin timing.',
      recommendedAction:
          'Ask a pharmacist how to time these medicines and avoid repeated combined use without advice.',
      evidenceSource: 'Clinical review required before patient release',
      reviewStatus: 'approved',
      version: 1,
    ),
    InteractionRule(
      id: 'amlodipine_ibuprofen',
      medicineAId: 'amlodipine',
      medicineBId: 'ibuprofen',
      severity: 'Moderate',
      explanation:
          'Ibuprofen may reduce blood-pressure control and increase kidney monitoring needs in some patients taking amlodipine.',
      recommendedAction:
          'Use the lowest suitable dose for the shortest time and ask a pharmacist if repeated doses are needed.',
      evidenceSource: 'Clinical review required before patient release',
      reviewStatus: 'approved',
      version: 1,
    ),
    InteractionRule(
      id: 'diclofenac_warfarin',
      medicineAId: 'diclofenac',
      medicineBId: 'warfarin',
      severity: 'Major',
      explanation:
          'Diclofenac may increase bleeding and stomach-ulcer risk when combined with warfarin.',
      recommendedAction:
          'Do not use this combination unless a prescriber specifically approves it.',
      evidenceSource: 'Clinical review required before patient release',
      reviewStatus: 'approved',
      version: 1,
    ),
    InteractionRule(
      id: 'metronidazole_warfarin',
      medicineAId: 'metronidazole',
      medicineBId: 'warfarin',
      severity: 'Major',
      explanation:
          'Metronidazole can increase warfarin effect and raise bleeding risk.',
      recommendedAction:
          'Contact the prescriber or anticoagulation clinic for monitoring advice.',
      evidenceSource: 'Clinical review required before patient release',
      reviewStatus: 'approved',
      version: 1,
    ),
  ];
}
