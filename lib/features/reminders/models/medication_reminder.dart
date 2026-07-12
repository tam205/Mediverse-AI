class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.name,
    required this.dose,
    required this.time,
    required this.period,
    required this.status,
  });

  final String id;
  final String name;
  final String dose;
  final String time;
  final String period;
  final String status;

  static const demo = [
    MedicationReminder(
      id: '1',
      name: 'Amoxicillin 500mg',
      dose: '1 capsule after breakfast',
      time: '08:00 AM',
      period: 'Morning',
      status: 'taken',
    ),
    MedicationReminder(
      id: '2',
      name: 'Ibuprofen 400mg',
      dose: '1 tablet after lunch',
      time: '01:00 PM',
      period: 'Afternoon',
      status: 'pending',
    ),
    MedicationReminder(
      id: '3',
      name: 'Vitamin D3 1000 IU',
      dose: '1 tablet after dinner',
      time: '08:00 PM',
      period: 'Evening',
      status: 'pending',
    ),
    MedicationReminder(
      id: '4',
      name: 'Asthma inhaler',
      dose: '2 puffs if prescribed',
      time: '10:00 PM',
      period: 'Night',
      status: 'missed',
    ),
  ];

  factory MedicationReminder.fromMap(String id, Map<String, dynamic> map) {
    return MedicationReminder(
      id: id,
      name: map['name'] as String? ?? '',
      dose: map['dose'] as String? ?? '',
      time: map['time'] as String? ?? '',
      period: map['period'] as String? ?? 'Morning',
      status: map['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dose': dose,
      'time': time,
      'period': period,
      'status': status,
    };
  }

  MedicationReminder copyWith({String? status}) {
    return MedicationReminder(
      id: id,
      name: name,
      dose: dose,
      time: time,
      period: period,
      status: status ?? this.status,
    );
  }
}
