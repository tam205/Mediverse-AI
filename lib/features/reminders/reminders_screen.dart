import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import 'models/medication_reminder.dart';
import 'services/reminder_repository.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _repository = const ReminderRepository();
  late Future<List<MedicationReminder>> _remindersFuture;
  var _items = <MedicationReminder>[];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    _remindersFuture = _repository.getReminders();
  }

  void _addReminder() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _AddReminderSheet(),
    );
  }

  Future<void> _updateStatus(int index, String status) async {
    final updated = _items[index].copyWith(status: status);
    setState(() => _items[index] = updated);
    await _repository.saveReminder(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MediverseAppBar(title: 'Medication Reminders'),
      body: ScreenPadding(
        child: FutureBuilder<List<MedicationReminder>>(
          future: _remindersFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_items.isEmpty) _items = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Medication Schedule',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                ..._items.asMap().entries.map((entry) {
                  final showPeriod =
                      entry.key == 0 ||
                      _items[entry.key - 1].period != entry.value.period;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showPeriod) ...[
                        Text(
                          entry.value.period,
                          style: const TextStyle(
                            color: AppColors.ocean,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _ReminderTile(
                        item: entry.value,
                        onTaken: () => _updateStatus(entry.key, 'taken'),
                        onMissed: () => _updateStatus(entry.key, 'missed'),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 18),
                PrimaryButton(label: 'Add Reminder', onPressed: _addReminder),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.item,
    required this.onTaken,
    required this.onMissed,
  });

  final MedicationReminder item;
  final VoidCallback onTaken;
  final VoidCallback onMissed;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      'taken' => AppColors.emerald,
      'missed' => AppColors.coral,
      _ => AppColors.amber,
    };
    final statusText = switch (item.status) {
      'taken' => 'Taken',
      'missed' => 'Missed',
      _ => 'Pending',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.status == 'missed' ? Icons.close : Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.dose,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        item.time,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (item.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMissed,
                      child: const Text('Missed'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onTaken,
                      child: const Text('Taken'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddReminderSheet extends StatelessWidget {
  const _AddReminderSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Reminder',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          SizedBox(height: 16),
          FieldLabel('Medicine'),
          MediverseTextField(hint: 'Medicine name'),
          SizedBox(height: 12),
          FieldLabel('Schedule'),
          MediverseTextField(hint: 'Example: 08:00 AM after breakfast'),
          SizedBox(height: 18),
          PrimaryButton(label: 'Save Reminder'),
        ],
      ),
    );
  }
}
