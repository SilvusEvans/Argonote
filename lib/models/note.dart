import 'package:characters/characters.dart';

import '../utils/markdown_plain.dart';

/// 笔记（页面）数据模型。在 OneNote 体系里对应「页」。
///
/// 只负责「数据结构 + 序列化」，不依赖 Flutter、不碰存储，
/// 方便在单元测试里直接构造和断言。
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const <String>[],
    this.notebookId,
    this.sectionId,
    this.pinned = false,
    this.archived = false,
    this.deletedAt,
  });

  /// 唯一标识。新增笔记时由仓储层生成。
  final String id;

  /// 标题，允许为空（UI 会显示本地化的「无标题」）。
  final String title;

  /// 正文，支持 Markdown 语法。
  final String content;

  final DateTime createdAt;

  /// 最近一次修改时间，列表默认按它倒序排列。
  final DateTime updatedAt;

  /// 标签。同一条笔记可以有多个，列表页可按标签筛选。
  final List<String> tags;

  /// 所属笔记本 id。不变式：每条笔记都必须归属一个笔记本，加载时
  /// `HomeShell._ensureDefaults()` 会把没有有效归属的笔记并进兜底笔记本；
  /// 类型可空只是为了容忍旧数据里这个字段还不存在。
  final String? notebookId;

  /// 所属分区 id，可以为空——空表示挂在该笔记本的「未分区」下。
  final String? sectionId;

  /// 置顶（收藏）。置顶的笔记排在列表最前面。
  final bool pinned;

  /// 是否已归档。软删除标记，列表默认过滤掉。
  final bool archived;

  /// 归档时间，用于「彻底删除」的提醒文案。
  final DateTime? deletedAt;

  /// 标题是否为空（展示层用 [AppStrings.untitled] 兜底，避免模型里写死文案）。
  bool get hasTitle => title.trim().isNotEmpty;

  /// 展示用的标题，可能为空字符串。
  String get displayTitle => title.trim();

  /// 是否为空笔记（标题、正文、标签都为空）。保存时用它判断要不要丢弃/删除。
  bool get isBlank =>
      title.trim().isEmpty && content.trim().isEmpty && tags.isEmpty;

  /// 列表副标题用的纯文本摘要：把 Markdown 标记尽量剥掉后再按字素截断。
  String get plainPreview => plainTextFromMarkdown(content);

  /// 字素（用户感知字符）数：中文按字计，emoji 不会拆半。
  int get graphemeCount => content.characters.length;

  /// 字数：按空白切词，适合英文；中文按字符计。
  int get wordCount => content
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .fold<int>(
        0,
        (sum, word) => sum + _cjkUnits(word) + (RegExp(r'[A-Za-z0-9]').hasMatch(word) ? 1 : 0),
      );

  static final RegExp _cjk = RegExp(r'[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]');

  static int _cjkUnits(String word) => _cjk.allMatches(word).length;

  /// 保存时应写入的 updatedAt。
  ///
  /// Windows 系统时钟只有毫秒级精度，自动保存紧接着手动保存时两次会拿到
  /// 相同时间；而列表排序用的 List.sort 并不稳定，时间相同就会在刷新后跳位。
  /// 这里保证严格晚于上一次，排序因此始终确定。
  DateTime bumpedUpdatedAt([DateTime? now]) {
    final candidate = now ?? DateTime.now();
    return candidate.isAfter(updatedAt)
        ? candidate
        : updatedAt.add(const Duration(microseconds: 1));
  }

  /// 返回修改过字段的新实例。保留 id 与 createdAt，updatedAt 默认刷新为当前时间。
  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    List<String>? tags,
    Object? notebookId = _sentinel,
    Object? sectionId = _sentinel,
    bool? pinned,
    bool? archived,
    Object? deletedAt = _sentinel,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      notebookId: identical(notebookId, _sentinel) ? this.notebookId : notebookId as String?,
      sectionId: identical(sectionId, _sentinel) ? this.sectionId : sectionId as String?,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      deletedAt: identical(deletedAt, _sentinel) ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  /// 用当前时间生成一条全新笔记。
  ///
  /// id = 微秒时间戳 + 自增序号：Windows 的系统时钟分辨率只有毫秒级，
  /// 连续新建两条笔记会拿到相同的时间戳，必须补一个序号才能保证唯一
  /// （否则列表里会出现重复的 Dismissible key，更新也可能打到错的笔记上）。
  factory Note.create({
    String title = '',
    String content = '',
    List<String> tags = const <String>[],
    String? notebookId,
    String? sectionId,
  }) {
    final now = DateTime.now();
    return Note(
      id: _nextId(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      tags: tags,
      notebookId: notebookId,
      sectionId: sectionId,
    );
  }

  static int _idSequence = 0;

  static String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-n${++_idSequence}';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags,
        'notebookId': notebookId,
        'sectionId': sectionId,
        'pinned': pinned,
        'archived': archived,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  /// 反序列化。对缺失/脏数据做兜底，避免一条坏数据导致整个列表打不开。
  ///
  /// 兼容 v1 数据：旧的 folderId 字段直接当作 sectionId 读入
  /// （文件夹在启动迁移时已转换成同名分区，id 保持不变）。
  factory Note.fromJson(Map<String, dynamic> json) {
    final updatedRaw = json['updatedAt'] as String?;
    final createdRaw = json['createdAt'] as String?;
    final updatedAt = DateTime.tryParse(updatedRaw ?? '');
    final createdAt = DateTime.tryParse(createdRaw ?? '');

    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags
            .whereType<String>()
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    return Note(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      createdAt: createdAt ?? updatedAt ?? DateTime.now(),
      updatedAt: updatedAt ?? createdAt ?? DateTime.now(),
      tags: tags,
      // notebookId 是后加的字段：旧数据一律留空，由加载时的兜底逻辑按分区补全。
      notebookId: json['notebookId'] as String?,
      sectionId: (json['sectionId'] as String?) ?? (json['folderId'] as String?),
      pinned: json['pinned'] as bool? ?? false,
      // 归档位早期叫 trashed（"回收站"语义），旧数据里仍是那个 key。
      archived: json['archived'] as bool? ?? json['trashed'] as bool? ?? false,
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          other.id == id &&
          other.title == title &&
          other.content == content &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.pinned == pinned &&
          other.archived == archived;

  @override
  int get hashCode =>
      Object.hash(id, title, content, createdAt, updatedAt, pinned, archived);

  @override
  String toString() => 'Note(id: $id, title: $title, updatedAt: $updatedAt)';
}

/// copyWith 里区分「不传」和「传 null」的哨兵值。
const Object _sentinel = Object();
