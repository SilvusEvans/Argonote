import '../models/folder.dart';
import 'folder_repository.dart';

/// 内存版文件夹仓储，供测试使用。
class InMemoryFolderRepository implements FolderRepository {
  InMemoryFolderRepository([List<Folder>? seed])
      : _folders = <Folder>[...(seed ?? const <Folder>[])];

  final List<Folder> _folders;

  @override
  Future<List<Folder>> all() async {
    final copy = <Folder>[..._folders]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return copy;
  }

  @override
  Future<Folder?> findById(String id) async {
    for (final folder in _folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  @override
  Future<Folder> create(String name) async {
    final folder = Folder.create(name);
    _folders.add(folder);
    return folder;
  }

  @override
  Future<Folder> rename(String id, String name) async {
    final index = _folders.indexWhere((folder) => folder.id == id);
    if (index == -1) return Folder.create(name);
    final renamed = _folders[index].copyWith(name: name);
    _folders[index] = renamed;
    return renamed;
  }

  @override
  Future<void> delete(String id) async {
    _folders.removeWhere((folder) => folder.id == id);
  }
}
