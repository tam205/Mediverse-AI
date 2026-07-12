import 'package:firebase_database/firebase_database.dart';

class Allergy {
  const Allergy({
    required this.substance,
    required this.reaction,
    required this.severity,
  });

  final String substance;
  final String reaction;
  final String severity;

  factory Allergy.fromMap(Map<String, dynamic> map) {
    return Allergy(
      substance: map['substance']?.toString() ?? '',
      reaction: map['reaction']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {'substance': substance, 'reaction': reaction, 'severity': severity};
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
    required this.currentMedicines,
    required this.emergencyName,
    required this.emergencyRelationship,
    required this.emergencyCountryCode,
    required this.emergencyPhone,
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
  final List<String> currentMedicines;
  final String emergencyName;
  final String emergencyRelationship;
  final String emergencyCountryCode;
  final String emergencyPhone;
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
    final values = [
      name,
      email,
      phone,
      dateOfBirth,
      gender,
      country,
      language,
      age > 0 ? '$age' : '',
      weightKg > 0 ? '$weightKg' : '',
      heightCm > 0 ? '$heightCm' : '',
      bloodGroup,
      allergies.isNotEmpty ? 'allergies' : '',
      currentMedicines.isNotEmpty ? 'medicines' : '',
      emergencyName,
      emergencyPhone,
      dataConsent ? 'consent' : '',
    ];
    final complete = values.where((value) => value.trim().isNotEmpty).length;
    return ((complete / values.length) * 100).round();
  }

  String get missingGuidance {
    final missing = <String>[];
    if (allergies.isEmpty) {
      missing.add('allergies');
    }
    if (currentMedicines.isEmpty) {
      missing.add('current medicines');
    }
    if (!hasEmergencyContact) {
      missing.add('emergency contact');
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
      age: 34,
      weightKg: 72,
      heightCm: 170,
      bloodGroup: 'O+',
      allergyEntries: const [
        Allergy(
          substance: 'Penicillin',
          reaction: 'Rash and swelling',
          severity: 'Moderate',
        ),
        Allergy(
          substance: 'Peanuts',
          reaction: 'Swelling',
          severity: 'Moderate',
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
      currentMedicines: ['Amlodipine', 'Vitamin D3', 'Paracetamol'],
      emergencyName: 'Mary Doe',
      emergencyRelationship: 'Sister',
      emergencyCountryCode: '+243',
      emergencyPhone: '000 000 000',
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
    currentMedicines: const [],
    emergencyName: '',
    emergencyRelationship: '',
    emergencyCountryCode: '',
    emergencyPhone: '',
    dataConsent: false,
    lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory HealthProfile.fromMap(Map<String, dynamic> map) {
    final fallback = HealthProfile.demoForUser();
    final allergyEntries = _allergyEntriesFromMap(map);
    return HealthProfile(
      name: map['name'] as String? ?? fallback.name,
      email: map['email'] as String? ?? fallback.email,
      phone: map['phone'] as String? ?? fallback.phone,
      dateOfBirth: map['dateOfBirth'] as String? ?? fallback.dateOfBirth,
      gender: map['gender'] as String? ?? fallback.gender,
      country: map['country'] as String? ?? fallback.country,
      language: map['language'] as String? ?? fallback.language,
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
      currentMedicines: List<String>.from(
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
    String? bloodGroup,
    List<Allergy>? allergyEntries,
    List<String>? medicineAllergies,
    List<String>? foodAllergies,
    bool? hasDiabetes,
    bool? hasHypertension,
    bool? hasAsthma,
    List<String>? otherChronicDiseases,
    String? pregnancyBreastfeeding,
    List<String>? currentMedicines,
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
      currentMedicines: currentMedicines ?? this.currentMedicines,
      emergencyName: emergencyName,
      emergencyRelationship: emergencyRelationship,
      emergencyCountryCode: emergencyCountryCode,
      emergencyPhone: emergencyPhone,
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
        ? allergyEntries.first.severity
        : allergySeverity;

    return {
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'country': country,
      'language': language,
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
      'currentMedicines': currentMedicines,
      'emergencyName': emergencyName,
      'emergencyRelationship': emergencyRelationship,
      'emergencyCountryCode': emergencyCountryCode,
      'emergencyPhone': emergencyPhone,
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
}
