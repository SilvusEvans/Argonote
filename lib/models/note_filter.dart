import 'package:argonote/models/note.dart';

/// 列表页的筛选条件：文件夹 + 标签 + 关键词。
///
/// 单独抽成模型，方便单元测试直接验证筛选逻辑，不用起 Widget。
class NoteFilter {
  const NoteFilter({
    this.folderId,
    this.unfiledOnly = false,
    this.tag,
    this.keyword = '',
  });

  /// 指定文件夹；null 表示不按文件夹筛选。
  final String? folderId;

  /// 只看「未归类」的笔记。
  final bool unfiledOnly;

  /// 只看带某个标签的笔记；null 表示不按标签筛选。
  final String? tag;

  /// 关键词，标题 / 正文 / 标签不区分大小写匹配。
  final String keyword;

  static const NoteFilter empty = NoteFilter();

  bool get isEmpty =>
      folderId == null && !unfiledOnly && (tag == null || tag!.isEmpty) && keyword.trim().isEmpty;

  NoteFilter copyWith({
    Object? folderId = _sentinel,
    bool? unfiledOnly,
    Object? tag = _sentinel,
    String? keyword,
  }) {
    return NoteFilter(
      folderId: identical(folderId, _sentinel) ? this.folderId : folderId as String?,
      unfiledOnly: unfiledOnly ?? this.unfiledOnly,
      tag: identical(tag, _sentinel) ? this.tag : tag as String?,
      keyword: keyword ?? this.keyword,
    );
  }

  /// 判断一条笔记是否命中当前筛选条件。
  bool matches(Note note) {
    if (!_matchesFolder(note)) return false;
    if (!_matchesTag(note)) return false;
    return _matchesKeyword(note);
  }

  bool _matchesFolder(Note note) {
    if (unfiledOnly) return note.folderId == null;
    if (folderId == null) return true;
    return note.folderId == folderId;
  }

  bool _matchesTag(Note note) {
    final filterTag = tag;
    if (filterTag == null || filterTag.isEmpty) return true;
    return note.tags.contains(filterTag);
  }

  bool _matchesKeyword(Note note) {
    final trimmed = keyword.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    return note.title.toLowerCase().contains(trimmed) ||
        note.content.toLowerCase().contains(trimmed) ||
        note.tags.any((item) => item.toLowerCase().contains(trimmed));
  }

  /// 从一批笔记里收集全部标签（去重、按字典序），供筛选栏展示。
  static List<String> collectTags(Iterable<Note> notes) {
    final tags = <String>{};
    for (final note in notes) {
      tags.addAll(note.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }
}

const Object _sentinel = Object();
