import 'package:flutter/material.dart';

enum NewsPriority { normal, high, urgent }

extension NewsPriorityWire on NewsPriority {
  static NewsPriority fromWire(String? value) {
    switch (value?.toLowerCase()) {
      case 'urgent':
        return NewsPriority.urgent;
      case 'high':
        return NewsPriority.high;
      case 'normal':
      case null:
      case '':
        return NewsPriority.normal;
      default:
        return NewsPriority.normal;
    }
  }

  String get wireValue {
    switch (this) {
      case NewsPriority.normal:
        return 'normal';
      case NewsPriority.high:
        return 'high';
      case NewsPriority.urgent:
        return 'urgent';
    }
  }
}

extension NewsPriorityPresentation on NewsPriority {
  String get label {
    switch (this) {
      case NewsPriority.normal:
        return 'Normal';
      case NewsPriority.high:
        return 'High';
      case NewsPriority.urgent:
        return 'Urgent';
    }
  }

  bool get isFlagged => this != NewsPriority.normal;

  Color backgroundColor(ColorScheme scheme) {
    switch (this) {
      case NewsPriority.normal:
        return scheme.surfaceContainerHighest;
      case NewsPriority.high:
        return const Color(0xFFFFE0B2);
      case NewsPriority.urgent:
        return const Color(0xFFFFCDD2);
    }
  }

  Color foregroundColor(ColorScheme scheme) {
    switch (this) {
      case NewsPriority.normal:
        return scheme.onSurfaceVariant;
      case NewsPriority.high:
        return const Color(0xFF8B5A00);
      case NewsPriority.urgent:
        return const Color(0xFFB71C1C);
    }
  }
}
