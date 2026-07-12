import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
      return AuthResult.demo(
        'Demo sign in active until Firebase is configured.',
      );
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
  }) async {
    if (!firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return AuthResult.demo(
        'Demo account created. Add Firebase config to persist users.',
      );
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
      }
      await credential.user?.reload();
      return AuthResult.success();
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_messageFor(error));
    }
  }

  static Future<AuthResult> sendPasswordReset(String email) async {
    if (!firebaseReady) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return AuthResult.demo(
        'Password reset preview. Firebase email reset will work after configuration.',
      );
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return AuthResult.success();
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_messageFor(error));
    }
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

  factory AuthResult.success() {
    return const AuthResult._(ok: true, message: 'Success', demoMode: false);
  }

  factory AuthResult.demo(String message) {
    return AuthResult._(ok: true, message: message, demoMode: true);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(ok: false, message: message, demoMode: false);
  }
}
