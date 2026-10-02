/// OneNote 体系的顶层容器：笔记本（Notebook）。
///
/// 层级关系与 OneNote 一致：
/// 笔记本 > （分区组） > 分区（Section） > 页面（Note）。
/// 分区组可选，笔记永远直接挂在分区下。
class Notebook {
  const Notebook({
    required this.id,
    required this.name,
    required this.createdAt,
    this.colorIndex,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// 主题色下标（null 用默认色），用于树节点图标的着色。
  final int? colorIndex;

  factory Notebook.create(String name, {int? colorIndex}) => Notebook(
        id: _nextId(),
        name: name,
        createdAt: DateTime.now(),
        colorIndex: colorIndex,
      );

  static int _idSequence = 0;

  /// id = 微秒时间戳 + 自增序号：Windows 时钟精度只到毫秒，
  /// 连续创建时纯时间戳会重复。
  static String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-${++_idSequence}';

  Notebook copyWith({String? name, int? colorIndex}) => Notebook(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        colorIndex: colorIndex ?? this.colorIndex,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'colorIndex': colorIndex,
      };

  factory Notebook.fromJson(Map<String, dynamic> json) => Notebook(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        colorIndex: json['colorIndex'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notebook && other.id == id && other.name == name && other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, createdAt);

  @override
  String toString() => 'Notebook(id: $id, name: $name)';
}

/// 分区组：笔记本和分区之间的可选分组层。
class SectionGroup {
  const SectionGroup({
    required this.id,
    required this.notebookId,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String notebookId;
  final String name;
  final DateTime createdAt;

  factory SectionGroup.create(String notebookId, String name) => SectionGroup(
        id: _nextId(),
        notebookId: notebookId,
        name: name,
        createdAt: DateTime.now(),
      );

  static int _idSequence = 0;

  static String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-g${++_idSequence}';

  SectionGroup copyWith({String? name}) => SectionGroup(
        id: id,
        notebookId: notebookId,
        name: name ?? this.name,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'notebookId': notebookId,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SectionGroup.fromJson(Map<String, dynamic> json) => SectionGroup(
        id: (json['id'] as String?) ?? '',
        notebookId: (json['notebookId'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionGroup &&
          other.id == id &&
          other.notebookId == notebookId &&
          other.name == name;

  @override
  int get hashCode => Object.hash(id, notebookId, name);

  @override
  String toString() => 'SectionGroup(id: $id, name: $name)';
}

/// 分区：页面的直接容器，对应 OneNote 的 Section。
class Section {
  const Section({
    required this.id,
    required this.notebookId,
    required this.name,
    required this.createdAt,
    this.groupId,
  });

  final String id;
  final String notebookId;

  /// 所属分区组；null 表示直接挂在笔记本下。
  final String? groupId;

  final String name;
  final DateTime createdAt;

  factory Section.create({
    required String notebookId,
    required String name,
    String? groupId,
  }) =>
      Section(
        id: _nextId(),
        notebookId: notebookId,
        groupId: groupId,
        name: name,
        createdAt: DateTime.now(),
      );

  static int _idSequence = 0;

  static String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-s${++_idSequence}';

  Section copyWith({String? name, Object? groupId = _sentinel, String? notebookId}) => Section(
        id: id,
        notebookId: notebookId ?? this.notebookId,
        groupId: identical(groupId, _sentinel) ? this.groupId : groupId as String?,
        name: name ?? this.name,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'notebookId': notebookId,
        'groupId': groupId,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        id: (json['id'] as String?) ?? '',
        notebookId: (json['notebookId'] as String?) ?? '',
        groupId: json['groupId'] as String?,
        name: (json['name'] as String?) ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Section &&
          other.id == id &&
          other.notebookId == notebookId &&
          other.groupId == groupId &&
          other.name == name;

  @override
  int get hashCode => Object.hash(id, notebookId, groupId, name);

  @override
  String toString() => 'Section(id: $id, name: $name)';
}

const Object _sentinel = Object();
