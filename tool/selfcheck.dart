// 纯逻辑层自检脚本（模型 / 筛选 / 文本工具 / 内存仓储）。
//
// 这台机器上 `flutter test` 跑不起来（回环 TCP 被防火墙拦掉），所以留了这个
// 不依赖 Flutter 运行时的入口：`dart run tool/selfcheck.dart`，用退出码表示结果。
// Widget 测试仍然写在 test/ 里，能在正常环境跑的机器上照常用。
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:argonote/data/in_memory_note_repository.dart';
import 'package:argonote/data/in_memory_notebook_repository.dart';
import 'package:argonote/models/note.dart';
import 'package:argonote/models/note_filter.dart';
import 'package:argonote/models/notebook.dart';
import 'package:argonote/utils/markdown_plain.dart';
import 'package:argonote/utils/markdown_tools.dart';
import 'package:characters/characters.dart';

int _total = 0;
int _failed = 0;

void check(String name, bool condition) {
  _total++;
  if (condition) {
    print('PASS  $name');
  } else {
    _failed++;
    print('FAIL  $name');
    exitCode = 1;
  }
}

bool hasLoneSurrogate(String text) {
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      if (i + 1 >= text.length) return true;
      final next = text.codeUnitAt(i + 1);
      if (next < 0xDC00 || next > 0xDFFF) return true;
      i++;
    } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
      return true;
    }
  }
  return false;
}

Note note(
  String id, {
  String title = '',
  String content = '',
  List<String> tags = const <String>[],
  String? notebookId,
  String? sectionId,
  bool pinned = false,
  bool archived = false,
  int day = 1,
}) {
  final stamp = DateTime(2026, 1, day);
  return Note(
    id: id,
    title: title,
    content: content,
    createdAt: stamp,
    updatedAt: stamp,
    tags: tags,
    notebookId: notebookId,
    sectionId: sectionId,
    pinned: pinned,
    archived: archived,
    deletedAt: archived ? stamp : null,
  );
}

List<String> idsOf(List<Note> notes) => notes.map((note) => note.id).toList();

