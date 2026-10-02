import 'package:flutter/widgets.dart';

import 'note.dart';

/// 编辑器一个标签页的运行时状态。
///
/// 控制器由标签自己持有：切换标签时编辑器用 IndexedStack 保活，
/// 未保存的草稿不会因为切走而丢失；关闭标签才 dispose。
class NoteTab {
  NoteTab({
    required this.id,
    this.note,
    String title = '',
    String content = '',
    List<String> tags = const <String>[],
    this.sectionId,
    this.pinned = false,
  })  : titleController = TextEditingController(text: title),
        contentController = TextEditingController(text: content),
        tags = <String>[...tags];

  /// 稳定 id：已保存笔记用 note.id，草稿用 draft-* 序号。
  final String id;

  /// 已落库的笔记；null 表示还没保存过的新建。
  Note? note;

  final TextEditingController titleController;
  final TextEditingController contentController;

  List<String> tags;
  String? sectionId;
  bool pinned;

  /// 有未落库的修改。
  bool dirty = false;

  bool get isPersisted => note != null;

  String get label {
    final title = titleController.text.trim();
    return title.isEmpty ? '' : title;
  }

  static int _draftSequence = 0;

  static String nextDraftId() => 'draft-${DateTime.now().microsecondsSinceEpoch}-${++_draftSequence}';

  void fillFromNote(Note source) {
    note = source;
    titleController.text = source.title;
    contentController.text = source.content;
    tags = <String>[...source.tags];
    sectionId = source.sectionId;
    pinned = source.pinned;
    dirty = false;
  }

  void dispose() {
    titleController.dispose();
    contentController.dispose();
  }
}
