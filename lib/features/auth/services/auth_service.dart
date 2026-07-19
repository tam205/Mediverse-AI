import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import '../../../services/user_service.dart';

class AuthService {
  const AuthService._();

  static bool firebaseReady = false;

  static String get currentUserId {
    if (firebaseReady) {
      return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    }
    return 'demo-user';
  }

  static String get currentUserName {
    if (!firebaseReady) return 'Demo User';
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      final name = email
          .split('@')
          .first
          .replaceAll('.', ' ')
          .replaceAll('_', ' ');
      return name
          .split(' ')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
    }
    return 'User';
  }

  static String get currentUserEmail {
    if (!firebaseReady) return 'demo@mediverse.ai';
    return FirebaseAuth.instance.currentUser?.email ?? 'No email added';
  }

  static String get currentUserInitials {
    final parts = currentUserName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      firebaseReady = true;
      debugPrint(
        'Firebase project: ${DefaultFirebaseOptions.currentPlatform.projectId}',
      );
      debugPrint(
        'Realtime Database URL: ${DefaultFirebaseOptions.currentPlatform.databaseURL}',
      );
    } catch (_) {
      firebaseReady = false;
    }
  }

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (!firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return AuthResult.demo('Demo sign in is active.');
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_messageFor(error));
    }
  }

  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String languageCode,
  }) async {
    if (!firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return AuthResult.demo('Demo account created.');
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(name);
      if (credential.user != null) {
        await const UserService().createUserProfile(
          user: credential.user!,
          name: name,
        );
        await FirebaseAuth.instance.setLanguageCode(languageCode);
        await credential.user!.sendEmailVerification();
      }
      await credential.user?.reload();
      return AuthResult.success();
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_messageFor(error));
    }
  }

  static Future<AuthResult> sendPasswordReset({
    required String email,
    required String languageCode,
  }) async {
    if (!firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return AuthResult.demo('Password reset email sent if an account exists.');
    }

    try {
      final auth = FirebaseAuth.instance;
      await auth.setLanguageCode(languageCode);
      await auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult._(
        ok: true,
        message: 'Password reset email sent if an account exists.',
        demoMode: false,
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_messageFor(error));
    }
  }

  static Future<AuthResult> sendEmailVerification() async {
    if (!firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return const AuthResult._(
        ok: true,
        message: 'verification-sent',
        demoMode: true,
      );
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return AuthResult.failure('no-user');
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser?.emailVerified == true) {
        return AuthResult.success('already-verified');
      }

      await refreshedUser?.sendEmailVerification();

      return AuthResult.success('verification-sent');
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(error.code);
    } catch (_) {
      return AuthResult.failure('unknown-error');
    }
  }

  static Future<bool> isCurrentUserEmailVerified() async {
    if (!firebaseReady) return true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    await user.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified == true;
  }

  static Future<void> signOut() async {
    if (firebaseReady) {
      await FirebaseAuth.instance.signOut();
    }
  }

  static String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-not-found' => 'No account was found for this email.',
      'wrong-password' => 'The password is incorrect.',
      'email-already-in-use' => 'This email is already registered.',
      'weak-password' => 'Use at least 6 characters for your password.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
  }
}

class AuthResult {
  const AuthResult._({
    required this.ok,
    required this.message,
    required this.demoMode,
  });

  final bool ok;
  final String message;
  final bool demoMode;

  factory AuthResult.success([String message = 'Success']) {
    return AuthResult._(ok: true, message: message, demoMode: false);
  }

  factory AuthResult.demo(String message) {
    return AuthResult._(ok: true, message: message, demoMode: true);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(ok: false, message: message, demoMode: false);
  }
}
