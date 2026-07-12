import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/brand_widgets.dart';
import '../../shared/widgets/form_fields.dart';
import '../shell/app_shell.dart';
import 'forgot_password_screen.dart';
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
  var _language = AuthLanguage.english;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AuthCopy get copy => AuthCopy.forLanguage(_language);

  Future<void> _signIn() async {
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
    setState(() => _loading = false);

    if (!result.ok) {
      setState(() => _errorMessage = result.message);
      return;
    }

    TextInput.finishAutofillContext();
    if (result.demoMode) {
      _showMessage(result.message);
      context.replaceWith(const AppShell());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = copy;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _AuthHero(subtitle: text.heroSubtitle)),
                const SizedBox(width: 12),
                LanguageSelector(
                  value: _language,
                  onChanged: (value) => setState(() => _language = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.signInTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text.signInSubtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FieldLabel(text.email),
                    MediverseTextField(
                      hint: text.emailHint,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.mail_outline,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) => _validateEmail(value, text),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(text.password),
                    MediverseTextField(
                      hint: text.passwordHint,
                      controller: _passwordController,
                      obscure: _obscurePassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      suffixIconTooltip: _obscurePassword
                          ? text.showPassword
                          : text.hidePassword,
                      onSuffixIconPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) => _validatePassword(value, text),
                      onSubmitted: (_) {
                        if (!_loading) _signIn();
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.pushScreen(const ForgotPasswordScreen()),
                        child: Text(text.forgotPassword),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      _AuthErrorMessage(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    _SignInButton(
                      label: text.signInButton,
                      loadingLabel: text.signingIn,
                      loading: _loading,
                      onPressed: _loading ? null : _signIn,
                    ),
                    const SizedBox(height: 16),
                    _SecureSignInNote(
                      title: text.secureSignInTitle,
                      disclaimer: text.disclaimer,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    text.noAccount,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  GestureDetector(
                    onTap: () => context.pushScreen(
                      RegisterScreen(initialLanguage: _language),
                    ),
                    child: Text(
                      text.createAccount,
                      style: const TextStyle(
                        color: AppColors.ocean,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value, AuthCopy text) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return text.emailRequired;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return text.invalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value, AuthCopy text) {
    final password = value ?? '';
    if (password.isEmpty) return text.passwordRequired;
    if (password.length < 6) return text.passwordTooShort;
    return null;
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepTeal, AppColors.ocean],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ocean.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const ShieldLogo(size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mediverse AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
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
      child: FilledButton(
        onPressed: onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(loadingLabel),
                  ],
                )
              : Text(key: const ValueKey('label'), label),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade800)),
          ),
        ],
      ),
    );
  }
}

class _SecureSignInNote extends StatelessWidget {
  const _SecureSignInNote({required this.title, required this.disclaimer});

  final String title;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.ocean),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  disclaimer,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum AuthLanguage { english, french }

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AuthLanguage value;
  final ValueChanged<AuthLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AuthLanguage>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: AuthLanguage.english, child: Text('English')),
        PopupMenuItem(value: AuthLanguage.french, child: Text('Français')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_outlined, size: 19),
            const SizedBox(width: 6),
            Text(
              value == AuthLanguage.english ? 'English' : 'Français',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class AuthCopy {
  const AuthCopy({
    required this.signInTitle,
    required this.signInSubtitle,
    required this.heroSubtitle,
    required this.secureSignInTitle,
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
  });

  final String signInTitle;
  final String signInSubtitle;
  final String heroSubtitle;
  final String secureSignInTitle;
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

  static AuthCopy forLanguage(AuthLanguage language) {
    return switch (language) {
      AuthLanguage.french => const AuthCopy(
        signInTitle: 'Bon retour',
        signInSubtitle:
            'Connectez-vous pour vérifier vos médicaments et gérer vos informations de santé.',
        heroSubtitle:
            'Accédez en toute sécurité aux outils de vérification des médicaments et aux ressources de santé.',
        secureSignInTitle: 'Connexion sécurisée',
        email: 'Adresse e-mail',
        emailHint: 'Saisissez votre adresse e-mail',
        password: 'Mot de passe',
        passwordHint: 'Saisissez votre mot de passe',
        forgotPassword: 'Mot de passe oublié ?',
        signInButton: 'Se connecter',
        signingIn: 'Connexion en cours...',
        showPassword: 'Afficher le mot de passe',
        hidePassword: 'Masquer le mot de passe',
        disclaimer:
            'Mediverse AI fournit des informations éducatives sur les médicaments. L’application ne remplace pas l’avis d’un médecin ou d’un pharmacien.',
        noAccount: 'Nouveau sur Mediverse AI ? ',
        createAccount: 'Créer un compte',
        emailRequired: 'Veuillez saisir votre adresse e-mail.',
        invalidEmail: 'Veuillez saisir une adresse e-mail valide.',
        passwordRequired: 'Veuillez saisir votre mot de passe.',
        passwordTooShort:
            'Votre mot de passe doit contenir au moins 6 caractères.',
      ),
      AuthLanguage.english => const AuthCopy(
        signInTitle: 'Welcome back',
        signInSubtitle:
            'Sign in to check medicine safety and manage your personal health information.',
        heroSubtitle:
            'Secure access to medicine safety tools and trusted health education.',
        secureSignInTitle: 'Secure sign-in',
        email: 'Email address',
        emailHint: 'Enter your email address',
        password: 'Password',
        passwordHint: 'Enter your password',
        forgotPassword: 'Forgot your password?',
        signInButton: 'Sign in',
        signingIn: 'Signing you in...',
        showPassword: 'Show password',
        hidePassword: 'Hide password',
        disclaimer:
            'Mediverse AI provides educational medicine information and does not replace advice from a doctor or pharmacist.',
        noAccount: 'New to Mediverse AI? ',
        createAccount: 'Create an account',
        emailRequired: 'Please enter your email address.',
        invalidEmail: 'Please enter a valid email address.',
        passwordRequired: 'Please enter your password.',
        passwordTooShort: 'Your password must be at least 6 characters.',
      ),
    };
  }
}
