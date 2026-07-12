import 'package:flutter/material.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import '../drug_checker/result_screen.dart';
import '../drug_checker/services/interaction_engine.dart';
import 'models/prescription_scan.dart';
import 'services/prescription_scan_repository.dart';

class ReviewDetectedMedicinesScreen extends StatefulWidget {
  const ReviewDetectedMedicinesScreen({super.key});

  @override
  State<ReviewDetectedMedicinesScreen> createState() =>
      _ReviewDetectedMedicinesScreenState();
}

class _ReviewDetectedMedicinesScreenState
    extends State<ReviewDetectedMedicinesScreen> {
  final _repository = const PrescriptionScanRepository();
  final _engine = const InteractionEngine();
  final _controllers = PrescriptionScan.sampleMedicines
      .map((medicine) => TextEditingController(text: medicine))
      .toList();
  bool _saving = false;
  bool _checking = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _detectedMedicines {
    return _controllers
        .map((controller) => controller.text.trim())
        .where((medicine) => medicine.isNotEmpty)
        .toList();
  }

  String get _prescriptionText {
    return [
      'Rx',
      ..._detectedMedicines.asMap().entries.map(
        (entry) => '${entry.key + 1}. ${entry.value}',
      ),
    ].join('\n');
  }

  Future<void> _saveScan() async {
    setState(() => _saving = true);
    await _repository.saveScan(
      prescriptionText: _prescriptionText,
      detectedMedicines: _detectedMedicines,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription text saved securely.')),
    );
  }

  Future<void> _checkInteractions() async {
    setState(() => _checking = true);
    final result = await _engine.check(
      _detectedMedicines.map(_medicineNameOnly).toList(),
    );
    if (!mounted) return;
    setState(() => _checking = false);
    context.pushScreen(ResultScreen(result: result));
  }

  void _removeMedicine(int index) {
    if (_controllers.length <= 1) return;
    final controller = _controllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  void _addMedicine() {
    setState(() => _controllers.add(TextEditingController()));
  }

  String _medicineNameOnly(String value) {
    return value
        .replaceAll(
          RegExp(r'\b\d+\s?(mg|ml|g|mcg|iu)\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MediverseAppBar(title: 'Review Medicines'),
      body: ScreenPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detected from prescription',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review detected medicine text before saving. The image is not uploaded for this MVP.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description_outlined, color: AppColors.ocean),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Realtime Database scan record',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Saved fields: prescriptionText, detectedMedicines, createdAt. No Firebase Storage is used.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _prescriptionText,
                    style: const TextStyle(
                      color: AppColors.ink,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._controllers.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MediverseTextField(
                  hint: 'Detected medicine',
                  controller: entry.value,
                  prefixIcon: Icons.medication_outlined,
                  suffixIcon: _controllers.length > 1 ? Icons.close : null,
                  suffixIconTooltip: 'Remove medicine',
                  onSuffixIconPressed: () => _removeMedicine(entry.key),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addMedicine,
              icon: const Icon(Icons.add),
              label: const Text('Add detected medicine'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _saving ? 'Saving scan text...' : 'Save Scan Text',
              onPressed: _saving ? null : _saveScan,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checking ? null : _checkInteractions,
                icon: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.health_and_safety_outlined),
                label: Text(
                  _checking ? 'Checking interactions...' : 'Check Interactions',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
