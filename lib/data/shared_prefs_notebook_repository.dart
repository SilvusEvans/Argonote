import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notebook.dart';
import 'notebook_repository.dart';

/// 基于 shared_preferences 的笔记本体系持久化。
///
/// 三种节点整体存一个 JSON 对象（数据量小、低频写），key 为
/// `argonote.notebookTree.v1`。首次读取时如果树不存在但旧版
/// `argonote.folders.v1` 存在，则执行一次性迁移：
/// 建一个默认笔记本，把每个文件夹转成 id 相同的分区
/// （这样笔记里残留的 folderId 可以直接当 sectionId 用，零成本兼容）。
class SharedPrefsNotebookRepository implements NotebookRepository {
  SharedPrefsNotebookRepository(this._prefs);

  static const String storageKey = 'argonote.notebookTree.v1';
  static const String legacyFoldersKey = 'argonote.folders.v1';

  final SharedPreferences _prefs;

  _TreeData _read() {
    final raw = _prefs.getString(storageKey);
    if (raw != null && raw.isNotEmpty) {
      return _TreeData.decode(raw);
    }
    final migrated = _migrateFromLegacyFolders();
    if (migrated != null) return migrated;
    return _TreeData();
  }

  _TreeData? _migrateFromLegacyFolders() {
    final legacy = _prefs.getString(legacyFoldersKey);
    if (legacy == null || legacy.isEmpty) return null;

    final decoded = jsonDecode(legacy);
    if (decoded is! List) return null;

    final defaultNotebook = Notebook.create('Notebook 1');
    final tree = _TreeData(
      notebooks: <Notebook>[defaultNotebook],
      sections: <Section>[
        for (final item in decoded)
          if (item is Map)
            Section(
              id: (item['id'] as String?) ?? '',
              notebookId: defaultNotebook.id,
              name: (item['name'] as String?) ?? '',
              createdAt:
                  DateTime.tryParse(item['createdAt'] as String? ?? '') ?? DateTime.now(),
            ),
      ],
    );
    // 迁移结果立即落盘，下次读取走正常路径。
    _write(tree);
    return tree;
  }

  void _write(_TreeData tree) {
    _prefs.setString(storageKey, tree.encode());
  }

  @override
  Future<List<Notebook>> notebooks() async => _read().notebooks;

  @override
  Future<List<SectionGroup>> sectionGroups() async => _read().groups;

  @override
  Future<List<Section>> sections() async => _read().sections;

  @override
  Future<Notebook> createNotebook(String name) async {
    final tree = _read();
    final notebook = Notebook.create(name);
    tree.notebooks.add(notebook);
    _write(tree);
    return notebook;
  }

  @override
  Future<Notebook> renameNotebook(String id, String name) async {
    final tree = _read();
    final index = tree.notebooks.indexWhere((n) => n.id == id);
    if (index == -1) return Notebook.create(name);
    final renamed = tree.notebooks[index].copyWith(name: name);
    tree.notebooks[index] = renamed;
    _write(tree);
    return renamed;
  }

  @override
  Future<Set<String>> deleteNotebook(String id) async {
    final tree = _read();
    final removedSections = <String>{
      ...tree.sections.where((s) => s.notebookId == id).map((s) => s.id),
    };
    tree.notebooks.removeWhere((n) => n.id == id);
    tree.groups.removeWhere((g) => g.notebookId == id);
    tree.sections.removeWhere((s) => s.notebookId == id);
    _write(tree);
    return removedSections;
  }

  @override
  Future<SectionGroup> createSectionGroup(String notebookId, String name) async {
    final tree = _read();
    final group = SectionGroup.create(notebookId, name);
    tree.groups.add(group);
    _write(tree);
    return group;
  }

  @override
  Future<SectionGroup> renameSectionGroup(String id, String name) async {
    final tree = _read();
    final index = tree.groups.indexWhere((g) => g.id == id);
    if (index == -1) return SectionGroup.create('', name);
    final renamed = tree.groups[index].copyWith(name: name);
    tree.groups[index] = renamed;
    _write(tree);
    return renamed;
  }

  @override
  Future<void> deleteSectionGroup(String id) async {
    final tree = _read();
    tree.groups.removeWhere((g) => g.id == id);
    // 组内分区上移到笔记本直属层，不删除。
    for (var i = 0; i < tree.sections.length; i++) {
      final section = tree.sections[i];
      if (section.groupId == id) {
        tree.sections[i] = section.copyWith(
          name: section.name,
          groupId: null,
        );
      }
    }
    _write(tree);
  }

  @override
  Future<Section> createSection(String notebookId, String name, {String? groupId}) async {
    final tree = _read();
    final section = Section.create(notebookId: notebookId, name: name, groupId: groupId);
    tree.sections.add(section);
    _write(tree);
    return section;
  }

  @override
  Future<Section> renameSection(String id, String name) async {
    final tree = _read();
    final index = tree.sections.indexWhere((s) => s.id == id);
    if (index == -1) {
      return Section.create(notebookId: '', name: name);
    }
    final renamed = tree.sections[index].copyWith(name: name);
    tree.sections[index] = renamed;
    _write(tree);
    return renamed;
  }

  @override
  Future<Section> moveSection(String id, String notebookId, {String? groupId}) async {
    final tree = _read();
    final index = tree.sections.indexWhere((s) => s.id == id);
    if (index == -1) {
      return Section.create(notebookId: notebookId, name: '', groupId: groupId);
    }
    final moved = tree.sections[index]
        .copyWith(name: tree.sections[index].name, notebookId: notebookId, groupId: groupId);
    tree.sections[index] = moved;
    _write(tree);
    return moved;
  }

  @override
  Future<void> deleteSection(String id) async {
    final tree = _read();
    tree.sections.removeWhere((s) => s.id == id);
    _write(tree);
  }
}

/// 内存里整套树的中转结构，读写时一次性解包/打包。
class _TreeData {
  _TreeData({
    List<Notebook>? notebooks,
    List<SectionGroup>? groups,
    List<Section>? sections,
  })  : notebooks = notebooks ?? <Notebook>[],
        groups = groups ?? <SectionGroup>[],
        sections = sections ?? <Section>[];

  final List<Notebook> notebooks;
  final List<SectionGroup> groups;
  final List<Section> sections;

  String encode() => jsonEncode(<String, Object>{
        'notebooks': notebooks.map((n) => n.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
        'sections': sections.map((s) => s.toJson()).toList(),
      });

  static _TreeData decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return _TreeData();

    List<T> parse<T>(String key, T Function(Map<String, dynamic>) build) {
      final list = decoded[key];
      if (list is! List) return <T>[];
      return <T>[
        for (final item in list)
          if (item is Map) build(item.map((k, v) => MapEntry(k.toString(), v))),
      ];
    }

    return _TreeData(
      notebooks: parse<Notebook>('notebooks', Notebook.fromJson),
      groups: parse<SectionGroup>('groups', SectionGroup.fromJson),
      sections: parse<Section>('sections', Section.fromJson),
    );
  }
}
