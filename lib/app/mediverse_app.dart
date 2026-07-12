import 'package:flutter/material.dart';

import 'auth_gate.dart';
import '../core/theme/app_theme.dart';

class MediverseApp extends StatelessWidget {
  const MediverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mediverse AI',
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
