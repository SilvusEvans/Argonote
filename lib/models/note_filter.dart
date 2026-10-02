import 'note.dart';

/// 列表页的排序方式。
enum NoteSort {
  updatedAtDesc('updated'),
  createdAtDesc('created'),
  titleAsc('title');

  const NoteSort(this.code);
  final String code;

  static NoteSort fromCode(String? code) {
    for (final value in NoteSort.values) {
      if (value.code == code) return value;
    }
    return NoteSort.updatedAtDesc;
  }
}

/// 列表的树形选择范围：全部 / 某笔记本 / 某笔记本的未分区 / 某分区组 / 某分区 / 归档 / 置顶。
///
/// 与 [NoteFilter]（关键词 / 标签 / 排序）叠加使用。
class NoteScope {
  const NoteScope._(this.kind, this.id);

  final NoteScopeKind kind;

  /// kind 需要附加 id 时的目标 id（笔记本 / 分区组 / 分区）。
  final String? id;

  static const NoteScope all = NoteScope._(NoteScopeKind.all, null);
  static const NoteScope pinned = NoteScope._(NoteScopeKind.pinned, null);
  static const NoteScope archived = NoteScope._(NoteScopeKind.archived, null);

  const NoteScope.section(String sectionId) : this._(NoteScopeKind.section, sectionId);
  const NoteScope.notebook(String notebookId) : this._(NoteScopeKind.notebook, notebookId);
  const NoteScope.group(String groupId) : this._(NoteScopeKind.group, groupId);

  /// 某个笔记本下「没有分区」的那批笔记，id 是笔记本 id。
  const NoteScope.unsectioned(String notebookId)
      : this._(NoteScopeKind.unsectioned, notebookId);
}

enum NoteScopeKind { all, pinned, archived, section, unsectioned, notebook, group }

/// 列表页的筛选条件：关键词 + 标签 + 排序。
///
/// 单独抽成模型，方便单元测试直接验证筛选逻辑，不用起 Widget。
class NoteFilter {
  const NoteFilter({
    this.tag,
    this.keyword = '',
    this.sort = NoteSort.updatedAtDesc,
  });

  /// 只看带某个标签的笔记；null 表示不按标签筛选。
  final String? tag;

  /// 关键词，标题 / 正文 / 标签不区分大小写匹配。
  final String keyword;

  /// 排序方式（置顶项永远排在最前，此字段决定其余部分的顺序）。
  final NoteSort sort;

  static const NoteFilter empty = NoteFilter();

  bool get isEmpty => (tag == null || tag!.isEmpty) && keyword.trim().isEmpty;

  NoteFilter copyWith({
    Object? tag = _sentinel,
    String? keyword,
    NoteSort? sort,
  }) {
    return NoteFilter(
      tag: identical(tag, _sentinel) ? this.tag : tag as String?,
      keyword: keyword ?? this.keyword,
      sort: sort ?? this.sort,
    );
  }

  /// 判断一条笔记是否命中当前筛选条件（不含范围/归档过滤）。
  bool matches(Note note) {
    if (!_matchesTag(note)) return false;
    return _matchesKeyword(note);
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

  /// 先按范围/筛选过滤，再排序：置顶优先，其余按 [sort]。
  ///
  /// [groupSectionIds] 只在分区组范围下用到（组内所有分区 id）。
  List<Note> apply(List<Note> notes, NoteScope scope, {Set<String>? groupSectionIds}) {
    final result = <Note>[];
    for (final note in notes) {
      if (_matchesScope(note, scope, groupSectionIds) && matches(note)) {
        result.add(note);
      }
    }
    result.sort(_compare);
    return result;
  }

  bool _matchesScope(Note note, NoteScope scope, Set<String>? groupSectionIds) {
    switch (scope.kind) {
      case NoteScopeKind.archived:
        return note.archived;
      case NoteScopeKind.pinned:
        if (note.archived) return false;
        return note.pinned;
      case NoteScopeKind.all:
        return !note.archived;
      case NoteScopeKind.section:
        return !note.archived && note.sectionId == scope.id;
      case NoteScopeKind.unsectioned:
        return !note.archived && note.notebookId == scope.id && note.sectionId == null;
      case NoteScopeKind.notebook:
        return !note.archived && note.notebookId == scope.id;
      case NoteScopeKind.group:
        return !note.archived &&
            note.sectionId != null &&
            (groupSectionIds?.contains(note.sectionId) ?? false);
    }
  }

  int _compare(Note a, Note b) {
    // 置顶永远优先。
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    switch (sort) {
      case NoteSort.updatedAtDesc:
        return b.updatedAt.compareTo(a.updatedAt);
      case NoteSort.createdAtDesc:
        return b.createdAt.compareTo(a.createdAt);
      case NoteSort.titleAsc:
        final byTitle = a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase());
        if (byTitle != 0) return byTitle;
        return b.updatedAt.compareTo(a.updatedAt);
    }
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
