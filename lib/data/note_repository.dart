import '../models/note.dart';

/// 笔记（页）仓储接口。
///
/// UI 只依赖这个抽象，不关心底层是 SharedPreferences、SQLite 还是远端接口。
/// 换存储实现时，只需要改 [main.dart] 里注入的那一行。
abstract class NoteRepository {
  /// 返回全部笔记（含回收站里的），按更新时间倒序。
  Future<List<Note>> all();

  /// 按 id 取一条，不存在返回 null。
  Future<Note?> findById(String id);

  /// 新建一条笔记并返回落库后的实例。
  Future<Note> create({
    required String title,
    required String content,
    List<String> tags = const <String>[],
    String? sectionId,
    bool pinned = false,
  });

  /// 更新标题/正文/标签/分区（内部刷新 updatedAt），返回更新后的实例。
  Future<Note> update({
    required String id,
    required String title,
    required String content,
    required List<String> tags,
    String? sectionId,
  });

  /// 置顶 / 取消置顶。不刷新 updatedAt（置顶不算编辑）。
  Future<Note> setPinned(String id, bool pinned);

  /// 移入回收站（软删除）。记录 deletedAt。
  Future<Note> moveToTrash(String id);

  /// 从回收站还原。
  Future<Note> restoreFromTrash(String id);

  /// 彻底删除一条笔记。id 不存在时静默忽略。
  Future<void> delete(String id);

  /// 还原一条笔记，用于「撤销删除」：连同原始 id、创建时间一起还原。
  Future<void> restore(Note note);

  /// 分区/笔记本被删后，解除这批分区下笔记的归属（sectionId 置空）。
  Future<void> unassignSections(Set<String> sectionIds);
}
