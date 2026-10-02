import '../models/notebook.dart';

/// 笔记本体系仓储：笔记本 / 分区组 / 分区 三种节点一起管理。
///
/// 取代旧的 FolderRepository。删除节点时仓储只负责自己的数据，
/// 笔记的归属解除（sectionId 置空）由调用方通过 NoteRepository 完成。
abstract class NotebookRepository {
  /// 全部笔记本，按创建顺序。
  Future<List<Notebook>> notebooks();

  Future<List<SectionGroup>> sectionGroups();

  Future<List<Section>> sections();

  Future<Notebook> createNotebook(String name);

  Future<Notebook> renameNotebook(String id, String name);

  /// 删除笔记本，连带其下所有分区组和分区。返回被删分区的 id 集合，
  /// 调用方用它去解除笔记归属。
  Future<Set<String>> deleteNotebook(String id);

  Future<SectionGroup> createSectionGroup(String notebookId, String name);

  Future<SectionGroup> renameSectionGroup(String id, String name);

  /// 删除分区组；组内分区不删除，上移到笔记本直属层。
  Future<void> deleteSectionGroup(String id);

  Future<Section> createSection(String notebookId, String name, {String? groupId});

  Future<Section> renameSection(String id, String name);

  /// 把分区移动到笔记本（可指定分区组；不传表示移到笔记本直属层）。
  Future<Section> moveSection(String id, String notebookId, {String? groupId});

  /// 删除单个分区。调用方负责解除其下笔记的归属。
  Future<void> deleteSection(String id);
}
