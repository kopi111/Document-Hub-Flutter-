import 'package:flutter/material.dart';

import '../services/first_launch_preferences.dart';
import 'eula_screen.dart';
import 'home_screen.dart';
import 'privacy_notice_screen.dart';

class FirstLaunchGate extends StatefulWidget {
  const FirstLaunchGate({super.key});

  @override
  State<FirstLaunchGate> createState() => _FirstLaunchGateState();
}

enum _FirstLaunchStep { loading, privacyNotice, eula, ready }

class _FirstLaunchGateState extends State<FirstLaunchGate> {
  final FirstLaunchPreferences _preferences = FirstLaunchPreferences();
  _FirstLaunchStep _step = _FirstLaunchStep.loading;

  @override
  void initState() {
    super.initState();
    _resolveNextStep();
  }

  Future<void> _resolveNextStep() async {
    final privacyNoticeAcknowledged = await _preferences.hasAcknowledgedPrivacyNotice();
    if (!privacyNoticeAcknowledged) {
      _setStep(_FirstLaunchStep.privacyNotice);
      return;
    }
    final eulaAccepted = await _preferences.hasAcceptedEula();
    _setStep(eulaAccepted ? _FirstLaunchStep.ready : _FirstLaunchStep.eula);
  }

  void _setStep(_FirstLaunchStep step) {
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
      case _FirstLaunchStep.loading:
        return const _LoadingScreen();
      case _FirstLaunchStep.privacyNotice:
        return PrivacyNoticeScreen(onAcknowledged: _handlePrivacyAcknowledged);
      case _FirstLaunchStep.eula:
        return EulaScreen(onAccepted: _handleEulaAccepted);
      case _FirstLaunchStep.ready:
        return const HomeScreen();
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
