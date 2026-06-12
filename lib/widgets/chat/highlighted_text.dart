import 'package:flutter/material.dart';

import '../../screens/chat/chat_style.dart';

/// A drop-in replacement for [Text] that case-insensitively highlights every
/// occurrence of [query] inside [text] with a yellow background span.
///
/// Renders as a plain [Text] when [query] is empty or not present in [text].
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;

  /// The active search query. Empty string disables highlighting.
  final String query;

  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  static const Color _highlightBackground = Color(0xFFFFE07A);

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        style ?? ChatStyle.body(size: 14, color: ChatStyle.textPrimary);
    final needle = query.toLowerCase();
    if (needle.isEmpty || !text.toLowerCase().contains(needle)) {
      return Text(text, style: baseStyle, maxLines: maxLines, overflow: overflow);
    }
    return RichText(
      text: TextSpan(children: _buildSpans(baseStyle, needle)),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  List<TextSpan> _buildSpans(TextStyle base, String needle) {
    final lowerText = text.toLowerCase();
    final highlighted =
        base.copyWith(backgroundColor: _highlightBackground, color: ChatStyle.textPrimary);
    final spans = <TextSpan>[];
    var cursor = 0;

    while (cursor < text.length) {
      final matchStart = lowerText.indexOf(needle, cursor);
      if (matchStart == -1) break;
      if (matchStart > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, matchStart), style: base));
      }
      final matchEnd = matchStart + needle.length;
      spans.add(TextSpan(text: text.substring(matchStart, matchEnd), style: highlighted));
      cursor = matchEnd;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return spans;
  }
}