Future<void> main() async {
  // ---- A. 字符显示：字素安全 ----
  const familyCodes = [
    0xD83D, 0xDC68, 0x200D, 0xD83D, 0xDC69, //
    0x200D, 0xD83D, 0xDC67, 0x200D, 0xD83D, 0xDC66,
  ];
  const flagCodes = [0xD83C, 0xDDE8, 0xD83C, 0xDDF3];
  final family = String.fromCharCodes(familyCodes);
  final flag = String.fromCharCodes(flagCodes);

  final emojiNote = note('e1', content: '$family' 'x');
  check('A1 家庭 emoji + x 共 2 个字素', emojiNote.graphemeCount == 2);
  check('A1b 家庭 emoji 本身是 1 个字素', note('e1b', content: family).graphemeCount == 1);

  check('A2 国旗 emoji 算 1 个字素', note('e2', content: flag).graphemeCount == 1);

  final combining = note('e3', content: 'e\u0301');
  check('A3 组合附加符算 1 个字素', combining.graphemeCount == 1);

  final longEmoji = '${family * 30}中文结尾';
  final preview = plainTextFromMarkdown(longEmoji, maxLength: 5);
  check('A4 摘要截断不产生孤立代理对', !hasLoneSurrogate(preview));
  check('A5 摘要截断不含替换字符 U+FFFD', !preview.contains('\uFFFD'));

  final cjkPreview = plainTextFromMarkdown('# 标题\n\n**加粗** 与 `代码` 混排，内容较长。' * 4, maxLength: 12);
  check('A6 Markdown 标记被剥离', !cjkPreview.contains('**') && !cjkPreview.contains('`'));
  check('A7 中文摘要截断安全', cjkPreview.characters.length <= 13 && !hasLoneSurrogate(cjkPreview));

  final mixed = note('e4', content: '${String.fromCharCodes([0xD83D, 0xDE00])} emoji 与中文文本 hello world');
  check('A8 截断 emoji 开头文本安全',
      !hasLoneSurrogate(plainTextFromMarkdown(mixed.content, maxLength: 1)));
  check('A9 字数统计中英混排', note('e5', content: '你好 world').wordCount == 3);
  check('A10 字数统计纯英文', note('e6', content: 'hello world').wordCount == 2);

  // 工具栏编辑：选区端点落在代理对中间时也不能造出孤立代理对，
  // 否则写回文本框就是一块 U+FFFD，正是"字符有时显示不出来"的那条路径。
  final grin = String.fromCharCodes([0xD83D, 0xDE00]); // 😀 占 2 个 code unit
  final emojiText = '前$grin后'; // 字素边界：0 / 1 / 3 / 4
  final caretWrap = wrapSelection(emojiText, 2, 2, before: '**', after: '**');
  check('A11 光标落在半截 emoji 内包裹不切碎字形',
      !hasLoneSurrogate(caretWrap.text) &&
          caretWrap.text == '前****$grin后' &&
          caretWrap.start == 3 &&
          caretWrap.end == 3);

  final dragWrap = wrapSelection(emojiText, 2, 3, before: '*', after: '*');
  check('A12 半截选区向外扩成完整 emoji',
      !hasLoneSurrogate(dragWrap.text) && dragWrap.text == '前*$grin*后');

  final familyWrap = wrapSelection('a$family' 'b', 3, 4, before: '_', after: '_');
  check('A13 ZWJ 组合 emoji 整体包裹',
      !hasLoneSurrogate(familyWrap.text) && familyWrap.text == 'a_${family}_b');

  final blockInsert = insertBlock(emojiText, 2, 2, '- 条目');
  check('A14 半截光标处插入块不吞字',
      !hasLoneSurrogate(blockInsert.text) && blockInsert.text.contains(grin));
  check('A15 插入结果自身无孤立代理对', !hasLoneSurrogate(blockInsert.text.substring(
      blockInsert.start, blockInsert.end)));

  // ---- B. JSON 兼容与往返 ----
  final legacy = Note.fromJson(<String, dynamic>{
    'id': 'l1',
    'title': '旧数据',
    'content': 'c',
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-02T00:00:00.000Z',
    'folderId': 'f9',
  });
  check('B1 旧 folderId 读作 sectionId', legacy.sectionId == 'f9');

  final both = Note.fromJson(<String, dynamic>{
    'id': 'l2',
    'sectionId': 's1',
    'folderId': 'f9',
  });
  check('B2 sectionId 优先于 folderId', both.sectionId == 's1');

  final dirty = Note.fromJson(<String, dynamic>{'id': 'l3', 'tags': <dynamic>['a', 1, '', ' b ']});
  check('B3 脏 tags 被清洗', dirty.tags.length == 2 && dirty.tags.last == 'b');

  final roundTrip = Note.fromJson(note('r1', title: 'T', content: 'C', tags: const ['x'],
          sectionId: 's7', pinned: true).toJson());
  check('B4 往返保留分区/置顶', roundTrip.sectionId == 's7' && roundTrip.pinned);
  check('B5 往返保留正文与标题', roundTrip.title == 'T' && roundTrip.content == 'C');

  // ---- C. 文本工具（工具栏 / 双链） ----
  final bolded = wrapSelection('abc', 0, 3, before: '**', after: '**');
  check('C1 包裹选区', bolded.text == '**abc**' && bolded.start == 0 && bolded.end == 7);
  final unbolded = wrapSelection(bolded.text, bolded.start, bolded.end, before: '**', after: '**');
  check('C2 再次点击剥离（切换语义）', unbolded.text == 'abc');

  final headed = wrapSelection('', 0, 0, before: '# ', placeholder: '标题');
  check('C3 空选区插入占位并把光标放到中间', headed.text == '# 标题' && headed.start == 2 && headed.end == 4);

  final stripHeading = prefixLines('# 已加标题', 0, 6, prefix: '# ');
  check('C4 行首前缀剥离', stripHeading.text == '已加标题');
  final addPrefix = prefixLines('一\n二\n三', 0, 5, prefix: '- ');
  check('C5 多行加前缀', addPrefix.text == '- 一\n- 二\n- 三');
  final task = prefixLines('任务', 0, 2, prefix: '- [ ] ');
  check('C6 任务列表前缀', task.text == '- [ ] 任务');

  final withTable = insertBlock('abc', 3, 3, tableBlock);
  check('C7 行中插入表格块自动补前导空行', withTable.text == 'abc\n$tableBlock');
  final midBlock = insertBlock('ab\ncd', 3, 3, 'X');
  check('C8 行首插入块自动补尾随空行', midBlock.text == 'ab\nX\ncd');

  final wikified = preprocessWikiLinks('参见 [[研究 笔记]] 与 [[无 空格]] 两次 [[研究 笔记]]');
  check('C9 双链转换数量', '研究 笔记'.isNotEmpty && RegExp(r'\]\(note://').allMatches(wikified).length == 3);
  final target = wikiLinkTarget(RegExp(r'note://([^\)]+)').firstMatch(wikified)!.group(0)!);
  check('C10 双链目标解码还原中文标题', target == '研究 笔记');
  check('C11 非双链 href 返回 null', wikiLinkTarget('https://example.com') == null);
  check('C12 已转换文本不再含方括号语法', !wikified.contains('[['));

  final hardBreak = applySoftLineBreaks('第一行\n第二行');
  check('C13 单换行补成 Markdown 硬换行', hardBreak == '第一行  \n第二行');
  check('C14 硬换行处理可重复执行', applySoftLineBreaks(hardBreak) == hardBreak);
  check('C15 空行不补，保留段落分隔', applySoftLineBreaks('甲\n\n乙') == '甲\n\n乙');
  check('C16 引用块内照样断行', applySoftLineBreaks('> 引一\n> 引二') == '> 引一  \n> 引二');
  check('C17 围栏代码块内部原样保留',
      applySoftLineBreaks('```\na\nb\n```') == '```\na\nb\n```');
  check('C18 块级语法相邻行不补',
      applySoftLineBreaks('正文\n- 项目') == '正文\n- 项目' &&
          applySoftLineBreaks('# 标题\n正文') == '# 标题\n正文');

  // ---- D. 范围筛选与排序 ----
  final pool = <Note>[
    note('n1', title: 'B', content: 'k', tags: const ['x'], notebookId: 'nb1', sectionId: 's1', day: 2),
    note('n2', title: 'A', notebookId: 'nb1', sectionId: 's2', pinned: true, day: 1),
    note('n3', title: 'c', notebookId: 'nb2', day: 3),
    note('n4', title: 'D', notebookId: 'nb1', sectionId: 's1', archived: true, day: 4),
  ];
  const filter = NoteFilter.empty;
  check('D1 全部范围排除归档',
      idsOf(filter.apply(pool, NoteScope.all)).toSet().difference({'n4'}).length == 3 &&
          !idsOf(filter.apply(pool, NoteScope.all)).contains('n4'));
  check('D2 置顶永远排最前', filter.apply(pool, NoteScope.all).first.id == 'n2');
  check('D3 默认按更新时间倒序',
      idsOf(filter.apply(pool, NoteScope.all)) .sublist(1) .join(',') == 'n3,n1');
  check('D4 归档范围', idsOf(filter.apply(pool, NoteScope.archived)).join(',') == 'n4');
  check('D5 置顶范围', idsOf(filter.apply(pool, NoteScope.pinned)).join(',') == 'n2');
  check('D6 置顶范围排除已归档',
      idsOf(filter.apply(<Note>[...pool, note('n5', title: 'E', pinned: true, archived: true, day: 5)],
              NoteScope.pinned))
          .join(',') ==
      'n2');
  check('D7 分区范围', idsOf(filter.apply(pool, const NoteScope.section('s1'))).join(',') == 'n1');
  check('D8 笔记本范围按 notebookId',
      idsOf(filter.apply(pool, const NoteScope.notebook('nb1'))).toSet().difference({'n1', 'n2'})
          .isEmpty);
  check('D9 分区组范围',
      idsOf(filter.apply(pool, const NoteScope.group('g1'), groupSectionIds: const {'s1'}))
          .join(',') == 'n1');
  check('D10 未分区范围只收无分区笔记',
      idsOf(filter.apply(pool, const NoteScope.unsectioned('nb2'))).join(',') == 'n3');
  check('D11 关键词大小写不敏感',
      idsOf(const NoteFilter(keyword: 'b').apply(pool, NoteScope.all)).join(',') == 'n1');
  check('D12 关键词命中正文',
      idsOf(const NoteFilter(keyword: 'K').apply(pool, NoteScope.all)).join(',') == 'n1');
  check('D13 标签筛选',
      idsOf(const NoteFilter(tag: 'x').apply(pool, NoteScope.all)).join(',') == 'n1');
  check('D14 关键词与标签叠加', const NoteFilter(keyword: 'z', tag: 'x').apply(pool, NoteScope.all).isEmpty);
  check('D15 标题排序忽略大小写',
      idsOf(const NoteFilter(sort: NoteSort.titleAsc).apply(pool, NoteScope.all))
          .join(',') == 'n2,n1,n3');
  check('D16 创建时间排序可用（置顶仍在前）',
      idsOf(const NoteFilter(sort: NoteSort.createdAtDesc).apply(pool, NoteScope.all))
          .join(',') == 'n2,n3,n1');
  check('D17 标签收集去重排序',
      NoteFilter.collectTags(pool).join(',') == 'x');
  check('D18 copyWith 保留未传字段', const NoteFilter(tag: 't').copyWith(keyword: 'k').tag == 't');
  check('D19 copyWith 显式清空标签', const NoteFilter(tag: 't').copyWith(tag: null).tag == null);
  check('D20 sort 代码往返', NoteSort.fromCode('title') == NoteSort.titleAsc &&
      NoteSort.fromCode('nope') == NoteSort.updatedAtDesc);

  // ---- E. 笔记仓储行为 ----
  final repo = InMemoryNoteRepository(pool);
  final created = await repo.create(
      title: '新页', content: '正文', tags: const ['t'], notebookId: 'nb1', sectionId: 's1');
  check('E1 新建后能查到', (await repo.findById(created.id))?.title == '新页');
  check('E2 新建携带归属', created.sectionId == 's1' && created.notebookId == 'nb1');
  final updated = await repo.update(
      id: created.id,
      title: '改名',
      content: '正文2',
      tags: const <String>[],
      notebookId: 'nb1',
      sectionId: 's2');
  check('E3 更新保留分区', updated.sectionId == 's2' && updated.title == '改名');
  check('E4 连续保存的时间戳严格递增', updated.updatedAt.isAfter(created.updatedAt));
  final unpinned = await repo.setPinned(updated.id, true);
  check('E5 置顶不刷新 updatedAt', unpinned.updatedAt == updated.updatedAt && unpinned.pinned);
  final unfiled = await repo.update(
      id: updated.id,
      title: '改名',
      content: '正文2',
      tags: const <String>[],
      notebookId: 'nb1',
      sectionId: null);
  check('E6 显式 null 分区即移出', unfiled.sectionId == null && unfiled.notebookId == 'nb1');
  final archived = await repo.archiveNote(updated.id);
  check('E7 软删除标记与时间', archived.archived && archived.deletedAt != null);
  check('E8 软删除后仍在 all() 中', (await repo.all()).any((item) => item.id == updated.id));
  final restored = await repo.unarchiveNote(updated.id);
  check('E9 还原清空 deletedAt', !restored.archived && restored.deletedAt == null);
  await repo.delete(updated.id);
  check('E10 彻底删除后查不到', await repo.findById(updated.id) == null);
  await repo.restore(note('ghost', title: '撤销恢复', day: 5));
  check('E11 撤销恢复重新写回', (await repo.findById('ghost'))?.title == '撤销恢复');
  await repo.moveNotesToNotebook(const ['n1', 'n4'], 'nb2');
  final afterMove = await repo.all();
  Note pick(String id) => afterMove.where((item) => item.id == id).single;
  check('E12 笔记本被删时笔记并入指定笔记本', pick('n1').notebookId == 'nb2');
  check('E13 并入同时清空分区', pick('n1').sectionId == null);
  check('E14 并入不刷新更新时间', pick('n1').updatedAt == DateTime(2026, 1, 2));
  check('E15 归档中的笔记同样并入', pick('n4').notebookId == 'nb2' && pick('n4').archived);
  check('E16 清单外的笔记不受影响', pick('n2').notebookId == 'nb1');
  await repo.clearNoteSections(const ['n2', 'ghost']);
  final afterClear = await repo.all();
  check('E17 清分区保留笔记本',
      afterClear.where((item) => item.id == 'n2').single.notebookId == 'nb1' &&
          afterClear.where((item) => item.id == 'n2').single.sectionId == null);
  check('E18 无分区的笔记执行清分区仍然无分区',
      afterClear.where((item) => item.id == 'ghost').single.sectionId == null);
  final blank = await repo.create(title: '', content: '', notebookId: 'nb1');
  check('E19 空白笔记判定', blank.isBlank);
  check('E20 id 微秒级也不重复',
      (await repo.create(title: 'a', content: '')).id != (await repo.create(title: 'b', content: '')).id);

  // ---- F. 笔记本仓储层级动作 ----
  final nb = InMemoryNotebookRepository();
  final book = await nb.createNotebook('研究');
  final group = await nb.createSectionGroup(book.id, '2026');
  final secIn = await nb.createSection(book.id, '文献', groupId: group.id);
  final secOut = await nb.createSection(book.id, '速记');
  check('F1 创建笔记本/分区组/分区',
      (await nb.notebooks()).length == 1 &&
          (await nb.sectionGroups()).length == 1 &&
          (await nb.sections()).length == 2);
  final renamed = await nb.renameSection(secOut.id, '速记本');
  check('F2 重命名分区', renamed.name == '速记本');
  final moved = await nb.moveSection(secOut.id, book.id, groupId: group.id);
  check('F3 分区移入分区组', moved.groupId == group.id && moved.notebookId == book.id);
  final movedOut = await nb.moveSection(secOut.id, book.id);
  check('F4 分区移出分区组', movedOut.groupId == null);
  await nb.deleteSectionGroup(group.id);
  check('F5 删除分区组后其分区变为游离',
      (await nb.sectionGroups()).isEmpty &&
          (await nb.sections()).where((s) => s.id == secIn.id).single.groupId == null);
  final orphanSections = await nb.deleteNotebook(book.id);
  check('F6 删除笔记本返回其分区 id', orphanSections.containsAll({secIn.id, secOut.id}));
  check('F7 笔记本内容被清空',
      (await nb.notebooks()).isEmpty && (await nb.sections()).isEmpty);
  await nb.deleteSection('ghost-section');
  check('F8 删除不存在分区不抛异常', (await nb.sections()).isEmpty);

  // ---- G. 模型 id 唯一性（时钟精度兜底） ----
  final batch = <String>{for (var i = 0; i < 50; i++) Notebook.create('n$i').id};
  check('G1 连续创建笔记本 id 不重复', batch.length == 50);
  final noteIds = <String>{for (var i = 0; i < 50; i++) Note.create(title: 't$i').id};
  check('G2 连续创建笔记 id 不重复', noteIds.length == 50);
  final sectionIds = <String>{
    for (var i = 0; i < 50; i++) Section.create(notebookId: 'nb', name: 's$i').id
  };
  check('G3 连续创建分区 id 不重复', sectionIds.length == 50);

  print('\n$_total checks, $_failed failed.');
}
