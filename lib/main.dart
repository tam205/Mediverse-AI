import 'package:flutter/material.dart';

import 'app/mediverse_app.dart';
import 'features/auth/services/auth_service.dart';

export 'app/mediverse_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(const MediverseApp());
}
