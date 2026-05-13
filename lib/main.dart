import 'package:flutter/material.dart';

import 'screens/first_launch_gate.dart';
import 'services/connectivity_service.dart';
import 'widgets/idle_timeout_gate.dart';
import 'widgets/offline_banner.dart';

void main() {
  runApp(const DocumentHubApp());
}

class DocumentHubApp extends StatelessWidget {
  const DocumentHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ConnectivityService connectivity = ConnectivityPlusService();

    return MaterialApp(
      title: 'JCF Document Hub',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) => OfflineBanner(
        connectivity: connectivity,
        child: IdleTimeoutGate(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const FirstLaunchGate(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B5E20),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
    );
  }
}
