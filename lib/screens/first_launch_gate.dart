import 'package:flutter/material.dart';

import '../services/auth/http_auth_service.dart';
import '../services/auth/session.dart';
import '../services/first_launch_preferences.dart';
import 'auth/ldap_login_screen.dart';
import 'dashboard/services_home_screen.dart';
import 'eula_screen.dart';
import 'privacy_notice_screen.dart';

/// App entry. A persisted session is restored first so a returning officer
/// skips sign-in; otherwise sign-in (AD/LDAP) comes first. The one-time privacy
/// notice and EULA follow on first access only, then the home screen.
class FirstLaunchGate extends StatefulWidget {
  const FirstLaunchGate({super.key});

  @override
  State<FirstLaunchGate> createState() => _FirstLaunchGateState();
}

enum _EntryState { restoring, login, ready }

class _FirstLaunchGateState extends State<FirstLaunchGate> {
  late final HttpAuthService _authService =
      HttpAuthService(session: Session.shared);
  _EntryState _state = _EntryState.restoring;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await Session.shared.restore();
    if (!mounted) return;
    setState(() => _state = session != null ? _EntryState.ready : _EntryState.login);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _EntryState.restoring:
        return const _LoadingScreen();
      case _EntryState.login:
        return LdapLoginScreen(
          authService: _authService,
          onSignedIn: (_) => const _OnboardingGate(),
        );
      case _EntryState.ready:
        return const _OnboardingGate();
    }
  }
}

/// Post-login onboarding: shows the privacy notice and EULA once (tracked in
/// [FirstLaunchPreferences]); on later sign-ins it goes straight to home.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

enum _OnboardingStep { loading, privacyNotice, eula, ready }

class _OnboardingGateState extends State<_OnboardingGate> {
  final FirstLaunchPreferences _preferences = FirstLaunchPreferences();
  _OnboardingStep _step = _OnboardingStep.loading;

  @override
  void initState() {
    super.initState();
    _resolveNextStep();
  }

  Future<void> _resolveNextStep() async {
    final privacyNoticeAcknowledged =
        await _preferences.hasAcknowledgedPrivacyNotice();
    if (!privacyNoticeAcknowledged) {
      _setStep(_OnboardingStep.privacyNotice);
      return;
    }
    final eulaAccepted = await _preferences.hasAcceptedEula();
    _setStep(eulaAccepted ? _OnboardingStep.ready : _OnboardingStep.eula);
  }

  void _setStep(_OnboardingStep step) {
    if (!mounted) return;
    setState(() => _step = step);
  }

  Future<void> _handlePrivacyAcknowledged() async {
    await _preferences.recordPrivacyNoticeAcknowledged();
    await _resolveNextStep();
  }

  Future<void> _handleEulaAccepted() async {
    await _preferences.recordEulaAccepted();
    await _resolveNextStep();
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _OnboardingStep.loading:
        return const _LoadingScreen();
      case _OnboardingStep.privacyNotice:
        return PrivacyNoticeScreen(onAcknowledged: _handlePrivacyAcknowledged);
      case _OnboardingStep.eula:
        return EulaScreen(onAccepted: _handleEulaAccepted);
      case _OnboardingStep.ready:
        return const ServicesHomeScreen();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
