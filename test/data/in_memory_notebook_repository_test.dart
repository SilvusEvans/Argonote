import 'package:argonote/data/in_memory_notebook_repository.dart';
import 'package:argonote/models/notebook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryNotebookRepository', () {
    test('新建笔记本后按创建顺序返回', () async {
      final repo = InMemoryNotebookRepository();
      final a = await repo.createNotebook('工作');
      final b = await repo.createNotebook('生活');

      final notebooks = await repo.notebooks();
      expect(notebooks.map((n) => n.name), <String>['工作', '生活']);
      expect(a.id, isNot(b.id));
    });

    test('重命名笔记本', () async {
      final repo = InMemoryNotebookRepository();
      final nb = await repo.createNotebook('旧名');
      final renamed = await repo.renameNotebook(nb.id, '新名');

      expect(renamed.name, '新名');
      expect((await repo.notebooks()).single.name, '新名');
    });

    test('删除笔记本连带分区与分区组，并返回受影响分区 id', () async {
      final repo = InMemoryNotebookRepository();
      final nb = await repo.createNotebook('待删');
      final other = await repo.createNotebook('保留');
      final group = await repo.createSectionGroup(nb.id, '组');
      final s1 = await repo.createSection(nb.id, '分区A');
      final s2 = await repo.createSection(nb.id, '分区B', groupId: group.id);
      final keepSection = await repo.createSection(other.id, '别的');

      final removed = await repo.deleteNotebook(nb.id);

      expect(removed, <String>{s1.id, s2.id});
      expect(await repo.notebooks(), <Notebook>[other]);
      expect(await repo.sectionGroups(), isEmpty);
      expect((await repo.sections()).map((s) => s.id), <String>[keepSection.id]);
    });

    test('删除分区组后组内分区上移且不删除', () async {
      final repo = InMemoryNotebookRepository();
      final nb = await repo.createNotebook('笔记本');
      final group = await repo.createSectionGroup(nb.id, '组');
      final section = await repo.createSection(nb.id, '分区', groupId: group.id);

      await repo.deleteSectionGroup(group.id);

      expect(await repo.sectionGroups(), isEmpty);
      final moved = (await repo.sections()).single;
      expect(moved.id, section.id);
      expect(moved.groupId, isNull);
      expect(moved.notebookId, nb.id);
    });

    test('移动分区到另一个笔记本', () async {
      final repo = InMemoryNotebookRepository();
      final from = await repo.createNotebook('A');
      final to = await repo.createNotebook('B');
      final section = await repo.createSection(from.id, '分区');

      final moved = await repo.moveSection(section.id, to.id);

      expect(moved.notebookId, to.id);
      expect(moved.name, '分区');
      expect(moved.groupId, isNull);
    });

    test('id 连续创建不重复（毫秒级时钟兜底）', () async {
      final repo = InMemoryNotebookRepository();
      final ids = <String>{};
      for (var i = 0; i < 50; i++) {
        ids.add((await repo.createNotebook('n$i')).id);
      }
      expect(ids.length, 50);
    });
  });
}
