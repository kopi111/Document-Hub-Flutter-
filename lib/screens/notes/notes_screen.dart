import 'package:flutter/material.dart';

import '../../models/notes/note.dart';
import '../../services/notes/notes_repository.dart';
import '../../theme/hub_style.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import '../../widgets/hub/hub_category_card.dart';
import '../../widgets/hub/hub_filter_pill.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/hub/hub_stat_banner.dart';
import '../../widgets/notifications_bell.dart';

/// A notebook grouping derived from keywords in a note's title and body. The
/// Note model carries no explicit notebook field, so notes are sorted into
/// these buckets the same way other Hub list screens derive their categories.
class _Notebook {
  const _Notebook({
    required this.label,
    required this.icon,
    required this.tint,
    required this.keywords,
  });

  final String label;
  final IconData icon;
  final HubTint tint;
  final List<String> keywords;

  bool matches(Note note) {
    final text = '${note.title} ${note.body}'.toLowerCase();
    return keywords.any(text.contains);
  }
}

const List<_Notebook> _notebooks = [
  _Notebook(
    label: 'Briefings',
    icon: Icons.campaign_outlined,
    tint: HubTint.blue,
    keywords: ['brief', 'parade', 'roll call', 'shift', 'duty'],
  ),
  _Notebook(
    label: 'Investigations',
    icon: Icons.search,
    tint: HubTint.purple,
    keywords: ['case', 'suspect', 'witness', 'statement', 'investig', 'lead'],
  ),
  _Notebook(
    label: 'Incidents',
    icon: Icons.report_gmailerrorred_outlined,
    tint: HubTint.red,
    keywords: ['incident', 'report', 'scene', 'arrest', 'seiz'],
  ),
  _Notebook(
    label: 'Tasks & Follow-ups',
    icon: Icons.checklist_rtl,
    tint: HubTint.green,
    keywords: ['todo', 'follow', 'task', 'remind', 'pending', 'action'],
  ),
  _Notebook(
    label: 'Contacts',
    icon: Icons.contacts_outlined,
    tint: HubTint.teal,
    keywords: ['contact', 'phone', 'address', 'email', 'number'],
  ),
  _Notebook(
    label: 'General',
    icon: Icons.sticky_note_2_outlined,
    tint: HubTint.orange,
    keywords: [],
  ),
];

/// A note belongs to the first notebook whose keywords it matches, falling
/// back to "General" when nothing matches.
_Notebook _notebookOf(Note note) {
  for (final notebook in _notebooks) {
    if (notebook.keywords.isNotEmpty && notebook.matches(note)) {
      return notebook;
    }
  }
  return _notebooks.last;
}

/// Quick-access filters built from attributes the Note model actually exposes:
/// its [Note.updatedAt] timestamp and the length of its body.
enum _QuickFilter { recent, thisWeek, detailed }

extension on _QuickFilter {
  String get label => switch (this) {
        _QuickFilter.recent => 'Recent',
        _QuickFilter.thisWeek => 'This Week',
        _QuickFilter.detailed => 'Detailed',
      };

  IconData get icon => switch (this) {
        _QuickFilter.recent => Icons.schedule,
        _QuickFilter.thisWeek => Icons.date_range,
        _QuickFilter.detailed => Icons.notes,
      };

  bool matches(Note note) => switch (this) {
        _QuickFilter.recent => _daysSince(note) <= 1,
        _QuickFilter.thisWeek => _daysSince(note) <= 7,
        _QuickFilter.detailed => note.body.trim().length >= 280,
      };
}

int _daysSince(Note note) => DateTime.now().difference(note.updatedAt).inDays;

String _relativeTime(DateTime moment) {
  final difference = DateTime.now().difference(moment);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  if (difference.inDays < 30) return '${difference.inDays ~/ 7}w ago';
  return '${difference.inDays ~/ 30}mo ago';
}

String _snippetOf(Note note) {
  final firstLine = note.body
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  return firstLine.isEmpty ? 'No additional text' : firstLine;
}

