import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chrome.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import '../shell/app_shell.dart';
import 'login_screen.dart';
import 'services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.initialLanguage = AuthLanguage.english,
  });

  final AuthLanguage initialLanguage;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AuthLanguage _language;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  RegisterCopy get copy => RegisterCopy.forLanguage(_language);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthService.register(
      name: _nameController.text.trim(),
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
      appBar: MediverseAppBar(title: text.appBarTitle),
      body: ScreenPadding(
        child: ListView(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: LanguageSelector(
                value: _language,
                onChanged: (value) => setState(() => _language = value),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.ocean.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_outlined,
                        color: AppColors.ocean,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      text.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text.subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FieldLabel(text.fullName),
                    MediverseTextField(
                      hint: text.fullNameHint,
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) return text.nameRequired;
                        if (name.length < 2) return text.nameTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(text.email),
                    MediverseTextField(
                      hint: text.emailHint,
                      controller: _emailController,
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) => _validateEmail(value, text),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(text.password),
                    MediverseTextField(
                      hint: text.passwordHint,
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) => _validatePassword(value, text),
                      onSubmitted: (_) {
                        if (!_loading) _register();
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text.passwordGuidance,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SafetyNotice(text: text.safetyNote),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      _AuthErrorMessage(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    PrimaryButton(
                      label: _loading ? text.creating : text.createButton,
                      onPressed: _loading ? null : _register,
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
                    text.haveAccount,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      text.signIn,
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

  String? _validateEmail(String? value, RegisterCopy text) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return text.emailRequired;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return text.invalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value, RegisterCopy text) {
    final password = value ?? '';
    if (password.isEmpty) return text.passwordRequired;
    if (password.length < 6) return text.passwordTooShort;
    return null;
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

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice({required this.text});

  final String text;

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
          const Icon(Icons.verified_user_outlined, color: AppColors.ocean),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterCopy {
  const RegisterCopy({
    required this.appBarTitle,
    required this.title,
    required this.subtitle,
    required this.fullName,
    required this.fullNameHint,
    required this.email,
    required this.emailHint,
    required this.password,
    required this.passwordHint,
    required this.passwordGuidance,
    required this.safetyNote,
    required this.createButton,
    required this.creating,
    required this.haveAccount,
    required this.signIn,
    required this.nameRequired,
    required this.nameTooShort,
    required this.emailRequired,
    required this.invalidEmail,
    required this.passwordRequired,
    required this.passwordTooShort,
  });

  final String appBarTitle;
  final String title;
  final String subtitle;
  final String fullName;
  final String fullNameHint;
  final String email;
  final String emailHint;
  final String password;
  final String passwordHint;
  final String passwordGuidance;
  final String safetyNote;
  final String createButton;
  final String creating;
  final String haveAccount;
  final String signIn;
  final String nameRequired;
  final String nameTooShort;
  final String emailRequired;
  final String invalidEmail;
  final String passwordRequired;
  final String passwordTooShort;

  static RegisterCopy forLanguage(AuthLanguage language) {
    return switch (language) {
      AuthLanguage.french => const RegisterCopy(
        appBarTitle: 'Créer un compte',
        title: 'Créer votre compte',
        subtitle:
            'Enregistrez votre profil de santé, vos rappels et votre historique de vérification des médicaments.',
        fullName: 'Nom complet',
        fullNameHint: 'Saisissez votre nom complet',
        email: 'Adresse e-mail',
        emailHint: 'Saisissez votre adresse e-mail',
        password: 'Mot de passe',
        passwordHint: 'Au moins 6 caractères',
        passwordGuidance:
            'Utilisez au moins 6 caractères. Choisissez un mot de passe que vous n’utilisez pas ailleurs.',
        safetyNote:
            'Mediverse AI fournit des informations éducatives sur les médicaments. L’application ne remplace pas l’avis d’un médecin ou d’un pharmacien.',
        createButton: 'Créer le compte',
        creating: 'Création du compte...',
        haveAccount: 'Vous avez déjà un compte ? ',
        signIn: 'Se connecter',
        nameRequired: 'Veuillez saisir votre nom complet.',
        nameTooShort: 'Veuillez saisir au moins 2 caractères.',
        emailRequired: 'Veuillez saisir votre adresse e-mail.',
        invalidEmail: 'Veuillez saisir une adresse e-mail valide.',
        passwordRequired: 'Veuillez saisir un mot de passe.',
        passwordTooShort:
            'Votre mot de passe doit contenir au moins 6 caractères.',
      ),
      AuthLanguage.english => const RegisterCopy(
        appBarTitle: 'Create account',
        title: 'Create your account',
        subtitle:
            'Save your health profile, reminders, and medicine safety history.',
        fullName: 'Full name',
        fullNameHint: 'Enter your full name',
        email: 'Email address',
        emailHint: 'Enter your email address',
        password: 'Password',
        passwordHint: 'At least 6 characters',
        passwordGuidance:
            'Use at least 6 characters. Choose a password you do not use elsewhere.',
        safetyNote:
            'Mediverse AI provides educational medicine information and does not replace advice from a doctor or pharmacist.',
        createButton: 'Create account',
        creating: 'Creating account...',
        haveAccount: 'Already have an account? ',
        signIn: 'Sign in',
        nameRequired: 'Please enter your full name.',
        nameTooShort: 'Please enter at least 2 characters.',
        emailRequired: 'Please enter your email address.',
        invalidEmail: 'Please enter a valid email address.',
        passwordRequired: 'Please enter a password.',
        passwordTooShort: 'Your password must be at least 6 characters.',
      ),
    };
  }
}
