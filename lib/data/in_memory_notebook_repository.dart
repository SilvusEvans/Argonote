import '../models/notebook.dart';
import 'notebook_repository.dart';

/// 内存版笔记本仓储，供测试使用。行为与 SharedPrefs 实现一致。
class InMemoryNotebookRepository implements NotebookRepository {
  InMemoryNotebookRepository({
    List<Notebook>? notebooks,
    List<SectionGroup>? groups,
    List<Section>? sections,
  })  : _notebooks = <Notebook>[...(notebooks ?? const <Notebook>[])],
        _groups = <SectionGroup>[...(groups ?? const <SectionGroup>[])],
        _sections = <Section>[...(sections ?? const <Section>[])];

  final List<Notebook> _notebooks;
  final List<SectionGroup> _groups;
  final List<Section> _sections;

  @override
  Future<List<Notebook>> notebooks() async => List<Notebook>.unmodifiable(_notebooks);

  @override
  Future<List<SectionGroup>> sectionGroups() async => List<SectionGroup>.unmodifiable(_groups);

  @override
  Future<List<Section>> sections() async => List<Section>.unmodifiable(_sections);

  @override
  Future<Notebook> createNotebook(String name) async {
    final notebook = Notebook.create(name);
    _notebooks.add(notebook);
    return notebook;
  }

  @override
  Future<Notebook> renameNotebook(String id, String name) async {
    final index = _notebooks.indexWhere((n) => n.id == id);
    if (index == -1) return Notebook.create(name);
    final renamed = _notebooks[index].copyWith(name: name);
    _notebooks[index] = renamed;
    return renamed;
  }

  @override
  Future<Set<String>> deleteNotebook(String id) async {
    final removed = <String>{..._sections.where((s) => s.notebookId == id).map((s) => s.id)};
    _notebooks.removeWhere((n) => n.id == id);
    _groups.removeWhere((g) => g.notebookId == id);
    _sections.removeWhere((s) => s.notebookId == id);
    return removed;
  }

  @override
  Future<SectionGroup> createSectionGroup(String notebookId, String name) async {
    final group = SectionGroup.create(notebookId, name);
    _groups.add(group);
    return group;
  }

  @override
  Future<SectionGroup> renameSectionGroup(String id, String name) async {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index == -1) return SectionGroup.create('', name);
    final renamed = _groups[index].copyWith(name: name);
    _groups[index] = renamed;
    return renamed;
  }

  @override
  Future<void> deleteSectionGroup(String id) async {
    _groups.removeWhere((g) => g.id == id);
    for (var i = 0; i < _sections.length; i++) {
      if (_sections[i].groupId == id) {
        _sections[i] = _sections[i].copyWith(groupId: null);
      }
    }
  }

  @override
  Future<Section> createSection(String notebookId, String name, {String? groupId}) async {
    final section = Section.create(notebookId: notebookId, name: name, groupId: groupId);
    _sections.add(section);
    return section;
  }

  @override
  Future<Section> renameSection(String id, String name) async {
    final index = _sections.indexWhere((s) => s.id == id);
    if (index == -1) return Section.create(notebookId: '', name: name);
    final renamed = _sections[index].copyWith(name: name);
    _sections[index] = renamed;
    return renamed;
  }

  @override
  Future<Section> moveSection(String id, String notebookId, {String? groupId}) async {
    final index = _sections.indexWhere((s) => s.id == id);
    if (index == -1) {
      return Section.create(notebookId: notebookId, name: '', groupId: groupId);
    }
    final moved = _sections[index]
        .copyWith(notebookId: notebookId, groupId: groupId);
    _sections[index] = moved;
    return moved;
  }

  @override
  Future<void> deleteSection(String id) async {
    _sections.removeWhere((s) => s.id == id);
  }
}
