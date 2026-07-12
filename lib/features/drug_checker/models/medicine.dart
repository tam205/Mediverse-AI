import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.category,
    required this.uses,
    required this.sideEffects,
    required this.warnings,
    required this.pregnancyWarning,
    required this.whenToSeeDoctor,
  });

  final String id;
  final String name;
  final String category;
  final String uses;
  final String sideEffects;
  final String warnings;
  final String pregnancyWarning;
  final String whenToSeeDoctor;

  static const demo = [
    Medicine(
      id: 'paracetamol',
      name: 'Paracetamol',
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
      name: 'Ibuprofen',
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
      id: 'warfarin',
      name: 'Warfarin',
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
      id: 'aspirin',
      name: 'Aspirin',
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
      id: 'amlodipine',
      name: 'Amlodipine',
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
  ];

  factory Medicine.fromMap(String id, Map<String, dynamic> map) {
    return Medicine(
      id: id,
      name: map['name'] as String? ?? id,
      category: map['category'] as String? ?? 'Medicine profile',
      uses: map['uses'] as String? ?? '',
      sideEffects: map['sideEffects'] as String? ?? '',
      warnings: map['warnings'] as String? ?? '',
      pregnancyWarning: map['pregnancyWarning'] as String? ?? '',
      whenToSeeDoctor: map['whenToSeeDoctor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
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
      id: name.toLowerCase().replaceAll(' ', '-'),
      name: name,
      category: 'Medicine profile',
      uses:
          'Medicine information will load from the drug database when connected.',
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

  Color get color {
    return switch (category) {
      'Blood thinner' => AppColors.coral,
      'Blood pressure' => AppColors.sky,
      'Pain and inflammation' => AppColors.amber,
      _ => AppColors.ocean,
    };
  }
}
