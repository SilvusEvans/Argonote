import '../models/folder.dart';

/// 文件夹仓储接口。与笔记仓储分开，各自只管自己的聚合。
abstract class FolderRepository {
  /// 全部文件夹，按名称升序。
  Future<List<Folder>> all();

  Future<Folder?> findById(String id);

  Future<Folder> create(String name);

  Future<Folder> rename(String id, String name);

  /// 删除文件夹。笔记不会被删除，只是失去 folderId（UI 上显示为「未归类」）。
  Future<void> delete(String id);
}
