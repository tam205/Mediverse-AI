import 'package:flutter/material.dart';
import 'package:mediverse_ai/features/auth/widgets/auth_language_selector.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/form_fields.dart';
import 'services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.initialLanguage = AuthLanguage.english,
  });

  final AuthLanguage initialLanguage;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late AuthLanguage _language;

  bool _loading = false;
  bool _emailSent = false;
  String? _errorMessage;

  ForgotPasswordCopy get copy => ForgotPasswordCopy.forLanguage(_language);

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthService.sendPasswordReset(
      email: _emailController.text.trim(),
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

    setState(() {
      _emailSent = true;
    });
  }

  String _humanizeError(String code) {
    return switch (code) {
      'invalid-email' => copy.invalidEmail,
      'network-request-failed' => copy.networkError,
      'too-many-requests' => copy.tooManyRequests,
      'operation-not-allowed' => copy.operationNotAllowed,
      _ => copy.generalError,
    };
  }

  void _changeEmail() {
    setState(() {
      _emailSent = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = copy;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
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
                  const SizedBox(height: 28),
                  if (_emailSent)
                    _EmailSentView(
                      copy: text,
                      email: _emailController.text.trim(),
                      loading: _loading,
                      onResend: _sendReset,
                      onChangeEmail: _changeEmail,
                      onReturnToLogin: () {
                        Navigator.of(context).pop();
                      },
                    )
                  else
                    _ResetFormView(
                      formKey: _formKey,
                      copy: text,
                      emailController: _emailController,
                      loading: _loading,
                      errorMessage: _errorMessage,
                      onSubmit: _sendReset,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetFormView extends StatelessWidget {
  const _ResetFormView({
    required this.formKey,
    required this.copy,
    required this.emailController,
    required this.loading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final ForgotPasswordCopy copy;
  final TextEditingController emailController;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderIcon(icon: Icons.lock_reset_rounded),
        const SizedBox(height: 18),
        Text(
          copy.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          copy.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 28),
        _Card(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldLabel(copy.email),
                const SizedBox(height: 7),
                MediverseTextField(
                  hint: copy.emailHint,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.mail_outline_rounded,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return copy.emailRequired;
                    }

                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return copy.invalidEmail;
                    }

                    return null;
                  },
                  onSubmitted: (_) {
                    if (!loading) {
                      onSubmit();
                    }
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorMessage(message: errorMessage!),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: loading ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ocean,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: loading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(copy.sending),
                            ],
                          )
                        : Text(
                            copy.sendButton,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                _SecurityMessage(
                  title: copy.securityTitle,
                  message: copy.securityMessage,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          copy.helpMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _EmailSentView extends StatelessWidget {
  const _EmailSentView({
    required this.copy,
    required this.email,
    required this.loading,
    required this.onResend,
    required this.onChangeEmail,
    required this.onReturnToLogin,
  });

  final ForgotPasswordCopy copy;
  final String email;
  final bool loading;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;
  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderIcon(icon: Icons.mark_email_read_outlined),
        const SizedBox(height: 18),
        Text(
          copy.emailSentTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          copy.emailSentSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            email,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 26),
        _Card(
          child: Column(
            children: [
              _Step(number: '1', text: copy.stepOne),
              const SizedBox(height: 16),
              _Step(number: '2', text: copy.stepTwo),
              const SizedBox(height: 16),
              _Step(number: '3', text: copy.stepThree),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onReturnToLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ocean,
                  ),
                  child: Text(copy.returnToLogin),
                ),
              ),
              TextButton(
                onPressed: loading ? null : onResend,
                child: Text(loading ? copy.sending : copy.resend),
              ),
              TextButton(
                onPressed: loading ? null : onChangeEmail,
                child: Text(copy.changeEmail),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          copy.checkSpam,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepTeal, AppColors.ocean],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: Colors.white, size: 38),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SecurityMessage extends StatelessWidget {
  const _SecurityMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, color: AppColors.ocean),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.surfaceTint,
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.ocean,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }
}

class ForgotPasswordCopy {
  const ForgotPasswordCopy({
    required this.back,
    required this.title,
    required this.subtitle,
    required this.email,
    required this.emailHint,
    required this.sendButton,
    required this.sending,
    required this.securityTitle,
    required this.securityMessage,
    required this.helpMessage,
    required this.emailSentTitle,
    required this.emailSentSubtitle,
    required this.stepOne,
    required this.stepTwo,
    required this.stepThree,
    required this.returnToLogin,
    required this.resend,
    required this.changeEmail,
    required this.checkSpam,
    required this.emailRequired,
    required this.invalidEmail,
    required this.networkError,
    required this.tooManyRequests,
    required this.operationNotAllowed,
    required this.generalError,
  });

  final String back;
  final String title;
  final String subtitle;
  final String email;
  final String emailHint;
  final String sendButton;
  final String sending;
  final String securityTitle;
  final String securityMessage;
  final String helpMessage;
  final String emailSentTitle;
  final String emailSentSubtitle;
  final String stepOne;
  final String stepTwo;
  final String stepThree;
  final String returnToLogin;
  final String resend;
  final String changeEmail;
  final String checkSpam;
  final String emailRequired;
  final String invalidEmail;
  final String networkError;
  final String tooManyRequests;
  final String operationNotAllowed;
  final String generalError;

  static ForgotPasswordCopy forLanguage(AuthLanguage language) {
    return switch (language) {
      AuthLanguage.french => const ForgotPasswordCopy(
        back: 'Retour',
        title: 'Mot de passe oublié ?',
        subtitle:
            'Saisissez votre adresse e-mail. Nous vous enverrons un lien sécurisé pour créer un nouveau mot de passe.',
        email: 'Adresse e-mail',
        emailHint: 'exemple@adresse.com',
        sendButton: 'Envoyer le lien de réinitialisation',
        sending: 'Envoi en cours...',
        securityTitle: 'Réinitialisation sécurisée',
        securityMessage:
            'Le lien temporaire sera envoyé uniquement à l’adresse e-mail associée à votre compte.',
        helpMessage:
            'Pour votre sécurité, nous ne vous demanderons jamais votre ancien mot de passe.',
        emailSentTitle: 'Vérifiez votre e-mail',
        emailSentSubtitle:
            'Si un compte correspond à cette adresse, vous recevrez un lien de réinitialisation.',
        stepOne: 'Ouvrez le message envoyé par Mediverse AI.',
        stepTwo: 'Appuyez sur le lien de réinitialisation.',
        stepThree:
            'Créez votre nouveau mot de passe, puis revenez vous connecter.',
        returnToLogin: 'Retour à la connexion',
        resend: 'Renvoyer le lien',
        changeEmail: 'Utiliser une autre adresse',
        checkSpam:
            'Vous ne trouvez pas le message ? Vérifiez le dossier spam ou courrier indésirable.',
        emailRequired: 'Saisissez votre adresse e-mail.',
        invalidEmail: 'Saisissez une adresse e-mail valide.',
        networkError:
            'Impossible de se connecter. Vérifiez votre connexion Internet.',
        tooManyRequests:
            'Trop de demandes ont été effectuées. Patientez avant de réessayer.',
        operationNotAllowed:
            'La réinitialisation du mot de passe n’est pas activée.',
        generalError:
            'Impossible d’envoyer le lien pour le moment. Veuillez réessayer.',
      ),

      AuthLanguage.english => const ForgotPasswordCopy(
        back: 'Back',
        title: 'Forgot your password?',
        subtitle:
            'Enter your email address and we will send you a secure link to create a new password.',
        email: 'Email address',
        emailHint: 'example@email.com',
        sendButton: 'Send reset link',
        sending: 'Sending...',
        securityTitle: 'Secure password reset',
        securityMessage:
            'The temporary link will only be sent to the email address connected to your account.',
        helpMessage:
            'For your safety, we will never ask for your old password.',
        emailSentTitle: 'Check your email',
        emailSentSubtitle:
            'If an account matches this address, you will receive a password-reset link.',
        stepOne: 'Open the email sent by Mediverse AI.',
        stepTwo: 'Tap the password-reset link.',
        stepThree:
            'Create your new password, then return to the app and sign in.',
        returnToLogin: 'Return to sign in',
        resend: 'Resend the link',
        changeEmail: 'Use a different email address',
        checkSpam: 'Cannot find the email? Check your spam or junk folder.',
        emailRequired: 'Enter your email address.',
        invalidEmail: 'Enter a valid email address.',
        networkError: 'We could not connect. Check your Internet connection.',
        tooManyRequests:
            'Too many requests were made. Wait before trying again.',
        operationNotAllowed: 'Password reset is not currently enabled.',
        generalError: 'We could not send the reset link. Please try again.',
      ),
    };
  }
}
