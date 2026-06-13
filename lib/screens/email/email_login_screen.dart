import 'package:flutter/material.dart';

import '../../services/email/jcf_mail_service.dart';
import '../../theme/nam_style.dart';
import 'email_inbox_screen.dart';

/// JCF email sign-in card.
///
/// Authenticates against the JCF mail host over IMAP. On success navigates to
/// [EmailInboxScreen] with the live [JcfMailService] session.
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;
  bool _signingIn = false;
  String? _signInError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateNonEmpty(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _signingIn = true;
      _signInError = null;
    });
    try {
      final session = await JcfMailService.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => EmailInboxScreen(session: session),
        ),
      );
    } on MailAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _signingIn = false;
        _signInError = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: NamStyle.pageInset,
                vertical: 32,
              ),
              child: _SignInCard(
                formKey: _formKey,
                emailController: _email,
                passwordController: _password,
                obscurePassword: _obscurePassword,
                signingIn: _signingIn,
                signInError: _signInError,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSignIn: _signIn,
                validateNonEmpty: _validateNonEmpty,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.signingIn,
    required this.signInError,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.validateNonEmpty,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool signingIn;
  final String? signInError;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignIn;
  final String? Function(String?) validateNonEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: NamStyle.surface,
        borderRadius: BorderRadius.circular(NamStyle.cardRadius),
        border: Border.all(color: NamStyle.hairline),
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LogoHeader(),
            const SizedBox(height: 28),
            _EmailField(
              controller: emailController,
              validator: validateNonEmpty,
            ),
            const SizedBox(height: 16),
            _PasswordField(
              controller: passwordController,
              obscure: obscurePassword,
              onToggleObscure: onToggleObscure,
              validator: validateNonEmpty,
            ),
            if (signInError != null) ...[
              const SizedBox(height: 18),
              _ErrorBanner(message: signInError!),
            ],
            const SizedBox(height: 24),
            _SignInButton(signingIn: signingIn, onSignIn: onSignIn),
            const SizedBox(height: 20),
            _LdapNote(),
          ],
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: NamStyle.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: NamStyle.gold.withValues(alpha: 0.4),
            ),
          ),
          child: const Icon(
            Icons.mail_outline_rounded,
            size: 28,
            color: NamStyle.gold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'JCF Mail',
          style: NamStyle.title(size: 22, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to your JCF email account',
          style: NamStyle.body(size: 13, color: NamStyle.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller, required this.validator});

  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      style: NamStyle.body(color: NamStyle.textPrimary),
      decoration: _inputDecoration(
        hintText: 'firstname.lastname@jcf.gov.jm',
        labelText: 'JCF Email',
        prefixIcon: Icons.person_outline,
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.validator,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscure,
      style: NamStyle.body(color: NamStyle.textPrimary),
      decoration: _inputDecoration(
        hintText: 'Network password',
        labelText: 'Password',
        prefixIcon: Icons.lock_outline,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: NamStyle.textSecondary,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.signingIn, required this.onSignIn});

  final bool signingIn;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: signingIn ? null : onSignIn,
      style: FilledButton.styleFrom(
        backgroundColor: NamStyle.gold,
        foregroundColor: NamStyle.onGold,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: NamStyle.title(size: 15, weight: FontWeight.w600),
      ),
      child: signingIn
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: NamStyle.onGold,
              ),
            )
          : const Text('Sign in'),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: NamStyle.alert.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NamStyle.alert.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: NamStyle.alert),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: NamStyle.body(size: 12, color: NamStyle.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LdapNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Sign in with your JCF mailbox address and password. '
      'Your credentials go straight to the JCF mail server and are never stored.',
      style: NamStyle.body(size: 11, color: NamStyle.textSecondary),
      textAlign: TextAlign.center,
    );
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  required String labelText,
  required IconData prefixIcon,
}) =>
    InputDecoration(
      hintText: hintText,
      labelText: labelText,
      labelStyle: NamStyle.body(size: 13, color: NamStyle.textSecondary),
      hintStyle: NamStyle.body(size: 13, color: NamStyle.textSecondary),
      prefixIcon: Icon(prefixIcon, size: 20, color: NamStyle.textSecondary),
      filled: true,
      fillColor: NamStyle.background,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NamStyle.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NamStyle.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NamStyle.gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NamStyle.alert),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: NamStyle.alert, width: 1.5),
      ),
    );
