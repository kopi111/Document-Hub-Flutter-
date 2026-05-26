import 'package:flutter/material.dart';

import '../../models/notes/note.dart';
import '../../services/notes/notes_repository.dart';
import '../../theme/jcf_palette.dart';
import '../../widgets/breadcrumb_trail.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesRepository _repository = SharedPreferencesNotesRepository();
  List<Note> _notes = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
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

  Future<void> _openEditor({Note? existing}) async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(builder: (_) => _NoteEditorScreen(existing: existing)),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments()),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: JcfPalette.accent,
        foregroundColor: JcfPalette.onAccent,
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
    );
  }

  List<BreadcrumbSegment> _breadcrumbSegments() {
    return [
      BreadcrumbSegment(
        label: 'Home',
        onTap: Navigator.canPop(context)
            ? () => Navigator.popUntil(context, (route) => route.isFirst)
            : null,
      ),
      const BreadcrumbSegment(label: 'Notes'),
    ];
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notes_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No notes yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap “New note” to capture an idea or briefing point.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _notes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = _notes[index];
        return ListTile(
          tileColor: Theme.of(context).colorScheme.surface,
          title: Text(note.title.isEmpty ? 'Untitled' : note.title),
          subtitle: Text(
            note.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            color: JcfPalette.danger,
            tooltip: 'Delete note',
            onPressed: () => _confirmDelete(note),
          ),
          onTap: () => _openEditor(existing: note),
        );
      },
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('This will remove “${note.title.isEmpty ? 'Untitled' : note.title}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: JcfPalette.danger,
              foregroundColor: JcfPalette.onDanger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _delete(note);
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
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New note' : 'Edit note'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save note',
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
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
