import 'package:firebase_database/firebase_database.dart';

import '../../drug_checker/models/medicine.dart';

enum UserRole {
  patient,
  student,
  healthcareProfessional;

  static UserRole fromStoredValue(Object? value) {
    switch (value?.toString()) {
      case 'student':
        return UserRole.student;
      case 'professional':
      case 'healthcareProfessional':
        return UserRole.healthcareProfessional;
      default:
        return UserRole.patient;
    }
  }
}

enum AllergySeverity {
  mild,
  moderate,
  severe,
  unknown;

  String get label {
    switch (this) {
      case AllergySeverity.mild:
        return 'Mild';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.severe:
        return 'Severe';
      case AllergySeverity.unknown:
        return 'Not sure';
    }
  }

  static AllergySeverity fromStoredValue(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'mild':
        return AllergySeverity.mild;
      case 'moderate':
        return AllergySeverity.moderate;
      case 'severe':
        return AllergySeverity.severe;
      default:
        return AllergySeverity.unknown;
    }
  }
}

class Allergy {
  const Allergy({
    required this.id,
    required this.substance,
    required this.reaction,
    required this.severity,
  });

  final String id;
  final String substance;
  final String reaction;
  final AllergySeverity severity;

  factory Allergy.fromMap(Map<String, dynamic> map) {
    return Allergy(
      id: map['id']?.toString() ?? '',
      substance: map['substance']?.toString() ?? '',
      reaction: map['reaction']?.toString() ?? '',
      severity: AllergySeverity.fromStoredValue(map['severity']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'substance': substance,
      'reaction': reaction,
      'severity': severity.name,
    };
  }
}

class CurrentMedicine {
  const CurrentMedicine({
    required this.id,
    required this.name,
    this.normalizedName,
    this.strength,
    this.dose,
    this.frequency,
    this.reason,
    this.startDate,
  });

  final String id;
  final String name;
  final String? normalizedName;
  final String? strength;
  final String? dose;
  final String? frequency;
  final String? reason;
  final DateTime? startDate;

  String get normalized {
    final stored = normalizedName?.trim() ?? '';
    if (stored.isNotEmpty) return stored;
    return Medicine.normalizeId(name);
  }

  String get detailsLine {
    return [
      strength,
      dose,
      frequency,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' • ');
  }

  factory CurrentMedicine.fromMap(Map<String, dynamic> map) {
    final name = map['name']?.toString() ?? '';
    return CurrentMedicine(
      id: map['id']?.toString() ?? '',
      name: name,
      normalizedName:
          map['normalizedName']?.toString() ?? Medicine.normalizeId(name),
      strength: _optionalString(map['strength']),
      dose: _optionalString(map['dose']),
      frequency: _optionalString(map['frequency']),
      reason: _optionalString(map['reason']),
      startDate: DateTime.tryParse(map['startDate']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'normalizedName': normalized,
      if (strength?.trim().isNotEmpty ?? false) 'strength': strength!.trim(),
      if (dose?.trim().isNotEmpty ?? false) 'dose': dose!.trim(),
      if (frequency?.trim().isNotEmpty ?? false) 'frequency': frequency!.trim(),
      if (reason?.trim().isNotEmpty ?? false) 'reason': reason!.trim(),
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
    };
  }

  static String? _optionalString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class HealthProfile {
  const HealthProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.country,
    required this.language,
    required this.primaryRole,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.bloodGroup,
    required this.allergyEntries,
    required this.medicineAllergies,
    required this.foodAllergies,
    required this.allergyReaction,
    required this.allergySeverity,
    required this.hasDiabetes,
    required this.hasHypertension,
    required this.hasAsthma,
    required this.otherChronicDiseases,
    required this.pregnancyBreastfeeding,
    required this.currentMedicineEntries,
    required this.currentMedicines,
    required this.emergencyName,
    required this.emergencyRelationship,
    required this.emergencyCountryCode,
    required this.emergencyPhone,
    required this.allergiesReviewed,
    required this.medicinesReviewed,
    required this.conditionsReviewed,
    required this.dataConsent,
    required this.lastUpdated,
  });

