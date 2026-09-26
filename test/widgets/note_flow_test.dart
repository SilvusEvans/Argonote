import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:argonote/app.dart';
import 'package:argonote/data/in_memory_note_repository.dart';
import 'package:argonote/models/note.dart';

void main() {
  testWidgets('空状态 → 新建 → 编辑 → 侧滑删除 全流程', (WidgetTester tester) async {
    final repository = InMemoryNoteRepository();

    await tester.pumpWidget(ArgonoteApp(repository: repository));
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

    await tester.pumpWidget(ArgonoteApp(repository: repository));
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
}
