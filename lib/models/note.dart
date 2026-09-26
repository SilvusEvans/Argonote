import 'package:argonote/utils/markdown_plain.dart';

/// 笔记数据模型。
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
    this.folderId,
  });

  /// 唯一标识。新增笔记时由仓储层生成。
  final String id;

  /// 标题，允许为空（列表页会显示「无标题」）。
  final String title;

  /// 正文，支持 Markdown 语法。
  final String content;

  final DateTime createdAt;

  /// 最近一次修改时间，列表按它倒序排列。
  final DateTime updatedAt;

  /// 标签。同一条笔记可以有多个，列表页可按标签筛选。
  final List<String> tags;

  /// 所属文件夹 id；null 表示「未归类」。
  final String? folderId;

  /// 列表/详情页展示用的标题，空标题回退为「无标题」。
  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();

  /// 是否为空笔记（标题、正文、标签都为空且未归入文件夹）。
  /// 返回编辑页时用它判断要不要丢弃。
  bool get isBlank =>
      title.trim().isEmpty &&
      content.trim().isEmpty &&
      tags.isEmpty &&
      folderId == null;

  /// 列表副标题用的纯文本摘要：把 Markdown 标记尽量剥掉后再截断。
  String get plainPreview => plainTextFromMarkdown(content);

  /// 返回修改过字段的新实例。保留 id 与 createdAt，updatedAt 默认刷新为当前时间。
  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    List<String>? tags,
    Object? folderId = _sentinel,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      folderId: identical(folderId, _sentinel) ? this.folderId : folderId as String?,
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
    String? folderId,
  }) {
    final now = DateTime.now();
    return Note(
      id: _nextId(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      tags: tags,
      folderId: folderId,
    );
  }

  static int _idSequence = 0;

  static String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-${++_idSequence}';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags,
        'folderId': folderId,
      };

  /// 反序列化。对缺失/脏数据做兜底，避免一条坏数据导致整个列表打不开。
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
      folderId: json['folderId'] as String?,
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
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, title, content, createdAt, updatedAt);

  @override
  String toString() => 'Note(id: $id, title: $title, updatedAt: $updatedAt)';
}

/// copyWith 里区分「不传」和「传 null」的哨兵值。
const Object _sentinel = Object();
