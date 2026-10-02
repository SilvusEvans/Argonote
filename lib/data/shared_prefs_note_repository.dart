import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';
import 'note_repository.dart';

/// 基于 shared_preferences 的本地持久化实现。
///
/// 存储策略：把整个笔记列表序列化成一个 JSON 数组，存在单个 key 下。
/// 对「记事本」这种数据量小（几百条以内）、写入不频繁的场景，
/// 这种整体读写的写法比引入数据库更简单，也更容易调试。
///
/// 数据量变大后，可以照同样接口换成 sqflite / isar 实现，UI 层零改动。
class SharedPrefsNoteRepository implements NoteRepository {
  SharedPrefsNoteRepository(this._prefs);

  /// 带版本号的 key，以后改数据结构时可以平滑迁移。
  /// v1 的旧数据（folderId）由 Note.fromJson 直接兼容读取，无需换 key。
  static const String storageKey = 'argonote.notes.v1';

  final SharedPreferences _prefs;

  @override
  Future<List<Note>> all() async => _readAll();

  @override
  Future<Note?> findById(String id) async {
    final notes = await _readAll();
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Future<Note> create({
    required String title,
    required String content,
    List<String> tags = const <String>[],
    String? notebookId,
    String? sectionId,
    bool pinned = false,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: Note.create().id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      tags: tags,
      notebookId: notebookId,
      sectionId: sectionId,
      pinned: pinned,
    );
    final notes = await _readAll();
    await _writeAll(<Note>[note, ...notes]);
    return note;
  }

  @override
  Future<Note> update({
    required String id,
    required String title,
    required String content,
    required List<String> tags,
    String? notebookId,
    String? sectionId,
  }) async {
    final notes = await _readAll();
    final index = notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      // 目标不存在时退化成新增，避免调用方拿到空而崩。
      return create(
        title: title,
        content: content,
        tags: tags,
        notebookId: notebookId,
        sectionId: sectionId,
      );
    }
    final updated = notes[index].copyWith(
      title: title,
      content: content,
      updatedAt: notes[index].bumpedUpdatedAt(),
      tags: tags,
      notebookId: notebookId,
      sectionId: sectionId,
    );
    notes[index] = updated;
    await _writeAll(notes);
    return updated;
  }

  @override
  Future<Note> setPinned(String id, bool pinned) => _patch(id, (note) {
        // 置顶不算编辑，保留原 updatedAt，避免打乱「最近修改」排序。
        return note.copyWith(pinned: pinned, updatedAt: note.updatedAt);
      });

  @override
  Future<Note> archiveNote(String id) => _patch(id, (note) {
        return note.copyWith(archived: true, deletedAt: DateTime.now(), updatedAt: note.updatedAt);
      });

  @override
  Future<Note> unarchiveNote(String id) => _patch(id, (note) {
        return note.copyWith(archived: false, deletedAt: null, updatedAt: note.updatedAt);
      });

  @override
  Future<void> delete(String id) async {
    final notes = await _readAll();
    notes.removeWhere((note) => note.id == id);
    await _writeAll(notes);
  }

  @override
  Future<void> restore(Note note) async {
    final notes = await _readAll();
    notes.removeWhere((item) => item.id == note.id);
    notes.add(note);
    await _writeAll(notes);
  }

  @override
  Future<void> moveNotesToNotebook(Iterable<String> noteIds, String notebookId) async {
    final targets = noteIds.toSet();
    final notes = await _readAll();
    var changed = false;
    for (var i = 0; i < notes.length; i++) {
      if (!targets.contains(notes[i].id)) continue;
      notes[i] = notes[i].copyWith(
        notebookId: notebookId,
        sectionId: null,
        updatedAt: notes[i].updatedAt,
      );
      changed = true;
    }
    if (changed) await _writeAll(notes);
  }

  @override
  Future<void> clearNoteSections(Iterable<String> noteIds) async {
    final targets = noteIds.toSet();
    final notes = await _readAll();
    var changed = false;
    for (var i = 0; i < notes.length; i++) {
      if (!targets.contains(notes[i].id) || notes[i].sectionId == null) continue;
      notes[i] = notes[i].copyWith(sectionId: null, updatedAt: notes[i].updatedAt);
      changed = true;
    }
    if (changed) await _writeAll(notes);
  }

  Future<Note> _patch(String id, Note Function(Note note) transform) async {
    final notes = await _readAll();
    final index = notes.indexWhere((note) => note.id == id);
    if (index == -1) throw StateError('note not found: $id');
    final updated = transform(notes[index]);
    notes[index] = updated;
    await _writeAll(notes);
    return updated;
  }

  Future<List<Note>> _readAll() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <Note>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Note>[];

    final notes = <Note>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        notes.add(Note.fromJson(item));
      } else if (item is Map) {
        notes.add(Note.fromJson(item.cast<String, dynamic>()));
      }
    }
    _sortByUpdatedAtDesc(notes);
    return notes;
  }

  Future<void> _writeAll(List<Note> notes) async {
    _sortByUpdatedAtDesc(notes);
    final encoded = jsonEncode(notes.map((note) => note.toJson()).toList());
    await _prefs.setString(storageKey, encoded);
  }

  static void _sortByUpdatedAtDesc(List<Note> notes) {
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
