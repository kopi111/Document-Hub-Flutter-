import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../theme/hub_style.dart';

/// JCF network (AD/LDAP) sign-in — the app's front page.
///
/// Authenticates against the backend `/v1/auth/login` endpoint (which binds to
/// Active Directory) via the injected [AuthService]. Styled to match the Hub
/// design system: navy→indigo gradient hero, soft white card, blue primary.
class LdapLoginScreen extends StatefulWidget {
  const LdapLoginScreen({
    super.key,
    required this.authService,
    required this.onSignedIn,
  });

  final AuthService authService;

  /// Builds the destination screen after a successful sign-in.
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
        MaterialPageRoute<void>(builder: (_) => widget.onSignedIn(session)),
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
    return Scaffold(
      backgroundColor: HubStyle.pageBackground,
      body: Column(
        children: [
          const _Hero(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Transform.translate(
                    offset: const Offset(0, -28),
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(
                color: HubStyle.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use your JCF network credentials',
              style: TextStyle(color: HubStyle.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Username'),
            const SizedBox(height: 7),
            _Field(
              controller: _username,
              validator: _requireNonEmpty,
              hint: 'firstname.lastname@jcf.gov.jm',
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Password'),
            const SizedBox(height: 7),
            _Field(
              controller: _password,
              validator: _requireNonEmpty,
              hint: 'Network password',
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signIn(),
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: HubStyle.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 22),
            _SignInButton(signingIn: _signingIn, onPressed: _signIn),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    size: 13, color: HubStyle.textSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Authorised JCF personnel on the JCF network only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: HubStyle.textSecondary, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient hero band with the force crest and branding.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: HubStyle.headerGradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: topInset + 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 16),
              const Text(
                'JCF Document Hub',
                style: TextStyle(
                  color: HubStyle.onGradient,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Secure access for serving officers',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 46),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HubStyle.accentBar(),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: HubStyle.textPrimary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.validator,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? Function(String?) validator;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6CDF);
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: HubStyle.textPrimary, fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: HubStyle.textSecondary.withValues(alpha: 0.8),
          fontSize: 13.5,
        ),
        prefixIcon: Icon(icon, size: 20, color: HubStyle.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: border(const Color(0xFFE2E8F0), 1),
        enabledBorder: border(const Color(0xFFE2E8F0), 1),
        focusedBorder: border(accent, 1.6),
        errorBorder: border(const Color(0xFFE0414C), 1),
        focusedErrorBorder: border(const Color(0xFFE0414C), 1.6),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFE0414C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 17, color: danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.signingIn, required this.onPressed});

  final bool signingIn;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          gradient: HubStyle.headerGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: signingIn ? null : onPressed,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: signingIn
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Sign in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
