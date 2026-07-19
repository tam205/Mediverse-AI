import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'services/auth_service.dart';
import 'widgets/auth_language_selector.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.initialLanguage = AuthLanguage.english,
  });

  final String email;
  final AuthLanguage initialLanguage;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late AuthLanguage _language;
  bool _checking = false;
  bool _resending = false;
  String? _message;
  bool _isError = false;

  EmailVerificationCopy get copy =>
      EmailVerificationCopy.forLanguage(_language);

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
  }

  Future<void> _resendVerification() async {
    setState(() {
      _resending = true;
      _message = null;
      _isError = false;
    });

    final result = await AuthService.sendEmailVerification();

    if (!mounted) return;

    setState(() {
      _resending = false;
      _message = _messageFor(result.message, copy);
      _isError = !result.ok;
    });
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _message = null;
      _isError = false;
    });

    final verified = await AuthService.isCurrentUserEmailVerified();

    if (!mounted) return;

    setState(() {
      _checking = false;
      _message = verified ? copy.verifiedMessage : copy.notVerifiedMessage;
      _isError = !verified;
    });
  }

  Future<void> _changeAccount() async {
    await AuthService.signOut();
  }

  String _messageFor(String code, EmailVerificationCopy text) {
    return switch (code) {
      'already-verified' => text.verifiedMessage,
      'verification-sent' => text.sentMessage,
      'too-many-requests' => text.tooManyRequests,
      'network-request-failed' => text.networkError,
      'no-user' => text.noUser,
      _ => text.generalError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = copy;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
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
                          _message = null;
                          _isError = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        color: AppColors.ocean,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    text.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.email.isEmpty ? text.yourEmail : widget.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _GuidanceCard(text: text.guidance),
                  if (_message != null) ...[
                    const SizedBox(height: 18),
                    _StatusMessage(message: _message!, isError: _isError),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _checking ? null : _checkVerification,
                    child: Text(_checking ? text.checking : text.checkButton),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _resending ? null : _resendVerification,
                    child: Text(_resending ? text.resending : text.resend),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _changeAccount,
                    child: Text(text.changeAccount),
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

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.ocean,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.45,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.coral : AppColors.ocean;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? AppColors.coral : AppColors.deepTeal,
          height: 1.4,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class EmailVerificationCopy {
  const EmailVerificationCopy({
    required this.title,
    required this.subtitle,
    required this.yourEmail,
    required this.guidance,
    required this.checkButton,
    required this.checking,
    required this.resend,
    required this.resending,
    required this.changeAccount,
    required this.sentMessage,
    required this.verifiedMessage,
    required this.notVerifiedMessage,
    required this.tooManyRequests,
    required this.networkError,
    required this.noUser,
    required this.generalError,
  });

  final String title;
  final String subtitle;
  final String yourEmail;
  final String guidance;
  final String checkButton;
  final String checking;
  final String resend;
  final String resending;
  final String changeAccount;
  final String sentMessage;
  final String verifiedMessage;
  final String notVerifiedMessage;
  final String tooManyRequests;
  final String networkError;
  final String noUser;
  final String generalError;

  static EmailVerificationCopy forLanguage(AuthLanguage language) {
    return switch (language) {
      AuthLanguage.french => const EmailVerificationCopy(
        title: 'Vérifiez votre e-mail',
        subtitle: 'Nous avons envoyé un lien de vérification à cette adresse.',
        yourEmail: 'Votre adresse e-mail',
        guidance:
            'Ouvrez le lien dans votre boîte de réception, puis revenez ici. Vérifiez aussi le dossier spam ou courrier indésirable.',
        checkButton: 'J’ai vérifié mon e-mail',
        checking: 'Vérification...',
        resend: 'Renvoyer l’e-mail',
        resending: 'Envoi...',
        changeAccount: 'Changer de compte',
        sentMessage: 'Un nouvel e-mail de vérification a été envoyé.',
        verifiedMessage: 'Votre e-mail est vérifié. Ouverture de Mediverse AI.',
        notVerifiedMessage: 'Votre e-mail n’est pas encore vérifié.',
        tooManyRequests:
            'Trop de demandes. Patientez un moment avant de réessayer.',
        networkError:
            'Impossible de se connecter. Vérifiez votre connexion Internet.',
        noUser: 'Aucun compte connecté.',
        generalError: 'Impossible d’envoyer l’e-mail de vérification.',
      ),
      AuthLanguage.english => const EmailVerificationCopy(
        title: 'Check your inbox',
        subtitle: 'We sent a verification link to this email address.',
        yourEmail: 'Your email address',
        guidance:
            'Open the verification link in your inbox, then return here. If you do not see it, check spam or junk mail.',
        checkButton: 'I have verified my email',
        checking: 'Checking...',
        resend: 'Resend verification email',
        resending: 'Sending...',
        changeAccount: 'Change account',
        sentMessage: 'A new verification email has been sent.',
        verifiedMessage: 'Your email is verified. Opening Mediverse AI.',
        notVerifiedMessage: 'Your email is not verified yet.',
        tooManyRequests: 'Too many requests. Please try again shortly.',
        networkError: 'We could not connect. Check your Internet connection.',
        noUser: 'No signed-in account was found.',
        generalError: 'We could not send the verification email.',
      ),
    };
  }
}
