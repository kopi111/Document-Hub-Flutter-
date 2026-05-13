import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/notes/note.dart';

abstract class NotesRepository {
  Future<List<Note>> listAll();
  Future<void> save(Note note);
  Future<void> delete(String noteId);
}

class SharedPreferencesNotesRepository implements NotesRepository {
  static const _storageKey = 'jcf_notes_v1';

  @override
  Future<List<Note>> listAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Note.fromJson(item as Map<String, dynamic>))
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> save(Note note) async {
    final existing = await _readAll();
    final filtered = existing.where((other) => other.id != note.id).toList();
    filtered.add(note);
    await _writeAll(filtered);
  }

  @override
  Future<void> delete(String noteId) async {
    final existing = await _readAll();
    final filtered = existing.where((other) => other.id != noteId).toList();
    await _writeAll(filtered);
  }

  Future<List<Note>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Note.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeAll(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(notes.map((note) => note.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
