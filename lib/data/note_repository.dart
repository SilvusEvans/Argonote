import '../models/note.dart';

/// 笔记仓储接口。
///
/// UI 只依赖这个抽象，不关心底层是 SharedPreferences、SQLite 还是远端接口。
/// 换存储实现时，只需要改 [main.dart] 里注入的那一行。
abstract class NoteRepository {
  /// 返回全部笔记，按更新时间倒序（最近编辑的排最前）。
  Future<List<Note>> all();

  /// 按 id 取一条，不存在返回 null。
  Future<Note?> findById(String id);

  /// 新建一条笔记并返回落库后的实例。
  Future<Note> create({required String title, required String content});

  /// 更新标题/正文（内部刷新 updatedAt），返回更新后的实例。
  Future<Note> update({
    required String id,
    required String title,
    required String content,
  });

  /// 删除一条笔记。id 不存在时静默忽略。
  Future<void> delete(String id);

  /// 恢复一条笔记，用于「撤销删除」：连同原始 id、创建时间一起还原。
  Future<void> restore(Note note);
}
