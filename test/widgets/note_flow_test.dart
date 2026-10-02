import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:argonote/app.dart';
import 'package:argonote/data/in_memory_note_repository.dart';
import 'package:argonote/data/in_memory_notebook_repository.dart';
import 'package:argonote/data/in_memory_settings_repository.dart';
import 'package:argonote/l10n/app_strings.dart';
import 'package:argonote/models/note.dart';
import 'package:argonote/settings/settings_controller.dart';

Future<SettingsController> _createSettingsController() async {
  final controller = SettingsController(InMemorySettingsRepository());
  await controller.load();
  return controller;
}

void _useWideScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// 按下 Ctrl 加指定键，用来触发外壳注册的快捷键。
Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

void main() {
  group('桌面三栏 + 多标签', () {
    testWidgets('树显示笔记本/分区，点笔记开标签编辑并自动保存', (WidgetTester tester) async {
      _useWideScreen(tester);
      final notes = InMemoryNoteRepository();
      final tree = InMemoryNotebookRepository();
      final nb = await tree.createNotebook('研究');
      final section = await tree.createSection(nb.id, '文献');
      await notes.create(title: '会议纪要', content: '下周一上线', sectionId: section.id);

      final settings = await _createSettingsController();
      await tester.pumpWidget(
        ArgonoteApp(
          noteRepository: notes,
          notebookRepository: tree,
          settingsController: settings,
        ),
      );
      await tester.pumpAndSettle();

      // 树节点 + 固定视图
      expect(find.text('研究'), findsOneWidget);
      expect(find.text('文献'), findsOneWidget);
      expect(find.text('所有笔记'), findsOneWidget);

      // 点列表里的笔记 → 编辑器标签出现
      await tester.tap(find.text('会议纪要'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noteTitleField')), findsOneWidget);

      // 输入正文 → 防抖自动落库
      await tester.enterText(find.byKey(const Key('noteContentField')), '补充：记得发议程');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      final saved = (await notes.all()).single;
      expect(saved.content, contains('记得发议程'));
      expect(saved.sectionId, section.id);

      // 选中分区节点 → 列表按分区过滤
      await tester.tap(find.text('文献'));
      await tester.pumpAndSettle();
      expect(find.text('会议纪要'), findsOneWidget);

      await tester.tap(find.text('所有笔记'));
      await tester.pumpAndSettle();
      expect(find.text('会议纪要'), findsOneWidget);
    });

    testWidgets('标签页可打开多个并可关闭', (WidgetTester tester) async {
      _useWideScreen(tester);
      final notes = InMemoryNoteRepository(<Note>[
        Note.create(title: '第一篇', content: 'a'),
        Note.create(title: '第二篇', content: 'b'),
      ]);
      final settings = await _createSettingsController();
      await tester.pumpWidget(
        ArgonoteApp(
          noteRepository: notes,
          notebookRepository: InMemoryNotebookRepository(),
          settingsController: settings,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('第一篇'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('第二篇'));
      await tester.pumpAndSettle();

      // 标签条上两篇都在（列表里也有同名标题，用 findsWidgets 放宽）
      expect(find.text('第一篇'), findsWidgets);
      expect(find.text('第二篇'), findsWidgets);

      // 关闭当前标签 → 回到第一篇仍显示标题字段
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('第二篇'), findsOneWidget); // 只剩列表条目

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noteTitleField')), findsNothing);
    });

    testWidgets('快捷键：Ctrl+N 新建标签、Ctrl+Tab 切换、Ctrl+W 关闭', (WidgetTester tester) async {
      _useWideScreen(tester);
      final notes = InMemoryNoteRepository(<Note>[
        Note.create(title: '第一篇', content: 'a'),
      ]);
      final settings = await _createSettingsController();
      await tester.pumpWidget(
        ArgonoteApp(
          noteRepository: notes,
          notebookRepository: InMemoryNotebookRepository(),
          settingsController: settings,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('第一篇'));
      await tester.pumpAndSettle();
      // 列表一条 + 编辑器标题字段一处
      expect(find.text('第一篇'), findsNWidgets(2));

      await _press(tester, LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();
      // 切到了新建的空白标签，编辑器里不再有「第一篇」
      expect(find.text('第一篇'), findsOneWidget);
      expect(find.byKey(const Key('noteTitleField')), findsOneWidget);

      await _press(tester, LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text('第一篇'), findsNWidgets(2));

      await _press(tester, LogicalKeyboardKey.keyW);
      await tester.pumpAndSettle();
      await _press(tester, LogicalKeyboardKey.keyW);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noteTitleField')), findsNothing);
      // 空白草稿不会被保存成一条笔记
      expect((await notes.all()).length, 1);
    });

    testWidgets('删除进回收站，可在回收站还原', (WidgetTester tester) async {
      _useWideScreen(tester);
      final notes = InMemoryNoteRepository(<Note>[
        Note.create(title: '待删笔记', content: 'x'),
      ]);
      final settings = await _createSettingsController();
      await tester.pumpWidget(
        ArgonoteApp(
          noteRepository: notes,
          notebookRepository: InMemoryNotebookRepository(),
          settingsController: settings,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      var saved = (await notes.all()).single;
      expect(saved.trashed, isTrue);
      expect(find.text('待删笔记'), findsNothing);

      // 进入回收站视图并还原
      await tester.tap(find.text('回收站'));
      await tester.pumpAndSettle();
      expect(find.text('待删笔记'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('还原'));
      await tester.pumpAndSettle();
      saved = (await notes.all()).single;
      expect(saved.trashed, isFalse);
    });

    testWidgets('预览模式渲染 Markdown 与双链', (WidgetTester tester) async {
      _useWideScreen(tester);
      final notes = InMemoryNoteRepository(<Note>[
        Note.create(title: '目标页', content: '到达'),
        Note.create(title: '索引', content: '# 大标题\n\n参考 [[目标页]]'),
      ]);
      final settings = await _createSettingsController();
      await tester.pumpWidget(
        ArgonoteApp(
          noteRepository: notes,
          notebookRepository: InMemoryNotebookRepository(),
          settingsController: settings,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('索引'));
      await tester.pumpAndSettle();
      expect(find.byType(MarkdownBody), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(MarkdownBody), findsOneWidget);
    });
  });

  group('窄屏回退', () {
    testWidgets('点笔记整屏进编辑器，返回键回列表', (WidgetTester tester) async {
      _useNarrowScreen(tester);
      final notes = InMemoryNoteRepository(<Note>[
        Note.create(title: '窄屏笔记', content: 'a'),
      ]);
      final settings = await _createSettingsController();
      await tester.pumpWidget(
        ArgonoteApp(
          noteRepository: notes,
          notebookRepository: InMemoryNotebookRepository(),
          settingsController: settings,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('窄屏笔记'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noteContentField')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noteContentField')), findsNothing);
    });
  });

  group('搜索与语言', () {
    testWidgets('搜索按标题和正文过滤', (WidgetTester tester) async {
      _useWideScreen(tester);
      final notes = InMemoryNoteRepository(<Note>[
        Note.create(title: '会议纪要', content: '下周一上线'),
        Note.create(title: '购物清单', content: '牛奶、鸡蛋'),
      ]);
      final settings = await _createSettingsController();
      await tester.pumpWidget(
        ArgonoteApp(
          noteRepository: notes,
          notebookRepository: InMemoryNotebookRepository(),
          settingsController: settings,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '鸡蛋');
      await tester.pumpAndSettle();
      expect(find.text('购物清单'), findsOneWidget);
      expect(find.text('会议纪要'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '不存在');
      await tester.pumpAndSettle();
      expect(find.text('没有匹配的笔记'), findsOneWidget);
    });

    testWidgets('设置页切换语言后立即生效', (WidgetTester tester) async {
      _useWideScreen(tester);
      final settings = await _createSettingsController();
      await tester.pumpWidget(
        ArgonoteApp(
          noteRepository: InMemoryNoteRepository(),
          notebookRepository: InMemoryNotebookRepository(),
          settingsController: settings,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('All notes'), findsOneWidget);
      expect(settings.settings.language, AppLanguage.english);
    });
  });
}
