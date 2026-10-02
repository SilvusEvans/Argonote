import '../models/note.dart';
import 'note_repository.dart';

/// 纯内存实现，供组件测试 / 预览使用。
///
/// 行为和 [SharedPrefsNoteRepository] 一致（同样按更新时间倒序），
/// 但不落盘，测试里无需 mock 平台通道。
class InMemoryNoteRepository implements NoteRepository {
  InMemoryNoteRepository([List<Note>? seed])
      : _notes = <Note>[...(seed ?? const <Note>[])];

  final List<Note> _notes;

  Note _require(String id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    throw StateError('note not found: $id');
  }

  @override
  Future<List<Note>> all() async {
    final copy = <Note>[..._notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return copy;
  }

  @override
  Future<Note?> findById(String id) async {
    for (final note in _notes) {
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
    final note = Note(
      id: Note.create().id,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
      notebookId: notebookId,
      sectionId: sectionId,
      pinned: pinned,
    );
    _notes.add(note);
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
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      return create(
        title: title,
        content: content,
        tags: tags,
        notebookId: notebookId,
        sectionId: sectionId,
      );
    }
    final updated = _notes[index].copyWith(
      title: title,
      content: content,
      updatedAt: _notes[index].bumpedUpdatedAt(),
      tags: tags,
      notebookId: notebookId,
      sectionId: sectionId,
    );
    _notes[index] = updated;
    return updated;
  }

  @override
  Future<Note> setPinned(String id, bool pinned) async {
    final note = _require(id);
    final updated = note.copyWith(pinned: pinned, updatedAt: note.updatedAt);
    _notes[_notes.indexOf(note)] = updated;
    return updated;
  }

  @override
  Future<Note> archiveNote(String id) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) throw StateError('note not found: $id');
    final archived = _notes[index].copyWith(archived: true, deletedAt: DateTime.now());
    _notes[index] = archived;
    return archived;
  }

  @override
  Future<Note> unarchiveNote(String id) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) throw StateError('note not found: $id');
    final restored = _notes[index].copyWith(archived: false, deletedAt: null);
    _notes[index] = restored;
    return restored;
  }

  @override
  Future<void> delete(String id) async {
    _notes.removeWhere((note) => note.id == id);
  }

  @override
  Future<void> restore(Note note) async {
    _notes.removeWhere((item) => item.id == note.id);
    _notes.add(note);
  }

  @override
  Future<void> moveNotesToNotebook(Iterable<String> noteIds, String notebookId) async {
    final targets = noteIds.toSet();
    for (var i = 0; i < _notes.length; i++) {
      if (!targets.contains(_notes[i].id)) continue;
      _notes[i] = _notes[i].copyWith(
        notebookId: notebookId,
        sectionId: null,
        updatedAt: _notes[i].updatedAt,
      );
    }
  }

  @override
  Future<void> clearNoteSections(Iterable<String> noteIds) async {
    final targets = noteIds.toSet();
    for (var i = 0; i < _notes.length; i++) {
      if (!targets.contains(_notes[i].id) || _notes[i].sectionId == null) continue;
      _notes[i] = _notes[i].copyWith(sectionId: null, updatedAt: _notes[i].updatedAt);
    }
  }
}
