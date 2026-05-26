import 'package:flutter/material.dart';

import '../../theme/jcf_palette.dart';

class NewsCategoryLabel extends StatelessWidget {
  const NewsCategoryLabel({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Text(
      category.toUpperCase(),
      style: const TextStyle(
        color: JcfPalette.danger,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}
