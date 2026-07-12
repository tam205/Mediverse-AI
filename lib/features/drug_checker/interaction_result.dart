import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum InteractionStatus { safe, caution, danger }

class InteractionResultCopy {
  const InteractionResultCopy({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.risk,
    required this.severity,
    required this.details,
    required this.whyRisky,
    required this.userAction,
    required this.professionalAdvice,
    required this.color,
    this.profileNotes = '',
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final String risk;
  final String severity;
  final String details;
  final String whyRisky;
  final String userAction;
  final String professionalAdvice;
  final Color color;
  final String profileNotes;

  InteractionResultCopy copyWith({
    String? subtitle,
    String? details,
    String? whyRisky,
    String? userAction,
    String? professionalAdvice,
    String? profileNotes,
  }) {
    return InteractionResultCopy(
      icon: icon,
      title: title,
      subtitle: subtitle ?? this.subtitle,
      body: body,
      risk: risk,
      severity: severity,
      details: details ?? this.details,
      whyRisky: whyRisky ?? this.whyRisky,
      userAction: userAction ?? this.userAction,
      professionalAdvice: professionalAdvice ?? this.professionalAdvice,
      color: color,
      profileNotes: profileNotes ?? this.profileNotes,
    );
  }

  static InteractionResultCopy fromStatus(InteractionStatus status) {
    switch (status) {
      case InteractionStatus.safe:
        return const InteractionResultCopy(
          icon: Icons.check_circle_outline,
          title: 'No known concern found',
          subtitle: 'Paracetamol + Ibuprofen',
          body:
              'These medicines do not show a known interaction in the available safety information.',
          risk: 'No known concern found',
          severity: 'None',
          details: 'No known interaction between Paracetamol and Ibuprofen.',
          whyRisky:
              'No major risk is currently shown for this pair in the demo data.',
          userAction:
              'Use medicines only as directed and avoid taking extra doses.',
          professionalAdvice:
              'Ask a doctor or pharmacist if symptoms continue, worsen, or if you have liver, kidney, pregnancy, or breastfeeding concerns.',
          color: AppColors.emerald,
        );
      case InteractionStatus.caution:
        return const InteractionResultCopy(
          icon: Icons.warning_amber_rounded,
          title: 'Caution advised',
          subtitle: 'Amlodipine + Ibuprofen',
          body:
              'These medicines may interact and should be reviewed carefully.',
          risk: 'Caution advised',
          severity: 'Moderate',
          details: 'Ibuprofen may reduce the effectiveness of Amlodipine.',
          whyRisky:
              'Some pain medicines can affect blood pressure control or kidney function in sensitive patients.',
          userAction:
              'Do not stop prescribed medicine. Monitor symptoms and avoid repeated use without advice.',
          professionalAdvice:
              'Speak with a pharmacist or doctor before using this combination, especially with hypertension, kidney disease, pregnancy, or older age.',
          color: AppColors.amber,
        );
      case InteractionStatus.danger:
        return const InteractionResultCopy(
          icon: Icons.report_problem_outlined,
          title: 'High-risk warning',
          subtitle: 'Warfarin + Aspirin',
          body: 'This combination may increase risk and needs medical review.',
          risk: 'High-risk warning',
          severity: 'High',
          details:
              'Aspirin may increase bleeding risk when taken with Warfarin.',
          whyRisky:
              'Both medicines can affect bleeding. Taken together, they may increase the chance of serious bleeding.',
          userAction:
              'Do not take this combination unless a doctor specifically told you to. Watch for bleeding, black stool, vomiting blood, or severe weakness.',
          professionalAdvice:
              'Contact a doctor or pharmacist immediately. If there are emergency symptoms, seek urgent care.',
          color: AppColors.coral,
        );
    }
  }
}
