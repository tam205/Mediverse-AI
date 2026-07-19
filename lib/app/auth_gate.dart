import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/auth/email_verification_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/services/auth_service.dart';
import '../features/onboarding/first_time_onboarding_screen.dart';
import '../features/shell/app_shell.dart';
import '../services/user_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.firebaseReady) return const LoginScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.canvas,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) return const LoginScreen();
        if (!user.emailVerified) {
          return EmailVerificationScreen(email: user.email ?? '');
        }

        return const _ProfileCompletionGate();
      },
    );
  }
}

class _ProfileCompletionGate extends StatelessWidget {
  const _ProfileCompletionGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: const UserService().watchProfileCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.canvas,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) return const AppShell();
        return const FirstTimeOnboardingScreen();
      },
    );
  }
}
