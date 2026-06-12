// INTEGRATION: Replace EmailLoginScreen with LdapLoginScreen as the app and chat
// entry gate. Construct with HttpAuthService backed by the shared Session instance;
// set onSignedIn to return ServicesHomeScreen() (or ChatListScreen for the chat gate).

import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../theme/nam_style.dart';

class LdapLoginScreen extends StatefulWidget {
  const LdapLoginScreen({
    super.key,
    required this.authService,
    required this.onSignedIn,
  });

  final AuthService authService;

  /// Builds the destination screen after a successful sign-in.
  /// The screen calls [Navigator.pushReplacement] with the returned widget.
  final Widget Function(AuthSession session) onSignedIn;

  @override
  State<LdapLoginScreen> createState() => _LdapLoginScreenState();
}

class _LdapLoginScreenState extends State<LdapLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;
  bool _signingIn = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _requireNonEmpty(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      final session = await widget.authService.signIn(
        _username.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => widget.onSignedIn(session),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _signingIn = false);
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
                usernameController: _username,
                passwordController: _password,
                obscurePassword: _obscurePassword,
                signingIn: _signingIn,
                error: _error,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSignIn: _signIn,
                validateNonEmpty: _requireNonEmpty,
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
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.signingIn,
    required this.error,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.validateNonEmpty,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool signingIn;
  final String? error;
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
            const _LogoHeader(),
            const SizedBox(height: 28),
            _UsernameField(
              controller: usernameController,
              validator: validateNonEmpty,
            ),
            const SizedBox(height: 16),
            _PasswordField(
              controller: passwordController,
              obscure: obscurePassword,
              onToggleObscure: onToggleObscure,
              validator: validateNonEmpty,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: error!),
            ],
            const SizedBox(height: 24),
            _SignInButton(signingIn: signingIn, onSignIn: onSignIn),
            const SizedBox(height: 20),
            const _NetworkNote(),
          ],
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader();

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
            Icons.shield_outlined,
            size: 28,
            color: NamStyle.gold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'JCF Sign In',
          style: NamStyle.title(size: 22, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Use your JCF network credentials',
          style: NamStyle.body(size: 13, color: NamStyle.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _UsernameField extends StatelessWidget {
  const _UsernameField({required this.controller, required this.validator});

  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.text,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      style: NamStyle.body(color: NamStyle.textPrimary),
      decoration: _inputDecoration(
        hintText: 'firstname.lastname',
        labelText: 'Username',
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
      textInputAction: TextInputAction.done,
      style: NamStyle.body(color: NamStyle.textPrimary),
      decoration: _inputDecoration(
        hintText: 'Network password',
        labelText: 'Password',
        prefixIcon: Icons.lock_outline,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: NamStyle.textSecondary,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: NamStyle.alert.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NamStyle.alert.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: NamStyle.alert),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: NamStyle.body(size: 13, color: NamStyle.alert),
            ),
          ),
        ],
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

class _NetworkNote extends StatelessWidget {
  const _NetworkNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Access is restricted to authorised JCF personnel on the JCF network.',
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
