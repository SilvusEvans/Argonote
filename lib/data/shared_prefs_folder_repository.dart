import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/folder.dart';
import 'folder_repository.dart';

/// 基于 shared_preferences 的文件夹持久化，策略与笔记一致：整体 JSON 读写。
class SharedPrefsFolderRepository implements FolderRepository {
  SharedPrefsFolderRepository(this._prefs);

  static const String storageKey = 'argonote.folders.v1';

  final SharedPreferences _prefs;

  @override
  Future<List<Folder>> all() async => _readAll();

  @override
  Future<Folder?> findById(String id) async {
    for (final folder in await _readAll()) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  @override
  Future<Folder> create(String name) async {
    final folder = Folder.create(name);
    final folders = await _readAll();
    await _writeAll(<Folder>[...folders, folder]);
    return folder;
  }

  @override
  Future<Folder> rename(String id, String name) async {
    final folders = await _readAll();
    final index = folders.indexWhere((folder) => folder.id == id);
    if (index == -1) return Folder.create(name);

    final renamed = folders[index].copyWith(name: name);
    folders[index] = renamed;
    await _writeAll(folders);
    return renamed;
  }

  @override
  Future<void> delete(String id) async {
    final folders = await _readAll();
    folders.removeWhere((folder) => folder.id == id);
    await _writeAll(folders);
  }

  Future<List<Folder>> _readAll() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <Folder>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Folder>[];

    final folders = <Folder>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        folders.add(Folder.fromJson(item));
      }
    }
    _sortByName(folders);
    return folders;
  }

  Future<void> _writeAll(List<Folder> folders) async {
    _sortByName(folders);
    await _prefs.setString(storageKey, jsonEncode(folders.map((f) => f.toJson()).toList()));
  }

  static void _sortByName(List<Folder> folders) {
    folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
