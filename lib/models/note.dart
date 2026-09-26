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
  });

  /// 唯一标识。新增笔记时由仓储层生成。
  final String id;

  /// 标题，允许为空（列表页会显示「无标题」）。
  final String title;

  /// 正文。
  final String content;

  final DateTime createdAt;

  /// 最近一次修改时间，列表按它倒序排列。
  final DateTime updatedAt;

  /// 列表/详情页展示用的标题，空标题回退为「无标题」。
  String get displayTitle => title.trim().isEmpty ? '无标题' : title.trim();

  /// 是否为空笔记（标题和正文都为空）。返回编辑页时用它判断要不要丢弃。
  bool get isBlank => title.trim().isEmpty && content.trim().isEmpty;

  /// 返回修改过字段的新实例。保留 id 与 createdAt，updatedAt 默认刷新为当前时间。
  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// 用当前时间生成一条全新笔记，id 由微秒时间戳生成，保证单机内唯一。
  factory Note.create({String title = '', String content = ''}) {
    final now = DateTime.now();
    return Note(
      id: '${now.microsecondsSinceEpoch}',
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// 反序列化。对缺失/脏数据做兜底，避免一条坏数据导致整个列表打不开。
  factory Note.fromJson(Map<String, dynamic> json) {
    final updatedRaw = json['updatedAt'] as String?;
    final createdRaw = json['createdAt'] as String?;
    final updatedAt = DateTime.tryParse(updatedRaw ?? '');
    final createdAt = DateTime.tryParse(createdRaw ?? '');
    return Note(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      createdAt: createdAt ?? updatedAt ?? DateTime.now(),
      updatedAt: updatedAt ?? createdAt ?? DateTime.now(),
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
