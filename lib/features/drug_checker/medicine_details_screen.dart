import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import 'models/medicine.dart';
import 'services/medicine_repository.dart';

class MedicineDetailsScreen extends StatefulWidget {
  const MedicineDetailsScreen({super.key, required this.name});

  final String name;

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  final _repository = const MedicineRepository();
  late Future<Medicine> _medicineFuture;

  @override
  void initState() {
    super.initState();
    _medicineFuture = _repository.getMedicine(widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediverseAppBar(title: widget.name),
      body: ScreenPadding(
        child: FutureBuilder<Medicine>(
          future: _medicineFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final medicine = snapshot.data!;
            return Column(
              children: [
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: medicine.color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.medication_outlined,
                          color: medicine.color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              medicine.category,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DetailSection(title: 'Uses', body: medicine.uses),
                _DetailSection(
                  title: 'Side effects',
                  body: medicine.sideEffects,
                ),
                _DetailSection(title: 'Warnings', body: medicine.warnings),
                _DetailSection(
                  title: 'Pregnancy/breastfeeding warning',
                  body: medicine.pregnancyWarning,
                ),
                _DetailSection(
                  title: 'When to see a doctor',
                  body: medicine.whenToSeeDoctor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
