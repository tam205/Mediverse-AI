import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.title,
    required this.status,
    required this.type,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String status;
  final String type;
  final Color color;
  final IconData icon;
  final DateTime createdAt;

  static final demo = [
    HistoryRecord(
      id: '1',
      title: 'Paracetamol + Ibuprofen',
      status: 'No known concern found',
      type: 'interaction',
      color: AppColors.emerald,
      icon: Icons.check_circle_outline,
      createdAt: DateTime(2024),
    ),
    HistoryRecord(
      id: '2',
      title: 'Amlodipine + Ibuprofen',
      status: 'Caution advised',
      type: 'interaction',
      color: AppColors.amber,
      icon: Icons.warning_amber_rounded,
      createdAt: DateTime(2024),
    ),
    HistoryRecord(
      id: '3',
      title: 'Warfarin + Aspirin',
      status: 'High-risk warning',
      type: 'interaction',
      color: AppColors.coral,
      icon: Icons.report_problem_outlined,
      createdAt: DateTime(2024),
    ),
    HistoryRecord(
      id: '4',
      title: 'Prescription Scanned',
      status: '23 May 2024, 11:10 AM',
      type: 'scan',
      color: AppColors.ocean,
      icon: Icons.document_scanner_outlined,
      createdAt: DateTime(2024),
    ),
    HistoryRecord(
      id: '5',
      title: 'AI Chat: Vitamin C + Iron',
      status: '22 May 2024, 02:45 PM',
      type: 'chat',
      color: AppColors.sky,
      icon: Icons.chat_bubble_outline,
      createdAt: DateTime(2024),
    ),
  ];

  factory HistoryRecord.fromMap(String id, Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'interaction';
    final severity =
        (map['riskLevel'] as String? ??
                map['severity'] as String? ??
                map['result'] as String? ??
                map['status'] as String? ??
                'safe')
            .toLowerCase();
    final color = switch (severity) {
      'danger' || 'high' || 'high-risk warning' => AppColors.coral,
      'caution' ||
      'moderate' ||
      'medium' ||
      'caution advised' => AppColors.amber,
      _ => AppColors.emerald,
    };
    final icon = switch (type) {
      'scan' => Icons.document_scanner_outlined,
      'chat' => Icons.chat_bubble_outline,
      _ => Icons.medication_outlined,
    };
    final drugA = map['drugA'] as String? ?? '';
    final drugB = map['drugB'] as String? ?? '';
    final medicines = List<String>.from(map['medicines'] as List? ?? const []);
    final fallbackTitle = medicines.isNotEmpty
        ? medicines.join(' + ')
        : [
            drugA,
            drugB,
          ].where((medicine) => medicine.trim().isNotEmpty).join(' + ');

    return HistoryRecord(
      id: id,
      title: map['title'] as String? ?? fallbackTitle,
      status: _displayStatus(
        map['status'] as String? ??
            map['riskLevel'] as String? ??
            map['result'] as String? ??
            '',
      ),
      type: type,
      color: color,
      icon: icon,
      createdAt: _createdAtFromMap(map),
    );
  }

  static DateTime _createdAtFromMap(Map<String, dynamic> map) {
    final value = map['createdAt'];
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _displayStatus(String value) {
    return switch (value.toLowerCase()) {
      'safe' || 'no interaction' => 'No known concern found',
      'caution' => 'Caution advised',
      'danger' || 'high' => 'High-risk warning',
      _ => value,
    };
  }
}
