import 'package:flutter/material.dart';

import 'screens/first_launch_gate.dart';
import 'services/connectivity_service.dart';
import 'theme/duty_theme.dart';
import 'widgets/idle_timeout_gate.dart';
import 'widgets/offline_banner.dart';

void main() {
  runApp(const JcfDutyApp());
}

class JcfDutyApp extends StatelessWidget {
  const JcfDutyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ConnectivityService connectivity = ConnectivityPlusService();

    return MaterialApp(
      title: 'JCF Duty',
      debugShowCheckedModeBanner: false,
      theme: DutyTheme.light(),
      darkTheme: DutyTheme.light(),
      themeMode: ThemeMode.light,
      builder: (context, child) => OfflineBanner(
        connectivity: connectivity,
        child: IdleTimeoutGate(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const FirstLaunchGate(),
    );
  }
}
