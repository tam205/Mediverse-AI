import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class Medicine {
  const Medicine({
    required this.id,
    required this.genericName,
    required this.brandNames,
    required this.aliases,
    required this.activeIngredient,
    required this.strength,
    required this.dosageForm,
    required this.reviewStatus,
    required this.category,
    required this.uses,
    required this.sideEffects,
    required this.warnings,
    required this.pregnancyWarning,
    required this.whenToSeeDoctor,
  });

  final String id;
  final String genericName;
  final List<String> brandNames;
  final List<String> aliases;
  final String activeIngredient;
  final String strength;
  final String dosageForm;
  final String reviewStatus;
  final String category;
  final String uses;
  final String sideEffects;
  final String warnings;
  final String pregnancyWarning;
  final String whenToSeeDoctor;

  String get name => genericName;
  bool get approved => reviewStatus.toLowerCase() == 'approved';
  String get searchableText {
    return [
      id,
      genericName,
      activeIngredient,
      strength,
      dosageForm,
      ...brandNames,
      ...aliases,
    ].join(' ').toLowerCase();
  }

  String get suggestionSubtitle {
    final brands = brandNames.isEmpty ? '' : 'Brands: ${brandNames.join(', ')}';
    return [
      if (brands.isNotEmpty) brands,
      if (activeIngredient.isNotEmpty) 'Active: $activeIngredient',
      if (dosageForm.isNotEmpty) dosageForm,
    ].join(' - ');
  }

  static const demo = [
    Medicine(
      id: 'paracetamol',
      genericName: 'Paracetamol',
      brandNames: ['Panadol', 'Calpol', 'Tylenol'],
      aliases: ['Acetaminophen', 'Paracetamol 500 mg'],
      activeIngredient: 'Paracetamol',
      strength: '500 mg',
      dosageForm: 'Tablet',
      reviewStatus: 'approved',
      category: 'Pain and fever',
      uses: 'Used to reduce fever and relieve mild to moderate pain.',
      sideEffects: 'Usually well tolerated. High doses may damage the liver.',
      warnings:
          'Avoid taking more than the recommended daily dose. Be careful with liver disease or alcohol use.',
      pregnancyWarning:
          'Often used during pregnancy when advised, but pregnant or breastfeeding users should confirm with a clinician.',
      whenToSeeDoctor:
          'Seek help for overdose, persistent fever, yellow eyes, severe weakness, or worsening pain.',
    ),
    Medicine(
      id: 'ibuprofen',
      genericName: 'Ibuprofen',
      brandNames: ['Advil', 'Nurofen', 'Brufen'],
      aliases: ['Ibuprofen 200 mg', 'Ibuprofen 400 mg'],
      activeIngredient: 'Ibuprofen',
      strength: '200 mg / 400 mg',
      dosageForm: 'Tablet',
      reviewStatus: 'approved',
      category: 'Pain and inflammation',
      uses:
          'Used for pain, fever, inflammation, dental pain, and muscle aches.',
      sideEffects:
          'May cause stomach pain, heartburn, dizziness, kidney strain, or bleeding risk.',
      warnings:
          'Avoid with stomach ulcers, kidney disease, blood thinners, uncontrolled hypertension, or repeated use without advice.',
      pregnancyWarning:
          'Avoid especially late in pregnancy unless prescribed. Ask a doctor if breastfeeding.',
      whenToSeeDoctor:
          'Seek help for black stool, vomiting blood, chest pain, swelling, severe stomach pain, or breathing difficulty.',
    ),
    Medicine(
      id: 'aspirin',
      genericName: 'Aspirin',
      brandNames: ['Disprin', 'Bayer Aspirin'],
      aliases: ['Acetylsalicylic acid', 'ASA'],
      activeIngredient: 'Aspirin',
      strength: '75 mg / 300 mg',
      dosageForm: 'Tablet',
      reviewStatus: 'approved',
      category: 'Pain and antiplatelet',
      uses:
          'Used for pain or, at low dose, to reduce clotting when prescribed.',
      sideEffects:
          'May cause stomach irritation, bleeding, ringing in ears, or allergic reactions.',
      warnings:
          'Avoid combining with blood thinners unless a doctor directs it. Avoid in children unless prescribed.',
      pregnancyWarning:
          'Ask a doctor before use during pregnancy or breastfeeding.',
      whenToSeeDoctor:
          'Seek help for bleeding, black stool, severe stomach pain, wheezing, swelling, or allergic symptoms.',
    ),
    Medicine(
      id: 'warfarin',
      genericName: 'Warfarin',
      brandNames: ['Coumadin', 'Marevan'],
      aliases: ['Warfarin sodium'],
      activeIngredient: 'Warfarin',
      strength: '1 mg / 3 mg / 5 mg',
      dosageForm: 'Tablet',
      reviewStatus: 'approved',
      category: 'Blood thinner',
      uses:
          'Used to reduce blood clot risk when prescribed and monitored by a clinician.',
      sideEffects:
          'Can cause bruising, bleeding, nosebleeds, or serious internal bleeding.',
      warnings:
          'Requires medical monitoring. Many medicines and foods can change its effect.',
      pregnancyWarning:
          'Can harm pregnancy. Users who are pregnant or planning pregnancy need urgent clinician guidance.',
      whenToSeeDoctor:
          'Seek urgent care for heavy bleeding, black stool, vomiting blood, severe headache, fall injury, or unusual bruising.',
    ),
    Medicine(
      id: 'amoxicillin',
      genericName: 'Amoxicillin',
      brandNames: ['Amoxil'],
      aliases: ['Amoxycillin'],
      activeIngredient: 'Amoxicillin',
      strength: '250 mg / 500 mg',
      dosageForm: 'Capsule',
      reviewStatus: 'approved',
      category: 'Antibiotic',
      uses: 'Used for some bacterial infections when prescribed.',
      sideEffects: 'May cause diarrhea, nausea, rash, or allergic reactions.',
      warnings:
          'Avoid if allergic to penicillin unless a clinician has reviewed it.',
      pregnancyWarning: 'Ask a clinician before use during pregnancy.',
      whenToSeeDoctor:
          'Seek urgent help for swelling, breathing trouble, severe rash, or persistent diarrhea.',
    ),
    Medicine(
      id: 'metformin',
      genericName: 'Metformin',
      brandNames: ['Glucophage'],
      aliases: ['Metformin hydrochloride'],
      activeIngredient: 'Metformin',
      strength: '500 mg / 850 mg',
      dosageForm: 'Tablet',
      reviewStatus: 'approved',
      category: 'Diabetes',
      uses: 'Used to help manage blood sugar in type 2 diabetes.',
      sideEffects:
          'May cause nausea, diarrhea, stomach upset, or low appetite.',
      warnings:
          'Kidney function may need monitoring. Follow prescriber instructions.',
      pregnancyWarning: 'Ask a clinician before use during pregnancy.',
      whenToSeeDoctor:
          'Seek help for severe weakness, breathing difficulty, or dehydration.',
    ),
    Medicine(
      id: 'amlodipine',
      genericName: 'Amlodipine',
      brandNames: ['Norvasc'],
      aliases: ['Amlodipine besylate'],
      activeIngredient: 'Amlodipine',
      strength: '5 mg / 10 mg',
      dosageForm: 'Tablet',
      reviewStatus: 'approved',
      category: 'Blood pressure',
      uses:
          'Used to treat high blood pressure and some heart-related chest pain.',
      sideEffects:
          'May cause ankle swelling, flushing, dizziness, headache, or fatigue.',
      warnings:
          'Do not stop suddenly without advice. Monitor dizziness or very low blood pressure symptoms.',
      pregnancyWarning:
          'Ask a doctor before use in pregnancy or breastfeeding.',
      whenToSeeDoctor:
          'Seek help for fainting, severe swelling, chest pain, or shortness of breath.',
    ),
    Medicine(
      id: 'diclofenac',
      genericName: 'Diclofenac',
      brandNames: ['Voltaren', 'Cataflam'],
      aliases: ['Diclofenac sodium', 'Diclofenac potassium'],
      activeIngredient: 'Diclofenac',
      strength: '25 mg / 50 mg',
      dosageForm: 'Tablet / gel',
      reviewStatus: 'approved',
      category: 'Pain and inflammation',
      uses: 'Used for pain and inflammation when suitable.',
      sideEffects:
          'May cause stomach irritation, bleeding risk, kidney strain, or swelling.',
      warnings:
          'Avoid with ulcers, kidney disease, blood thinners, or repeated use without advice.',
      pregnancyWarning: 'Avoid late in pregnancy unless prescribed.',
      whenToSeeDoctor:
          'Seek help for chest pain, black stool, vomiting blood, or severe stomach pain.',
    ),
    Medicine(
      id: 'omeprazole',
      genericName: 'Omeprazole',
      brandNames: ['Losec', 'Prilosec'],
      aliases: ['Omeprazole magnesium'],
      activeIngredient: 'Omeprazole',
      strength: '20 mg',
      dosageForm: 'Capsule',
      reviewStatus: 'approved',
      category: 'Stomach acid',
      uses: 'Used for acid reflux, ulcers, and stomach protection.',
      sideEffects: 'May cause headache, stomach upset, nausea, or diarrhea.',
      warnings:
          'Long-term use should be reviewed by a clinician when possible.',
      pregnancyWarning: 'Ask a clinician before use during pregnancy.',
      whenToSeeDoctor:
          'Seek help for trouble swallowing, vomiting blood, black stool, or unexplained weight loss.',
    ),
    Medicine(
      id: 'metronidazole',
      genericName: 'Metronidazole',
      brandNames: ['Flagyl'],
      aliases: ['Metronidazole 400 mg'],
      activeIngredient: 'Metronidazole',
      strength: '400 mg',
      dosageForm: 'Tablet',
      reviewStatus: 'approved',
      category: 'Antibiotic',
      uses: 'Used for certain bacterial and parasitic infections.',
      sideEffects: 'May cause metallic taste, nausea, headache, or dizziness.',
      warnings:
          'Avoid alcohol during treatment and for a short period after unless a clinician advises otherwise.',
      pregnancyWarning: 'Ask a clinician before use during pregnancy.',
      whenToSeeDoctor:
          'Seek help for severe rash, numbness, seizures, or persistent vomiting.',
    ),
  ];

  factory Medicine.fromMap(String id, Map<String, dynamic> map) {
    final genericName =
        map['genericName'] as String? ?? map['name'] as String? ?? id;
    return Medicine(
      id: id,
      genericName: genericName,
      brandNames: List<String>.from(map['brandNames'] as List? ?? const []),
      aliases: List<String>.from(map['aliases'] as List? ?? const []),
      activeIngredient: map['activeIngredient'] as String? ?? genericName,
      strength: map['strength'] as String? ?? '',
      dosageForm: map['dosageForm'] as String? ?? '',
      reviewStatus: map['reviewStatus'] as String? ?? 'draft',
      category: map['category'] as String? ?? 'Medicine profile',
      uses: map['uses'] as String? ?? map['description'] as String? ?? '',
      sideEffects: map['sideEffects'] as String? ?? '',
      warnings: map['warnings'] as String? ?? '',
      pregnancyWarning: map['pregnancyWarning'] as String? ?? '',
      whenToSeeDoctor: map['whenToSeeDoctor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'genericName': genericName,
      'name': genericName,
      'brandNames': brandNames,
      'aliases': aliases,
      'activeIngredient': activeIngredient,
      'strength': strength,
      'dosageForm': dosageForm,
      'reviewStatus': reviewStatus,
      'category': category,
      'uses': uses,
      'description': uses,
      'sideEffects': sideEffects,
      'warnings': warnings,
      'pregnancyWarning': pregnancyWarning,
      'whenToSeeDoctor': whenToSeeDoctor,
    };
  }

  static Medicine fallback(String name) {
    return Medicine(
      id: normalizeId(name),
      genericName: name,
      brandNames: const [],
      aliases: const [],
      activeIngredient: name,
      strength: '',
      dosageForm: '',
      reviewStatus: 'unreviewed',
      category: 'Medicine profile',
      uses:
          'Medicine information will load from the reviewed medicine database when connected.',
      sideEffects:
          'Side effects depend on the medicine, dose, and patient health profile.',
      warnings:
          'Check allergies, diseases, pregnancy/breastfeeding, and current medicines before use.',
      pregnancyWarning:
          'Ask a doctor or pharmacist before using during pregnancy or breastfeeding.',
      whenToSeeDoctor:
          'Seek care for severe symptoms, allergic reaction, overdose, or worsening condition.',
    );
  }

  static String normalizeId(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\b\d+\s?(mg|ml|g|mcg|iu)\b'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final aliases = {
      'panadol': 'paracetamol',
      'tylenol': 'paracetamol',
      'acetaminophen': 'paracetamol',
      'advil': 'ibuprofen',
      'nurofen': 'ibuprofen',
      'brufen': 'ibuprofen',
      'disprin': 'aspirin',
      'bayer-aspirin': 'aspirin',
      'coumadin': 'warfarin',
      'marevan': 'warfarin',
      'amoxil': 'amoxicillin',
      'glucophage': 'metformin',
      'norvasc': 'amlodipine',
      'voltaren': 'diclofenac',
      'cataflam': 'diclofenac',
      'losec': 'omeprazole',
      'prilosec': 'omeprazole',
      'flagyl': 'metronidazole',
    };
    return aliases[cleaned] ?? cleaned;
  }

  Color get color {
    return switch (category) {
      'Blood thinner' => AppColors.coral,
      'Blood pressure' => AppColors.sky,
      'Pain and inflammation' => AppColors.amber,
      'Pain and antiplatelet' => AppColors.amber,
      'Diabetes' => AppColors.emerald,
      'Antibiotic' => AppColors.ocean,
      _ => AppColors.ocean,
    };
  }
}
