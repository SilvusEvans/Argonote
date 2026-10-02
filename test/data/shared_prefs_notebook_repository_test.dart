import 'dart:convert';

import 'package:argonote/data/shared_prefs_notebook_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPrefsNotebookRepository 旧文件夹迁移', () {
    test('首次读取时把 folders.v1 转成默认笔记本下的分区（id 保留）', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPrefsNotebookRepository.legacyFoldersKey: jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'folder-a',
            'name': '工作',
            'createdAt': '2026-01-01T00:00:00.000',
          },
          <String, dynamic>{
            'id': 'folder-b',
            'name': '生活',
            'createdAt': '2026-01-02T00:00:00.000',
          },
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsNotebookRepository(prefs);

      final notebooks = await repo.notebooks();
      expect(notebooks, hasLength(1));

      final sections = await repo.sections();
      expect(sections.map((s) => s.id), <String>['folder-a', 'folder-b']);
      expect(sections.map((s) => s.name), <String>['工作', '生活']);
      expect(sections.every((s) => s.notebookId == notebooks.single.id), isTrue);

      // 迁移结果已落盘：第二次读取不再重复迁移。
      final again = await repo.notebooks();
      expect(again, hasLength(1));
    });

    test('无旧数据时为空树，不建默认笔记本', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsNotebookRepository(prefs);

      expect(await repo.notebooks(), isEmpty);
      expect(await repo.sections(), isEmpty);
    });

    test('已有树数据时不重复迁移', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPrefsNotebookRepository.legacyFoldersKey:
            jsonEncode(<Map<String, String>>[{'id': 'f', 'name': '旧', 'createdAt': '2026-01-01T00:00:00.000'}]),
        SharedPrefsNotebookRepository.storageKey:
            jsonEncode(<String, Object>{'notebooks': [], 'groups': [], 'sections': []}),
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsNotebookRepository(prefs);

      expect(await repo.notebooks(), isEmpty);
    });

    test('CRUD 往返持久化', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsNotebookRepository(prefs);

      final nb = await repo.createNotebook('研究');
      final group = await repo.createSectionGroup(nb.id, '组一');
      final section = await repo.createSection(nb.id, '分区', groupId: group.id);

      final renamed = await repo.renameSection(section.id, '分区改');
      expect(renamed.name, '分区改');

      final removed = await repo.deleteNotebook(nb.id);
      expect(removed, {section.id});
      expect(await repo.sections(), isEmpty);
      expect(await repo.sectionGroups(), isEmpty);
    });
  });
}
