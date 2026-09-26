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
    String? folderId,
  }) async {
    final note = Note.create(
      title: title,
      content: content,
      tags: tags,
      folderId: folderId,
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
    String? folderId,
  }) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      return create(title: title, content: content, tags: tags, folderId: folderId);
    }
    final updated = _notes[index].copyWith(
      title: title,
      content: content,
      updatedAt: DateTime.now(),
      tags: tags,
      folderId: folderId,
    );
    _notes[index] = updated;
    return updated;
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
}
