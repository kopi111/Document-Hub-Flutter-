// INTEGRATION: In ChatThreadScreenState, add `bool _isSearching = false` and
// `String _activeQuery = ''`; add a search-icon action to the AppBar that sets
// `_isSearching = true`; replace `appBar: _buildAppBar()` with
// `appBar: _isSearching ? InChatSearchBar(controller: _threadController,
//   onJumpTo: (i) => _scrollToIndex(i), onClose: () => setState(() { _isSearching = false; }),
//   onQueryChanged: (q) => setState(() => _activeQuery = q)) : _buildAppBar()`.
// In each bubble replace `Text(msg.text)` with
// `HighlightedText(text: msg.text, query: _activeQuery)`.

import 'package:flutter/material.dart';

import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

/// Telegram-style in-thread search bar that replaces the normal app bar.
///
/// Calls [ChatThreadController.search] on every keystroke, shows 'n of m'
/// match count, and emits [onJumpTo] with a message-list index so the thread
/// can scroll to and flash the matched bubble. Implements [PreferredSizeWidget]
/// so it slots directly into [Scaffold.appBar].
class InChatSearchBar extends StatefulWidget implements PreferredSizeWidget {
  const InChatSearchBar({
    super.key,
    required this.controller,
    required this.onJumpTo,
    required this.onClose,
    this.onQueryChanged,
  });

  /// The owning thread's controller; [ChatThreadController.search] drives hits.
  final ChatThreadController controller;

  /// Called with the message-list index of the currently focused hit so the
  /// parent can scroll to and flash that bubble.
  final ValueChanged<int> onJumpTo;

  /// Called when the user dismisses the search bar.
  final VoidCallback onClose;

  /// Called on every keystroke with the live query string so the parent can
  /// forward it to [HighlightedText] widgets inside the message list.
  final ValueChanged<String>? onQueryChanged;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<InChatSearchBar> createState() => _InChatSearchBarState();
}

class _InChatSearchBarState extends State<InChatSearchBar> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();

  String _query = '';
  List<int> _hits = const [];
  int _cursor = 0;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _input.removeListener(_onTextChanged);
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _input.text;
    final hits = widget.controller.search(query);
    widget.onQueryChanged?.call(query);
    setState(() {
      _query = query;
      _hits = hits;
      _cursor = 0;
    });
    if (hits.isNotEmpty) widget.onJumpTo(hits[0]);
  }

  void _stepPrevious() {
    if (_hits.isEmpty) return;
    final next = (_cursor - 1 + _hits.length) % _hits.length;
    setState(() => _cursor = next);
    widget.onJumpTo(_hits[next]);
  }

  void _stepNext() {
    if (_hits.isEmpty) return;
    final next = (_cursor + 1) % _hits.length;
    setState(() => _cursor = next);
    widget.onJumpTo(_hits[next]);
  }

  void _close() {
    widget.onQueryChanged?.call('');
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ChatStyle.gold,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: Colors.white,
        onPressed: _close,
        tooltip: 'Close search',
      ),
      titleSpacing: 0,
      title: TextField(
        controller: _input,
        focusNode: _focus,
        style: ChatStyle.body(size: 16, color: Colors.white),
        cursorColor: Colors.white,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search messages…',
          hintStyle: ChatStyle.body(
            size: 16,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      actions: [
        _MatchCounter(query: _query, hits: _hits, cursor: _cursor),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          color: Colors.white,
          disabledColor: Colors.white.withValues(alpha: 0.35),
          onPressed: _hits.isNotEmpty ? _stepPrevious : null,
          tooltip: 'Previous result',
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          color: Colors.white,
          disabledColor: Colors.white.withValues(alpha: 0.35),
          onPressed: _hits.isNotEmpty ? _stepNext : null,
          tooltip: 'Next result',
        ),
      ],
    );
  }
}

class _MatchCounter extends StatelessWidget {
  const _MatchCounter({
    required this.query,
    required this.hits,
    required this.cursor,
  });

  final String query;
  final List<int> hits;
  final int cursor;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return const SizedBox.shrink();
    final label =
        hits.isEmpty ? 'No results' : '${cursor + 1} of ${hits.length}';
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(
          label,
          style: ChatStyle.body(
            size: 13,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
