import 'package:argonote/data/in_memory_note_repository.dart';
import 'package:argonote/models/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryNoteRepository', () {
    test('all 按更新时间倒序', () async {
      final repo = InMemoryNoteRepository();
      final a = await repo.create(title: 'a', content: '1');
      final b = await repo.create(title: 'b', content: '2');

      final notes = await repo.all();
      expect(notes.first.id, b.id);
      expect(notes.last.id, a.id);
    });

    test('create 记录分区与置顶', () async {
      final repo = InMemoryNoteRepository();
      final note = await repo.create(
        title: 't',
        content: 'c',
        sectionId: 'sec-1',
        pinned: true,
      );

      expect(note.sectionId, 'sec-1');
      expect(note.pinned, isTrue);
    });

    test('update 刷新内容与分区（显式传 null 表示移出分区）', () async {
      final repo = InMemoryNoteRepository();
      final note = await repo.create(title: 't', content: 'c', sectionId: 'sec-1');

      final updated = await repo.update(
        id: note.id,
        title: 't2',
        content: 'c2',
        tags: const <String>['x'],
        sectionId: null,
      );

      expect(updated.title, 't2');
      expect(updated.tags, <String>['x']);
      expect(updated.sectionId, isNull);
      expect(updated.updatedAt.isAfter(note.createdAt), isTrue);
    });

    test('update 不存在的 id 退化成新增', () async {
      final repo = InMemoryNoteRepository();
      final created = await repo.update(
        id: 'missing',
        title: 't',
        content: 'c',
        tags: const <String>[],
      );

      expect(await repo.all(), hasLength(1));
      expect((await repo.findById(created.id))!.title, 't');
    });

    test('回收站：移入 / 还原 / 彻底删除', () async {
      final repo = InMemoryNoteRepository();
      final note = await repo.create(title: 't', content: 'c');

      final trashed = await repo.moveToTrash(note.id);
      expect(trashed.trashed, isTrue);
      expect(trashed.deletedAt, isNotNull);
      expect((await repo.findById(note.id))!.trashed, isTrue);

      final restored = await repo.restoreFromTrash(note.id);
      expect(restored.trashed, isFalse);
      expect(restored.deletedAt, isNull);

      await repo.delete(note.id);
      expect(await repo.all(), isEmpty);
    });

    test('setPinned 不改变 updatedAt', () async {
      final repo = InMemoryNoteRepository();
      final note = await repo.create(title: 't', content: 'c');

      final pinned = await repo.setPinned(note.id, true);
      expect(pinned.pinned, isTrue);
      expect(pinned.updatedAt, note.updatedAt);
    });

    test('unassignSections 只解除指定分区的归属', () async {
      final repo = InMemoryNoteRepository();
      final inA = await repo.create(title: 'a', content: '', sectionId: 'sec-a');
      final inB = await repo.create(title: 'b', content: '', sectionId: 'sec-b');

      await repo.unassignSections({'sec-a'});

      expect((await repo.findById(inA.id))!.sectionId, isNull);
      expect((await repo.findById(inB.id))!.sectionId, 'sec-b');
    });

    test('restore 用于撤销删除，保留原 id 与创建时间', () async {
      final repo = InMemoryNoteRepository();
      final note = await repo.create(title: 't', content: 'c');
      await repo.delete(note.id);

      await repo.restore(note);
      final restored = await repo.findById(note.id);
      expect(restored, isNotNull);
      expect(restored!.createdAt, note.createdAt);
    });

    test('连续新建 id 不重复（毫秒级时钟兜底）', () async {
      final repo = InMemoryNoteRepository();
      final ids = <String>{};
      for (var i = 0; i < 50; i++) {
        ids.add((await repo.create(title: 'n$i', content: '')).id);
      }
      expect(ids.length, 50);
    });

    test('脏 JSON 兜底：folderId 视为 sectionId', () {
      final note = Note.fromJson(<String, dynamic>{
        'id': 'x',
        'title': 't',
        'content': 'c',
        'folderId': 'legacy-folder',
      });
      expect(note.sectionId, 'legacy-folder');
      expect(note.pinned, isFalse);
      expect(note.trashed, isFalse);
    });
  });
}