  final String name;
  final String email;
  final String phone;
  final String dateOfBirth;
  final String gender;
  final String country;
  final String language;
  final UserRole primaryRole;
  final int age;
  final double weightKg;
  final double heightCm;
  final String bloodGroup;
  final List<Allergy> allergyEntries;
  final List<String> medicineAllergies;
  final List<String> foodAllergies;
  final String allergyReaction;
  final String allergySeverity;
  final bool hasDiabetes;
  final bool hasHypertension;
  final bool hasAsthma;
  final List<String> otherChronicDiseases;
  final String pregnancyBreastfeeding;
  final List<CurrentMedicine> currentMedicineEntries;
  final List<String> currentMedicines;
  final String emergencyName;
  final String emergencyRelationship;
  final String emergencyCountryCode;
  final String emergencyPhone;
  final bool allergiesReviewed;
  final bool medicinesReviewed;
  final bool conditionsReviewed;
  final bool dataConsent;
  final DateTime lastUpdated;

  List<String> get allergies {
    final structured = allergyEntries
        .map((allergy) => allergy.substance.trim())
        .where((substance) => substance.isNotEmpty)
        .toList();
    if (structured.isNotEmpty) return structured;
    return [...medicineAllergies, ...foodAllergies];
  }

  List<String> get chronicDiseases {
    final diseases = <String>[];
    if (hasDiabetes) diseases.add('Diabetes');
    if (hasHypertension) diseases.add('Hypertension');
    if (hasAsthma) diseases.add('Asthma');
    diseases.addAll(otherChronicDiseases);
    return diseases;
  }

  String get emergencyContact {
    if (emergencyName.trim().isEmpty || emergencyPhone.trim().isEmpty) {
      return 'Not added';
    }
    return '$emergencyName - $emergencyCountryCode $emergencyPhone';
  }

  bool get hasEmergencyContact => emergencyContact != 'Not added';

  int get completionPercent {
    var completed = 0;
    const total = 8;

    if (name.trim().isNotEmpty) completed++;
    if (age > 0 || dateOfBirth.trim().isNotEmpty) completed++;
    if (country.trim().isNotEmpty) completed++;
    completed++;
    if (allergiesReviewed) completed++;
    if (medicinesReviewed) completed++;
    if (conditionsReviewed) completed++;
    if (dataConsent) completed++;

    return ((completed / total) * 100).round();
  }

  String get missingGuidance {
    final missing = <String>[];
    if (!allergiesReviewed) {
      missing.add('allergies');
    }
    if (!medicinesReviewed) {
      missing.add('current medicines');
    }
    if (!conditionsReviewed) {
      missing.add('health conditions');
    }
    if (missing.isEmpty) {
      return 'Your safety profile is ready for smarter checks.';
    }
    return 'Add ${missing.join(' and ')} to improve safety checks.';
  }

  String get lastUpdatedLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${lastUpdated.day} ${months[lastUpdated.month - 1]} ${lastUpdated.year}';
  }

