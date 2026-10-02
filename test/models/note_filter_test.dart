import 'package:argonote/models/note.dart';
import 'package:argonote/models/note_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Note _note({
  String id = 'id',
  String title = '',
  String content = '',
  List<String> tags = const <String>[],
  String? notebookId,
  String? sectionId,
  bool pinned = false,
  bool archived = false,
  DateTime? updatedAt,
}) {
  return Note(
    id: id,
    title: title,
    content: content,
    createdAt: updatedAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    tags: tags,
    notebookId: notebookId,
    sectionId: sectionId,
    pinned: pinned,
    archived: archived,
  );
}

void main() {
  group('NoteFilter 关键词 / 标签', () {
    test('关键词匹配标题、正文、标签，忽略大小写', () {
      const filter = NoteFilter(keyword: 'FLUTTER');
      expect(filter.matches(_note(title: 'learn flutter')), isTrue);
      expect(filter.matches(_note(content: 'Flutter rocks')), isTrue);
      expect(filter.matches(_note(tags: const <String>['Flutter'])), isTrue);
      expect(filter.matches(_note(title: 'dart')), isFalse);
    });

    test('标签筛选', () {
      const filter = NoteFilter(tag: '工作');
      expect(filter.matches(_note(tags: const <String>['工作', '重要'])), isTrue);
      expect(filter.matches(_note(tags: const <String>['生活'])), isFalse);
    });

    test('copyWith 哨兵区分「不传」与「传 null」', () {
      const base = NoteFilter(tag: 'a');
      expect(base.copyWith(keyword: 'x').tag, 'a');
      expect(base.copyWith(tag: null).tag, isNull);
    });

    test('collectTags 去重排序', () {
      final tags = NoteFilter.collectTags(<Note>[
        _note(tags: const <String>['b', 'a']),
        _note(tags: const <String>['a', 'c']),
      ]);
      expect(tags, <String>['a', 'b', 'c']);
    });
  });

  group('NoteFilter.apply 范围', () {
    final active = _note(id: 'active', notebookId: 'nb-1', sectionId: 'sec-a', updatedAt: DateTime(2026, 6, 1));
    final pinnedOld = _note(
      id: 'pinned',
      notebookId: 'nb-1',
      sectionId: 'sec-a',
      pinned: true,
      updatedAt: DateTime(2026, 1, 1),
    );
    final otherSection = _note(id: 'other', notebookId: 'nb-1', sectionId: 'sec-b', updatedAt: DateTime(2026, 5, 1));
    final stray = _note(id: 'stray', notebookId: 'nb-1', updatedAt: DateTime(2026, 4, 1));
    final archived = _note(id: 'archived', notebookId: 'nb-2', archived: true, updatedAt: DateTime(2026, 7, 1));
    final all = <Note>[active, pinnedOld, otherSection, stray, archived];

    test('all 排除回收站，置顶永远在前', () {
      final result = NoteFilter.empty.apply(all, NoteScope.all);
      expect(result.map((n) => n.id), <String>['pinned', 'active', 'other', 'stray']);
    });

    test('pinned 只看未删除的置顶', () {
      final result = NoteFilter.empty.apply(all, NoteScope.pinned);
      expect(result.map((n) => n.id), <String>['pinned']);
    });

    test('archived 只看回收站', () {
      final result = NoteFilter.empty.apply(all, NoteScope.archived);
      expect(result.map((n) => n.id), <String>['archived']);
    });

    test('pinned 排除已归档的置顶', () {
      final pinnedArchived = _note(
        id: 'both',
        sectionId: 'sec-a',
        pinned: true,
        archived: true,
        updatedAt: DateTime(2026, 8, 1),
      );
      final result = NoteFilter.empty.apply(<Note>[...all, pinnedArchived], NoteScope.pinned);
      expect(result.map((n) => n.id), <String>['pinned']);
    });

    test('section 精确匹配', () {
      final result = NoteFilter.empty.apply(all, const NoteScope.section('sec-a'));
      expect(result.map((n) => n.id), <String>['pinned', 'active']);
    });

    test('notebook 按 notebookId 圈定，含未分区的笔记', () {
      final result = NoteFilter.empty.apply(all, const NoteScope.notebook('nb-1'));
      expect(result.map((n) => n.id), <String>['pinned', 'active', 'other', 'stray']);
    });

    test('notebook 范围排除其他笔记本', () {
      final result = NoteFilter.empty.apply(all, const NoteScope.notebook('nb-2'));
      expect(result, isEmpty);
    });

    test('unsectioned 只看该笔记本下没有分区的笔记', () {
      final result = NoteFilter.empty.apply(all, const NoteScope.unsectioned('nb-1'));
      expect(result.map((n) => n.id), <String>['stray']);
    });

    test('group 用组内分区 id 集合圈定', () {
      final result = NoteFilter.empty.apply(
        all,
        const NoteScope.group('g-1'),
        groupSectionIds: const <String>{'sec-a'},
      );
      expect(result.map((n) => n.id), <String>['pinned', 'active']);
    });

    test('排序方式：标题升序', () {
      final a = _note(id: '1', title: 'Banana', updatedAt: DateTime(2026, 1, 1));
      final b = _note(id: '2', title: 'apple', updatedAt: DateTime(2026, 2, 1));
      final result = const NoteFilter(sort: NoteSort.titleAsc).apply(<Note>[a, b], NoteScope.all);
      expect(result.map((n) => n.title), <String>['apple', 'Banana']);
    });

    test('排序方式：创建时间倒序', () {
      final old = Note(
        id: 'old',
        title: '',
        content: '',
        createdAt: DateTime(2020),
        updatedAt: DateTime(2026, 12, 1),
      );
      final fresh = _note(id: 'fresh', updatedAt: DateTime(2026, 3, 1));
      final result =
          const NoteFilter(sort: NoteSort.createdAtDesc).apply(<Note>[old, fresh], NoteScope.all);
      expect(result.first.id, 'old');
    });

    test('范围 + 关键词叠加', () {
      const filter = NoteFilter(keyword: 'active');
      final withTitle = _note(id: 'active', title: 'active note', sectionId: 'sec-a');
      final result = filter.apply(<Note>[withTitle, otherSection], const NoteScope.section('sec-a'));
      expect(result.map((n) => n.id), <String>['active']);
    });
  });

  group('NoteScope', () {
    test('section / notebook 携带 id', () {
      expect(const NoteScope.section('s').kind, NoteScopeKind.section);
      expect(const NoteScope.section('s').id, 's');
      expect(const NoteScope.unsectioned('nb').kind, NoteScopeKind.unsectioned);
      expect(const NoteScope.unsectioned('nb').id, 'nb');
      expect(NoteScope.all.id, isNull);
    });
  });
}
