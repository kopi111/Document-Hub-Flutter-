import 'package:flutter/material.dart';

class NewsCategoryLabel extends StatelessWidget {
  const NewsCategoryLabel({super.key, required this.category});

  final String category;

  static const Color _labelColor = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    return Text(
      category.toUpperCase(),
      style: const TextStyle(
        color: _labelColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}