  static HealthProfile demoForUser({String? name, String? email}) {
    return HealthProfile(
      name: _present(name) ? name!.trim() : 'Demo User',
      email: _present(email) ? email!.trim() : 'demo@mediverse.ai',
      phone: '+243 000 000 000',
      dateOfBirth: '28 Jun 1992',
      gender: 'Not specified',
      country: 'DRC',
      language: 'English / French',
      primaryRole: UserRole.patient,
      age: 34,
      weightKg: 72,
      heightCm: 170,
      bloodGroup: 'O+',
      allergyEntries: const [
        Allergy(
          id: 'demo-penicillin',
          substance: 'Penicillin',
          reaction: 'Rash and swelling',
          severity: AllergySeverity.moderate,
        ),
        Allergy(
          id: 'demo-peanuts',
          substance: 'Peanuts',
          reaction: 'Swelling',
          severity: AllergySeverity.moderate,
        ),
      ],
      medicineAllergies: ['Penicillin'],
      foodAllergies: ['Peanuts'],
      allergyReaction: 'Rash and swelling',
      allergySeverity: 'Moderate',
      hasDiabetes: false,
      hasHypertension: true,
      hasAsthma: false,
      otherChronicDiseases: const [],
      pregnancyBreastfeeding: 'Not applicable',
      currentMedicineEntries: const [
        CurrentMedicine(
          id: 'demo-amlodipine',
          name: 'Amlodipine',
          normalizedName: 'amlodipine',
          strength: '5 mg',
          frequency: 'Once daily',
          reason: 'For hypertension',
        ),
        CurrentMedicine(
          id: 'demo-vitamin-d3',
          name: 'Vitamin D3',
          normalizedName: 'vitamin-d3',
          strength: '1000 IU',
          frequency: 'Once daily',
        ),
        CurrentMedicine(
          id: 'demo-paracetamol',
          name: 'Paracetamol',
          normalizedName: 'paracetamol',
          strength: '500 mg',
          frequency: 'When needed',
        ),
      ],
      currentMedicines: ['Amlodipine', 'Vitamin D3', 'Paracetamol'],
      emergencyName: 'Mary Doe',
      emergencyRelationship: 'Sister',
      emergencyCountryCode: '+243',
      emergencyPhone: '000 000 000',
      allergiesReviewed: true,
      medicinesReviewed: true,
      conditionsReviewed: true,
      dataConsent: true,
      lastUpdated: DateTime.now(),
    );
  }

  static final demo = HealthProfile.demoForUser();

