import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:argonote/app.dart';
import 'package:argonote/data/in_memory_folder_repository.dart';
import 'package:argonote/data/in_memory_note_repository.dart';
import 'package:argonote/data/in_memory_settings_repository.dart';
import 'package:argonote/l10n/app_strings.dart';
import 'package:argonote/models/note.dart';
import 'package:argonote/settings/settings_controller.dart';

Future<SettingsController> _createSettingsController() async {
  final controller = SettingsController(InMemorySettingsRepository());
  await controller.load();
  return controller;
}

void main() {
  testWidgets('空状态 → 新建 → 编辑 → 侧滑删除 全流程', (WidgetTester tester) async {
    final repository = InMemoryNoteRepository();
    final folderRepository = InMemoryFolderRepository();
    final settings = await _createSettingsController();

    await tester.pumpWidget(
      ArgonoteApp(
        repository: repository,
        folderRepository: folderRepository,
        settingsController: settings,
      ),
    );
    await tester.pumpAndSettle();

    // 1. 空状态
    expect(find.text('还没有笔记'), findsOneWidget);

    // 2. 新建
    await tester.tap(find.text('写笔记'));
    await tester.pumpAndSettle();
    expect(find.text('新建笔记'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('noteTitleField')), '购物清单');
    await tester.enterText(find.byKey(const Key('noteContentField')), '牛奶、鸡蛋');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('购物清单'), findsOneWidget);
    expect(await repository.all(), hasLength(1));

    // 3. 编辑（改标题后保存）
    await tester.tap(find.text('购物清单'));
    await tester.pumpAndSettle();
    expect(find.text('编辑笔记'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('noteTitleField')), '周末采购');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('周末采购'), findsOneWidget);
    expect(find.text('购物清单'), findsNothing);

    // 4. 侧滑删除 + 二次确认
    await tester.drag(find.byType(Dismissible).first, const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('删除笔记'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.text('周末采购'), findsNothing);
    expect(await repository.all(), isEmpty);
    expect(find.text('还没有笔记'), findsOneWidget);
  });

  testWidgets('搜索按标题和正文过滤', (WidgetTester tester) async {
    final repository = InMemoryNoteRepository(<Note>[
      Note.create(title: '会议纪要', content: '下周一上线'),
      Note.create(title: '购物清单', content: '牛奶、鸡蛋'),
    ]);
    final settings = await _createSettingsController();

    await tester.pumpWidget(
      ArgonoteApp(
        repository: repository,
        folderRepository: InMemoryFolderRepository(),
        settingsController: settings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('会议纪要'), findsOneWidget);
    expect(find.text('购物清单'), findsOneWidget);

    // 命中标题
    await tester.enterText(find.byType(TextField).first, '会议');
    await tester.pumpAndSettle();
    expect(find.text('会议纪要'), findsOneWidget);
    expect(find.text('购物清单'), findsNothing);

    // 命中正文
    await tester.enterText(find.byType(TextField).first, '鸡蛋');
    await tester.pumpAndSettle();
    expect(find.text('购物清单'), findsOneWidget);
    expect(find.text('会议纪要'), findsNothing);

    // 无匹配时的空态
    await tester.enterText(find.byType(TextField).first, '不存在');
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的笔记'), findsOneWidget);
  });

  testWidgets('可以按文件夹和标签筛选', (WidgetTester tester) async {
    final folderRepository = InMemoryFolderRepository();
    final folder = await folderRepository.create('工作');

    final repository = InMemoryNoteRepository(<Note>[
      Note.create(
        title: '周报',
        content: '本周进展',
        tags: const <String>['日报'],
        folderId: folder.id,
      ),
      Note.create(title: '菜谱', content: '番茄炒蛋', tags: const <String>['生活']),
    ]);
    final settings = await _createSettingsController();

    await tester.pumpWidget(
      ArgonoteApp(
        repository: repository,
        folderRepository: folderRepository,
        settingsController: settings,
      ),
    );
    await tester.pumpAndSettle();

    // 按文件夹筛选。
    // 注意：列表项上也有一个写着文件夹名的徽章，find.text('工作') 会同时命中两处，
    // 所以这里限定成筛选栏里的 FilterChip。
    await tester.tap(find.widgetWithText(FilterChip, '工作'));
    await tester.pumpAndSettle();
    expect(find.text('周报'), findsOneWidget);
    expect(find.text('菜谱'), findsNothing);

    // 回到全部，再按标签筛选
    await tester.tap(find.widgetWithText(FilterChip, '全部'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '生活'));
    await tester.pumpAndSettle();
    expect(find.text('菜谱'), findsOneWidget);
    expect(find.text('周报'), findsNothing);
  });

  testWidgets('编辑页可以预览 Markdown', (WidgetTester tester) async {
    final repository = InMemoryNoteRepository(<Note>[
      Note.create(
        title: 'Markdown',
        content: '# 标题\n\n- 第一项\n\n| a | b |\n| - | - |\n| 1 | 2 |',
      ),
    ]);
    final settings = await _createSettingsController();

    await tester.pumpWidget(
      ArgonoteApp(
        repository: repository,
        folderRepository: InMemoryFolderRepository(),
        settingsController: settings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Markdown'));
    await tester.pumpAndSettle();

    // 默认是编辑页签
    expect(find.byType(MarkdownBody), findsNothing);

    await tester.tap(find.text('预览'));
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownBody), findsOneWidget);
  });

  testWidgets('设置页切换语言后立即生效', (WidgetTester tester) async {
    final repository = InMemoryNoteRepository();
    final settings = await _createSettingsController();

    await tester.pumpWidget(
      ArgonoteApp(
        repository: repository,
        folderRepository: InMemoryFolderRepository(),
        settingsController: settings,
      ),
    );
    await tester.pumpAndSettle();

    // 进入设置页
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsWidgets);

    // 切换到 English
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // 返回列表页，文案应已变成英文
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('New note'), findsOneWidget);
    expect(settings.settings.language, AppLanguage.english);
  });
}
