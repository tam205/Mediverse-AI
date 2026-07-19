import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/brand_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import '../shell/app_shell.dart';
import 'forgot_password_screen.dart';
import 'widgets/auth_language_selector.dart';
import 'register_screen.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthLanguage _language = AuthLanguage.english;

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  AuthCopy get copy => AuthCopy.forLanguage(_language);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (!result.ok) {
      setState(() {
        _errorMessage = _humanizeError(result.message);
      });
      return;
    }

    TextInput.finishAutofillContext();

    if (result.demoMode) {
      _showMessage(result.message);
      context.replaceWith(const AppShell());
    }

    // For normal login, AuthGate should detect the signed-in user
    // and automatically display AppShell.
  }

  String _humanizeError(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('user-not-found') ||
        normalized.contains('invalid-credential') ||
        normalized.contains('wrong-password')) {
      return copy.invalidCredentials;
    }

    if (normalized.contains('network') || normalized.contains('connection')) {
      return copy.networkError;
    }

    if (normalized.contains('too-many-requests')) {
      return copy.tooManyAttempts;
    }

    if (normalized.contains('user-disabled')) {
      return copy.accountDisabled;
    }

    return message.isEmpty ? copy.generalError : message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = copy;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          const Positioned(
            top: -100,
            right: -80,
            child: _BackgroundCircle(size: 240, opacity: 0.08),
          ),
          const Positioned(
            bottom: -110,
            left: -90,
            child: _BackgroundCircle(size: 280, opacity: 0.06),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 52,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: LanguageSelector(
                                value: _language,
                                onChanged: (value) {
                                  setState(() {
                                    _language = value;
                                    _errorMessage = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            _WelcomeHeader(
                              title: text.welcomeTitle,
                              subtitle: text.heroSubtitle,
                            ),

                            const SizedBox(height: 28),

                            _LoginCard(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      text.signInTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.4,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      text.signInSubtitle,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        height: 1.5,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    FieldLabel(text.email),
                                    const SizedBox(height: 7),
                                    MediverseTextField(
                                      hint: text.emailHint,
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      prefixIcon: Icons.mail_outline_rounded,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      validator: (value) =>
                                          _validateEmail(value, text),
                                    ),

                                    const SizedBox(height: 18),

                                    FieldLabel(text.password),
                                    const SizedBox(height: 7),
                                    MediverseTextField(
                                      hint: text.passwordHint,
                                      controller: _passwordController,
                                      obscure: _obscurePassword,
                                      prefixIcon: Icons.lock_outline_rounded,
                                      suffixIcon: _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      suffixIconTooltip: _obscurePassword
                                          ? text.showPassword
                                          : text.hidePassword,
                                      onSuffixIconPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      validator: (value) =>
                                          _validatePassword(value, text),
                                      onSubmitted: (_) {
                                        if (!_loading) {
                                          _signIn();
                                        }
                                      },
                                    ),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _loading
                                            ? null
                                            : () => context.pushScreen(
                                                ForgotPasswordScreen(
                                                  initialLanguage: _language,
                                                ),
                                              ),
                                        child: Text(
                                          text.forgotPassword,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),

                                    if (_errorMessage != null) ...[
                                      _AuthErrorMessage(
                                        message: _errorMessage!,
                                      ),
                                      const SizedBox(height: 18),
                                    ],

                                    _SignInButton(
                                      label: text.signInButton,
                                      loadingLabel: text.signingIn,
                                      loading: _loading,
                                      onPressed: _loading ? null : _signIn,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            _CreateAccountSection(
                              question: text.noAccount,
                              buttonText: text.createAccount,
                              onPressed: _loading
                                  ? null
                                  : () => context.pushScreen(
                                      RegisterScreen(
                                        initialLanguage: _language,
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 18),

                            Text(
                              text.disclaimer,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.muted,
                                height: 1.45,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value, AuthCopy text) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return text.emailRequired;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return text.invalidEmail;
    }

    return null;
  }

  String? _validatePassword(String? value, AuthCopy text) {
    final password = value ?? '';

    if (password.isEmpty) {
      return text.passwordRequired;
    }

    if (password.length < 6) {
      return text.passwordTooShort;
    }

    return null;
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.deepTeal, AppColors.ocean],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.ocean.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const ShieldLogo(size: 52),
        ),
        const SizedBox(height: 18),
        const Text(
          'Mediverse AI',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.deepTeal,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ocean,
          disabledBackgroundColor: AppColors.ocean.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Text(
                      loadingLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Icon(Icons.arrow_forward_rounded, size: 19),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AuthErrorMessage extends StatelessWidget {
  const _AuthErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.red.shade700,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red.shade800,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountSection extends StatelessWidget {
  const _CreateAccountSection({
    required this.question,
    required this.buttonText,
    required this.onPressed,
  });

  final String question;
  final String buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          question,
          style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
        ),
        const SizedBox(height: 5),
        TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
          label: Text(
            buttonText,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  const _BackgroundCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.ocean.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class AuthCopy {
  const AuthCopy({
    required this.welcomeTitle,
    required this.signInTitle,
    required this.signInSubtitle,
    required this.heroSubtitle,
    required this.email,
    required this.emailHint,
    required this.password,
    required this.passwordHint,
    required this.forgotPassword,
    required this.signInButton,
    required this.signingIn,
    required this.showPassword,
    required this.hidePassword,
    required this.disclaimer,
    required this.noAccount,
    required this.createAccount,
    required this.emailRequired,
    required this.invalidEmail,
    required this.passwordRequired,
    required this.passwordTooShort,
    required this.invalidCredentials,
    required this.networkError,
    required this.tooManyAttempts,
    required this.accountDisabled,
    required this.generalError,
  });

  final String welcomeTitle;
  final String signInTitle;
  final String signInSubtitle;
  final String heroSubtitle;
  final String email;
  final String emailHint;
  final String password;
  final String passwordHint;
  final String forgotPassword;
  final String signInButton;
  final String signingIn;
  final String showPassword;
  final String hidePassword;
  final String disclaimer;
  final String noAccount;
  final String createAccount;
  final String emailRequired;
  final String invalidEmail;
  final String passwordRequired;
  final String passwordTooShort;
  final String invalidCredentials;
  final String networkError;
  final String tooManyAttempts;
  final String accountDisabled;
  final String generalError;

  static AuthCopy forLanguage(AuthLanguage language) {
    return switch (language) {
      AuthLanguage.french => const AuthCopy(
        welcomeTitle: 'Votre santé, mieux comprise',
        signInTitle: 'Heureux de vous revoir',
        signInSubtitle:
            'Connectez-vous pour continuer à utiliser vos outils de sécurité médicamenteuse.',
        heroSubtitle:
            'Des informations simples et utiles pour vous aider à mieux comprendre vos médicaments.',
        email: 'Adresse e-mail',
        emailHint: 'exemple@adresse.com',
        password: 'Mot de passe',
        passwordHint: 'Saisissez votre mot de passe',
        forgotPassword: 'Mot de passe oublié ?',
        signInButton: 'Continuer',
        signingIn: 'Connexion en cours...',
        showPassword: 'Afficher le mot de passe',
        hidePassword: 'Masquer le mot de passe',
        disclaimer:
            'Mediverse AI fournit des informations éducatives et ne remplace pas les conseils d’un médecin ou d’un pharmacien.',
        noAccount: 'Vous n’avez pas encore de compte ?',
        createAccount: 'Créer mon compte',
        emailRequired: 'Saisissez votre adresse e-mail.',
        invalidEmail: 'Saisissez une adresse e-mail valide.',
        passwordRequired: 'Saisissez votre mot de passe.',
        passwordTooShort:
            'Le mot de passe doit contenir au moins 6 caractères.',
        invalidCredentials:
            'L’adresse e-mail ou le mot de passe est incorrect.',
        networkError:
            'Impossible de se connecter. Vérifiez votre connexion Internet.',
        tooManyAttempts:
            'Trop de tentatives. Patientez un moment avant de réessayer.',
        accountDisabled: 'Ce compte a été désactivé. Contactez l’assistance.',
        generalError: 'La connexion a échoué. Veuillez réessayer.',
      ),

      AuthLanguage.english => const AuthCopy(
        welcomeTitle: 'Your health, better understood',
        signInTitle: 'Good to see you again',
        signInSubtitle: 'Sign in to continue using your medicine safety tools.',
        heroSubtitle:
            'Clear and helpful information to help you better understand your medicines.',
        email: 'Email address',
        emailHint: 'example@email.com',
        password: 'Password',
        passwordHint: 'Enter your password',
        forgotPassword: 'Forgot your password?',
        signInButton: 'Continue',
        signingIn: 'Signing you in...',
        showPassword: 'Show password',
        hidePassword: 'Hide password',
        disclaimer:
            'Mediverse AI provides educational information and does not replace advice from a doctor or pharmacist.',
        noAccount: 'Do not have an account yet?',
        createAccount: 'Create my account',
        emailRequired: 'Enter your email address.',
        invalidEmail: 'Enter a valid email address.',
        passwordRequired: 'Enter your password.',
        passwordTooShort: 'Your password must contain at least 6 characters.',
        invalidCredentials: 'The email address or password is incorrect.',
        networkError: 'We could not connect. Check your Internet connection.',
        tooManyAttempts:
            'There have been too many attempts. Try again shortly.',
        accountDisabled: 'This account has been disabled. Contact support.',
        generalError: 'Sign-in was unsuccessful. Please try again.',
      ),
    };
  }
}