String _titleOf(Note note) => note.title.trim().isEmpty ? 'Untitled' : note.title.trim();

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesRepository _repository = SharedPreferencesNotesRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Note> _notes = const [];
  bool _loading = true;

  String _query = '';
  _QuickFilter? _quickFilter;
  _Notebook? _notebook;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final notes = await _repository.listAll();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  List<Note> get _visible {
    final lower = _query.toLowerCase();
    return _notes.where((note) {
      if (lower.isNotEmpty) {
        final hit = note.title.toLowerCase().contains(lower) ||
            note.body.toLowerCase().contains(lower);
        if (!hit) return false;
      }
      if (_quickFilter != null && !_quickFilter!.matches(note)) return false;
      if (_notebook != null && _notebookOf(note) != _notebook) return false;
      return true;
    }).toList();
  }

  bool get _hasFilters =>
      _query.isNotEmpty || _quickFilter != null || _notebook != null;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _quickFilter = null;
      _notebook = null;
    });
  }

  void _toggleQuickFilter(_QuickFilter value) =>
      setState(() => _quickFilter = _quickFilter == value ? null : value);

  void _toggleNotebook(_Notebook value) =>
      setState(() => _notebook = _notebook == value ? null : value);

  Future<void> _openEditor({Note? existing}) async {
    final result = await Navigator.of(context).push<Note>(
      sharedAxis(_NoteEditorScreen(existing: existing)),
    );
    if (result != null) {
      await _repository.save(result);
      await _refresh();
    }
  }

  Future<void> _delete(Note note) async {
    await _repository.delete(note.id);
    await _refresh();
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('This will remove “${_titleOf(note)}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: HubTint.red.foreground,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _delete(note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HubStyle.pageBackground,
      body: Column(
        children: [
          HubGradientHeader(
            title: 'Notes',
            showBack: true,
            actions: const [
              IconTheme(
                data: IconThemeData(color: HubStyle.onGradient),
                child: NotificationsBell(),
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final visible = _visible;
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SearchRow(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HubStatBanner(
            icon: Icons.edit_note,
            count: _notes.length.toString(),
            label: 'Total Notes',
            caption: 'Across all notebooks',
            actionLabel: 'New Note',
            onAction: () => _openEditor(),
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(title: 'Quick Access'),
        ),
        const SizedBox(height: 10),
        _buildQuickAccessPills(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(
            title: _hasFilters ? 'Matching Notes' : 'Recent Notes',
            actionLabel: _hasFilters ? 'Clear' : 'View All',
            onAction: _hasFilters ? _resetFilters : null,
          ),
        ),
        const SizedBox(height: 10),
        if (_notes.isEmpty)
          const _EmptyNotes()
        else if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 30, 16, 30),
            child: Center(
              child: Text(
                'No matching notes',
                style: TextStyle(color: HubStyle.textSecondary),
              ),
            ),
          )
        else
          ...visible.map(
            (note) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _NoteCard(
                note: note,
                onTap: () => _openEditor(existing: note),
                onDelete: () => _confirmDelete(note),
              ),
            ),
          ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(title: 'My Notebooks'),
        ),
        const SizedBox(height: 10),
        _buildNotebookGrid(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _NewNoteBanner(onTap: () => _openEditor()),
        ),
      ],
    );
  }

  Widget _buildQuickAccessPills() {
    final pills = <Widget>[
      HubFilterPill(
        label: 'All',
        icon: Icons.dashboard_outlined,
        selected: _quickFilter == null,
        onTap: () => setState(() => _quickFilter = null),
      ),
      for (final filter in _QuickFilter.values)
        HubFilterPill(
          label: filter.label,
          icon: filter.icon,
          selected: _quickFilter == filter,
          onTap: () => _toggleQuickFilter(filter),
        ),
    ];
    return HubFilterPillRow(children: pills);
  }

  Widget _buildNotebookGrid() {
    final populated =
        _notebooks.where((n) => _notes.any(n.matches)).toList();
    final shown = populated.isEmpty ? _notebooks : populated;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
        children: [
          for (final notebook in shown)
            HubCategoryCard(
              icon: notebook.icon,
              title: notebook.label,
              count: '${_notes.where((n) => _notebookOf(n) == notebook).length} notes',
              tint: notebook.tint,
              selected: _notebook == notebook,
              onTap: () => _toggleNotebook(notebook),
            ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: HubStyle.cardShadow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search notes...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: HubStyle.textSecondary),
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final notebook = _notebookOf(note);
    final tint = notebook.tint;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(HubStyle.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(notebook.icon, color: tint.foreground, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleOf(note),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _snippetOf(note),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textSecondary,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 12,
                            color: HubStyle.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _relativeTime(note.updatedAt),
                            style: const TextStyle(
                              color: HubStyle.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _NotebookChip(notebook: notebook),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: HubTint.red.foreground,
                  tooltip: 'Delete note',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotebookChip extends StatelessWidget {
  const _NotebookChip({required this.notebook});

  final _Notebook notebook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: notebook.tint.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        notebook.label,
        style: TextStyle(
          color: notebook.tint.foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          Icon(Icons.edit_note, size: 56, color: HubStyle.textSecondary),
          SizedBox(height: 10),
          Text(
            'No notes yet',
            style: TextStyle(
              color: HubStyle.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap “New Note” to capture an idea or briefing point.',
            textAlign: TextAlign.center,
            style: TextStyle(color: HubStyle.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _NewNoteBanner extends StatelessWidget {
  const _NewNoteBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const tint = HubTint.blue;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tint.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.note_add_outlined,
                  color: tint.foreground, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture a new note',
                    style: TextStyle(
                      color: HubStyle.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Jot down briefings, leads, and follow-ups on the move.',
                    style: TextStyle(
                      color: HubStyle.textSecondary,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tint.foreground,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: onTap,
              child: const Text('New Note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteEditorScreen extends StatefulWidget {
  const _NoteEditorScreen({this.existing});

  final Note? existing;

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _bodyController = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HubStyle.pageBackground,
      body: Column(
        children: [
          HubGradientHeader(
            title: widget.existing == null ? 'New Note' : 'Edit Note',
            showBack: true,
            actions: [
              IconTheme(
                data: const IconThemeData(color: HubStyle.onGradient),
                child: IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Save note',
                  onPressed: _save,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EditorField(
                    controller: _titleController,
                    label: 'Title',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _EditorField(
                      controller: _bodyController,
                      label: 'Body',
                      expands: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final note = Note(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      updatedAt: DateTime.now(),
    );
    Navigator.of(context).pop(note);
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    this.expands = false,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final bool expands;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: HubStyle.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        maxLines: expands ? null : 1,
        expands: expands,
        textAlignVertical: expands ? TextAlignVertical.top : null,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: expands,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
