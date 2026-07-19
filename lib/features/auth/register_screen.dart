import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/form_fields.dart';
import '../shell/app_shell.dart';
import 'services/auth_service.dart';
import 'widgets/auth_language_selector.dart';

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
  final _confirmPasswordController = TextEditingController();

  late AuthLanguage _language;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedPrivacy = false;

  String? _errorMessage;

  RegisterCopy get copy => RegisterCopy.forLanguage(_language);

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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedPrivacy) {
      setState(() {
        _errorMessage = copy.privacyRequired;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      languageCode: _language == AuthLanguage.french ? 'fr' : 'en',
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

    // For normal registration, AuthGate should automatically
    // detect the signed-in user and display AppShell.
  }

  String _humanizeError(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('email-already-in-use')) {
      return copy.emailAlreadyUsed;
    }

    if (normalized.contains('invalid-email')) {
      return copy.invalidEmail;
    }

    if (normalized.contains('weak-password')) {
      return copy.weakPassword;
    }

    if (normalized.contains('network') || normalized.contains('connection')) {
      return copy.networkError;
    }

    if (normalized.contains('too-many-requests')) {
      return copy.tooManyAttempts;
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
            top: -90,
            right: -80,
            child: _BackgroundCircle(size: 230, opacity: 0.07),
          ),
          const Positioned(
            bottom: -110,
            left: -90,
            child: _BackgroundCircle(size: 270, opacity: 0.05),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: text.back,
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                                const Spacer(),
                                LanguageSelector(
                                  value: _language,
                                  onChanged: (value) {
                                    setState(() {
                                      _language = value;
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _RegistrationHeader(
                              title: text.headerTitle,
                              subtitle: text.headerSubtitle,
                            ),

                            const SizedBox(height: 26),

                            _RegisterCard(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      text.title,
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
                                      text.subtitle,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        height: 1.5,
                                        fontSize: 14,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    FieldLabel(text.fullName),

                                    const SizedBox(height: 7),

                                    MediverseTextField(
                                      hint: text.fullNameHint,
                                      controller: _nameController,
                                      prefixIcon: Icons.person_outline_rounded,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.name],
                                      validator: (value) =>
                                          _validateName(value, text),
                                    ),

                                    const SizedBox(height: 18),

                                    FieldLabel(text.email),

                                    const SizedBox(height: 7),

                                    MediverseTextField(
                                      hint: text.emailHint,
                                      controller: _emailController,
                                      prefixIcon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
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
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscure: _obscurePassword,
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
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      validator: (value) =>
                                          _validatePassword(value, text),
                                    ),

                                    const SizedBox(height: 8),

                                    _PasswordGuidance(
                                      text: text.passwordGuidance,
                                    ),

                                    const SizedBox(height: 18),

                                    FieldLabel(text.confirmPassword),

                                    const SizedBox(height: 7),

                                    MediverseTextField(
                                      hint: text.confirmPasswordHint,
                                      controller: _confirmPasswordController,
                                      prefixIcon: Icons.lock_reset_rounded,
                                      obscure: _obscureConfirmPassword,
                                      suffixIcon: _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      suffixIconTooltip: _obscureConfirmPassword
                                          ? text.showPassword
                                          : text.hidePassword,
                                      onSuffixIconPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      validator: (value) =>
                                          _validateConfirmPassword(value, text),
                                      onSubmitted: (_) {
                                        if (!_loading) {
                                          _register();
                                        }
                                      },
                                    ),

                                    const SizedBox(height: 18),

                                    _PrivacyAgreement(
                                      value: _acceptedPrivacy,
                                      text: text.privacyAgreement,
                                      onChanged: _loading
                                          ? null
                                          : (value) {
                                              setState(() {
                                                _acceptedPrivacy =
                                                    value ?? false;

                                                if (_acceptedPrivacy &&
                                                    _errorMessage ==
                                                        text.privacyRequired) {
                                                  _errorMessage = null;
                                                }
                                              });
                                            },
                                    ),

                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 16),
                                      _AuthErrorMessage(
                                        message: _errorMessage!,
                                      ),
                                    ],

                                    const SizedBox(height: 20),

                                    _CreateAccountButton(
                                      label: text.createButton,
                                      loadingLabel: text.creating,
                                      loading: _loading,
                                      onPressed: _loading ? null : _register,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            _SignInSection(
                              question: text.haveAccount,
                              buttonText: text.signIn,
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              text.safetyNote,
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

  String? _validateName(String? value, RegisterCopy text) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return text.nameRequired;
    }

    if (name.length < 2) {
      return text.nameTooShort;
    }

    if (!RegExp(r"^[a-zA-ZÀ-ÿ' -]+$").hasMatch(name)) {
      return text.invalidName;
    }

    return null;
  }

  String? _validateEmail(String? value, RegisterCopy text) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return text.emailRequired;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return text.invalidEmail;
    }

    return null;
  }

  String? _validatePassword(String? value, RegisterCopy text) {
    final password = value ?? '';

    if (password.isEmpty) {
      return text.passwordRequired;
    }

    if (password.length < 8) {
      return text.passwordTooShort;
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      return text.passwordNeedsLetterAndNumber;
    }

    return null;
  }

  String? _validateConfirmPassword(String? value, RegisterCopy text) {
    final confirmation = value ?? '';

    if (confirmation.isEmpty) {
      return text.confirmPasswordRequired;
    }

    if (confirmation != _passwordController.text) {
      return text.passwordsDoNotMatch;
    }

    return null;
  }
}

class _RegistrationHeader extends StatelessWidget {
  const _RegistrationHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.deepTeal, AppColors.ocean],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.ocean.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mediverse AI',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 25,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.deepTeal,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            height: 1.45,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({required this.child});

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

class _PasswordGuidance extends StatelessWidget {
  const _PasswordGuidance({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.muted,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivacyAgreement extends StatelessWidget {
  const _PrivacyAgreement({
    required this.value,
    required this.text,
    required this.onChanged,
  });

  final bool value;
  final String text;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.ocean,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  const _CreateAccountButton({
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
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInSection extends StatelessWidget {
  const _SignInSection({
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
        TextButton(
          onPressed: onPressed,
          child: Text(
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

class RegisterCopy {
  const RegisterCopy({
    required this.back,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.title,
    required this.subtitle,
    required this.fullName,
    required this.fullNameHint,
    required this.email,
    required this.emailHint,
    required this.password,
    required this.passwordHint,
    required this.confirmPassword,
    required this.confirmPasswordHint,
    required this.passwordGuidance,
    required this.showPassword,
    required this.hidePassword,
    required this.privacyAgreement,
    required this.safetyNote,
    required this.createButton,
    required this.creating,
    required this.haveAccount,
    required this.signIn,
    required this.nameRequired,
    required this.nameTooShort,
    required this.invalidName,
    required this.emailRequired,
    required this.invalidEmail,
    required this.passwordRequired,
    required this.passwordTooShort,
    required this.passwordNeedsLetterAndNumber,
    required this.confirmPasswordRequired,
    required this.passwordsDoNotMatch,
    required this.privacyRequired,
    required this.emailAlreadyUsed,
    required this.weakPassword,
    required this.networkError,
    required this.tooManyAttempts,
    required this.generalError,
  });

  final String back;
  final String headerTitle;
  final String headerSubtitle;
  final String title;
  final String subtitle;
  final String fullName;
  final String fullNameHint;
  final String email;
  final String emailHint;
  final String password;
  final String passwordHint;
  final String confirmPassword;
  final String confirmPasswordHint;
  final String passwordGuidance;
  final String showPassword;
  final String hidePassword;
  final String privacyAgreement;
  final String safetyNote;
  final String createButton;
  final String creating;
  final String haveAccount;
  final String signIn;
  final String nameRequired;
  final String nameTooShort;
  final String invalidName;
  final String emailRequired;
  final String invalidEmail;
  final String passwordRequired;
  final String passwordTooShort;
  final String passwordNeedsLetterAndNumber;
  final String confirmPasswordRequired;
  final String passwordsDoNotMatch;
  final String privacyRequired;
  final String emailAlreadyUsed;
  final String weakPassword;
  final String networkError;
  final String tooManyAttempts;
  final String generalError;

  static RegisterCopy forLanguage(AuthLanguage language) {
    return switch (language) {
      AuthLanguage.french => const RegisterCopy(
        back: 'Retour',
        headerTitle: 'Commencez votre parcours',
        headerSubtitle:
            'Créez un compte sécurisé pour accéder à vos outils de santé.',
        title: 'Créer votre compte',
        subtitle:
            'Quelques informations suffisent. Votre profil de santé pourra être complété après la création du compte.',
        fullName: 'Nom complet',
        fullNameHint: 'Saisissez votre nom complet',
        email: 'Adresse e-mail',
        emailHint: 'exemple@adresse.com',
        password: 'Mot de passe',
        passwordHint: 'Créez un mot de passe sécurisé',
        confirmPassword: 'Confirmer le mot de passe',
        confirmPasswordHint: 'Saisissez à nouveau le mot de passe',
        passwordGuidance:
            'Utilisez au moins 8 caractères avec une lettre et un chiffre.',
        showPassword: 'Afficher le mot de passe',
        hidePassword: 'Masquer le mot de passe',
        privacyAgreement:
            'J’accepte que mes informations de compte soient utilisées pour créer et sécuriser mon compte Mediverse AI.',
        safetyNote:
            'Mediverse AI fournit des informations éducatives et ne remplace pas les conseils d’un médecin ou d’un pharmacien.',
        createButton: 'Créer mon compte',
        creating: 'Création du compte...',
        haveAccount: 'Vous avez déjà un compte ?',
        signIn: 'Se connecter',
        nameRequired: 'Saisissez votre nom complet.',
        nameTooShort: 'Le nom doit contenir au moins 2 caractères.',
        invalidName:
            'Le nom ne doit contenir que des lettres, espaces, apostrophes ou traits d’union.',
        emailRequired: 'Saisissez votre adresse e-mail.',
        invalidEmail: 'Saisissez une adresse e-mail valide.',
        passwordRequired: 'Créez un mot de passe.',
        passwordTooShort:
            'Le mot de passe doit contenir au moins 8 caractères.',
        passwordNeedsLetterAndNumber:
            'Ajoutez au moins une lettre et un chiffre.',
        confirmPasswordRequired: 'Confirmez votre mot de passe.',
        passwordsDoNotMatch: 'Les mots de passe ne correspondent pas.',
        privacyRequired:
            'Veuillez accepter les conditions de confidentialité pour continuer.',
        emailAlreadyUsed: 'Un compte existe déjà avec cette adresse e-mail.',
        weakPassword:
            'Ce mot de passe est trop faible. Choisissez-en un plus sécurisé.',
        networkError:
            'Impossible de se connecter. Vérifiez votre connexion Internet.',
        tooManyAttempts:
            'Trop de tentatives. Patientez un moment avant de réessayer.',
        generalError: 'La création du compte a échoué. Veuillez réessayer.',
      ),

      AuthLanguage.english => const RegisterCopy(
        back: 'Back',
        headerTitle: 'Start your journey',
        headerSubtitle:
            'Create a secure account to access your personal health tools.',
        title: 'Create your account',
        subtitle:
            'We only need a few details. You can complete your health profile after creating your account.',
        fullName: 'Full name',
        fullNameHint: 'Enter your full name',
        email: 'Email address',
        emailHint: 'example@email.com',
        password: 'Password',
        passwordHint: 'Create a secure password',
        confirmPassword: 'Confirm password',
        confirmPasswordHint: 'Enter the password again',
        passwordGuidance:
            'Use at least 8 characters with one letter and one number.',
        showPassword: 'Show password',
        hidePassword: 'Hide password',
        privacyAgreement:
            'I agree that my account information may be used to create and secure my Mediverse AI account.',
        safetyNote:
            'Mediverse AI provides educational information and does not replace advice from a doctor or pharmacist.',
        createButton: 'Create my account',
        creating: 'Creating your account...',
        haveAccount: 'Already have an account?',
        signIn: 'Sign in',
        nameRequired: 'Enter your full name.',
        nameTooShort: 'Your name must contain at least 2 characters.',
        invalidName:
            'Your name should only contain letters, spaces, apostrophes, or hyphens.',
        emailRequired: 'Enter your email address.',
        invalidEmail: 'Enter a valid email address.',
        passwordRequired: 'Create a password.',
        passwordTooShort: 'Your password must contain at least 8 characters.',
        passwordNeedsLetterAndNumber:
            'Include at least one letter and one number.',
        confirmPasswordRequired: 'Confirm your password.',
        passwordsDoNotMatch: 'The passwords do not match.',
        privacyRequired: 'Accept the privacy acknowledgement to continue.',
        emailAlreadyUsed: 'An account already exists with this email address.',
        weakPassword: 'This password is too weak. Choose a stronger password.',
        networkError: 'We could not connect. Check your Internet connection.',
        tooManyAttempts:
            'There have been too many attempts. Try again shortly.',
        generalError: 'We could not create your account. Please try again.',
      ),
    };
  }
}