  static final empty = HealthProfile(
    name: '',
    email: '',
    phone: '',
    dateOfBirth: '',
    gender: '',
    country: '',
    language: '',
    primaryRole: UserRole.patient,
    age: 0,
    weightKg: 0,
    heightCm: 0,
    bloodGroup: '',
    allergyEntries: const [],
    medicineAllergies: const [],
    foodAllergies: const [],
    allergyReaction: '',
    allergySeverity: '',
    hasDiabetes: false,
    hasHypertension: false,
    hasAsthma: false,
    otherChronicDiseases: const [],
    pregnancyBreastfeeding: 'Not applicable',
    currentMedicineEntries: const [],
    currentMedicines: const [],
    emergencyName: '',
    emergencyRelationship: '',
    emergencyCountryCode: '',
    emergencyPhone: '',
    allergiesReviewed: false,
    medicinesReviewed: false,
    conditionsReviewed: false,
    dataConsent: false,
    lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory HealthProfile.fromMap(Map<String, dynamic> map) {
    final fallback = HealthProfile.demoForUser();
    final allergyEntries = _allergyEntriesFromMap(map);
    final currentMedicineEntries = _currentMedicineEntriesFromMap(map);
    return HealthProfile(
      name: map['name'] as String? ?? fallback.name,
      email: map['email'] as String? ?? fallback.email,
      phone: map['phone'] as String? ?? fallback.phone,
      dateOfBirth: map['dateOfBirth'] as String? ?? fallback.dateOfBirth,
      gender: map['gender'] as String? ?? fallback.gender,
      country: map['country'] as String? ?? fallback.country,
      language: map['language'] as String? ?? fallback.language,
      primaryRole: UserRole.fromStoredValue(map['primaryRole']),
      age: (map['age'] as num?)?.toInt() ?? fallback.age,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? fallback.weightKg,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? fallback.heightCm,
      bloodGroup: map['bloodGroup'] as String? ?? fallback.bloodGroup,
      allergyEntries: allergyEntries,
      medicineAllergies: List<String>.from(
        map['medicineAllergies'] as List? ??
            _legacyAllergySubstances(map) ??
            fallback.medicineAllergies,
      ),
      foodAllergies: List<String>.from(
        map['foodAllergies'] as List? ?? fallback.foodAllergies,
      ),
      allergyReaction:
          map['allergyReaction'] as String? ?? fallback.allergyReaction,
      allergySeverity:
          map['allergySeverity'] as String? ?? fallback.allergySeverity,
      hasDiabetes: map['hasDiabetes'] as bool? ?? fallback.hasDiabetes,
      hasHypertension:
          map['hasHypertension'] as bool? ?? fallback.hasHypertension,
      hasAsthma: map['hasAsthma'] as bool? ?? fallback.hasAsthma,
      otherChronicDiseases: _otherChronicDiseasesFromMap(map),
      pregnancyBreastfeeding:
          map['pregnancyBreastfeeding'] as String? ??
          fallback.pregnancyBreastfeeding,
      currentMedicineEntries: currentMedicineEntries,
      currentMedicines: currentMedicineEntries.isNotEmpty
          ? currentMedicineEntries.map((medicine) => medicine.name).toList()
          : List<String>.from(
              map['currentMedicines'] as List? ?? fallback.currentMedicines,
            ),
      emergencyName: map['emergencyName'] as String? ?? fallback.emergencyName,
      emergencyRelationship:
          map['emergencyRelationship'] as String? ??
          fallback.emergencyRelationship,
      emergencyCountryCode:
          map['emergencyCountryCode'] as String? ??
          fallback.emergencyCountryCode,
      emergencyPhone:
          map['emergencyPhone'] as String? ?? fallback.emergencyPhone,
      allergiesReviewed:
          map['allergiesReviewed'] as bool? ?? allergyEntries.isNotEmpty,
      medicinesReviewed:
          map['medicinesReviewed'] as bool? ??
          (currentMedicineEntries.isNotEmpty ||
              ((map['currentMedicines'] as List?)?.isNotEmpty ?? false)),
      conditionsReviewed:
          map['conditionsReviewed'] as bool? ??
          (map['hasDiabetes'] == true ||
              map['hasHypertension'] == true ||
              map['hasAsthma'] == true ||
              (map['chronicDiseases'] as List? ?? const []).isNotEmpty),
      dataConsent: map['dataConsent'] as bool? ?? fallback.dataConsent,
      lastUpdated:
          DateTime.tryParse(map['lastUpdated'] as String? ?? '') ??
          fallback.lastUpdated,
    );
  }

  HealthProfile copyWith({
    String? name,
    String? email,
    DateTime? lastUpdated,
    int? age,
    String? country,
    UserRole? primaryRole,
    String? bloodGroup,
    List<Allergy>? allergyEntries,
    List<String>? medicineAllergies,
    List<String>? foodAllergies,
    bool? hasDiabetes,
    bool? hasHypertension,
    bool? hasAsthma,
    List<String>? otherChronicDiseases,
    String? pregnancyBreastfeeding,
    List<CurrentMedicine>? currentMedicineEntries,
    List<String>? currentMedicines,
    bool? allergiesReviewed,
    bool? medicinesReviewed,
    bool? conditionsReviewed,
    bool? dataConsent,
  }) {
    return HealthProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      country: country ?? this.country,
      language: language,
      primaryRole: primaryRole ?? this.primaryRole,
      age: age ?? this.age,
      weightKg: weightKg,
      heightCm: heightCm,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergyEntries: allergyEntries ?? this.allergyEntries,
      medicineAllergies: medicineAllergies ?? this.medicineAllergies,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      allergyReaction: allergyReaction,
      allergySeverity: allergySeverity,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      hasAsthma: hasAsthma ?? this.hasAsthma,
      otherChronicDiseases: otherChronicDiseases ?? this.otherChronicDiseases,
      pregnancyBreastfeeding:
          pregnancyBreastfeeding ?? this.pregnancyBreastfeeding,
      currentMedicineEntries:
          currentMedicineEntries ?? this.currentMedicineEntries,
      currentMedicines:
          currentMedicines ??
          currentMedicineEntries?.map((medicine) => medicine.name).toList() ??
          this.currentMedicines,
      emergencyName: emergencyName,
      emergencyRelationship: emergencyRelationship,
      emergencyCountryCode: emergencyCountryCode,
      emergencyPhone: emergencyPhone,
      allergiesReviewed: allergiesReviewed ?? this.allergiesReviewed,
      medicinesReviewed: medicinesReviewed ?? this.medicinesReviewed,
      conditionsReviewed: conditionsReviewed ?? this.conditionsReviewed,
      dataConsent: dataConsent ?? this.dataConsent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    final legacyMedicineAllergies = allergyEntries.isNotEmpty
        ? allergyEntries
              .map((allergy) => allergy.substance.trim())
              .where((substance) => substance.isNotEmpty)
              .toList()
        : medicineAllergies;
    final legacyReaction = allergyEntries.isNotEmpty
        ? allergyEntries.first.reaction
        : allergyReaction;
    final legacySeverity = allergyEntries.isNotEmpty
        ? allergyEntries.first.severity.name
        : allergySeverity;

    return {
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'country': country,
      'language': language,
      'primaryRole': primaryRole.name,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'bloodGroup': bloodGroup,
      'allergies': allergyEntries.map((allergy) => allergy.toMap()).toList(),
      'medicineAllergies': legacyMedicineAllergies,
      'foodAllergies': foodAllergies,
      'allergyReaction': legacyReaction,
      'allergySeverity': legacySeverity,
      'hasDiabetes': hasDiabetes,
      'hasHypertension': hasHypertension,
      'hasAsthma': hasAsthma,
      'chronicDiseases': chronicDiseases,
      'pregnancyBreastfeeding': pregnancyBreastfeeding,
      'currentMedicineEntries': currentMedicineEntries
          .map((medicine) => medicine.toMap())
          .toList(),
      'currentMedicines': currentMedicineEntries.isNotEmpty
          ? currentMedicineEntries.map((medicine) => medicine.name).toList()
          : currentMedicines,
      'emergencyName': emergencyName,
      'emergencyRelationship': emergencyRelationship,
      'emergencyCountryCode': emergencyCountryCode,
      'emergencyPhone': emergencyPhone,
      'allergiesReviewed': allergiesReviewed,
      'medicinesReviewed': medicinesReviewed,
      'conditionsReviewed': conditionsReviewed,
      'dataConsent': dataConsent,
      'updatedAt': ServerValue.timestamp,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  static bool _present(String? value) =>
      value != null && value.trim().isNotEmpty;

  static List<Allergy> _allergyEntriesFromMap(Map<String, dynamic> map) {
    final raw = map['allergies'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Allergy.fromMap(Map<String, dynamic>.from(item)))
          .where((allergy) => allergy.substance.trim().isNotEmpty)
          .toList();
    }
    if (raw is Map) {
      return raw.values
          .whereType<Map>()
          .map((item) => Allergy.fromMap(Map<String, dynamic>.from(item)))
          .where((allergy) => allergy.substance.trim().isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<String>? _legacyAllergySubstances(Map<String, dynamic> map) {
    final raw = map['allergies'];
    if (raw is List && raw.every((item) => item is String)) {
      return List<String>.from(raw);
    }
    return null;
  }

  static List<String> _otherChronicDiseasesFromMap(Map<String, dynamic> map) {
    final known = {'diabetes', 'hypertension', 'asthma'};
    return List<String>.from(
      map['chronicDiseases'] as List? ?? const [],
    ).where((condition) => !known.contains(condition.toLowerCase())).toList();
  }

  static List<CurrentMedicine> _currentMedicineEntriesFromMap(
    Map<String, dynamic> map,
  ) {
    final raw = map['currentMedicineEntries'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (item) => CurrentMedicine.fromMap(Map<String, dynamic>.from(item)),
          )
          .where((medicine) => medicine.name.trim().isNotEmpty)
          .toList();
    }
    if (raw is Map) {
      return raw.values
          .whereType<Map>()
          .map(
            (item) => CurrentMedicine.fromMap(Map<String, dynamic>.from(item)),
          )
          .where((medicine) => medicine.name.trim().isNotEmpty)
          .toList();
    }
    return const [];
  }
}
