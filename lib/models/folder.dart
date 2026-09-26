/// 文件夹：只负责「给笔记分组」，笔记通过 folderId 指向它。
class Folder {
  const Folder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// id = 微秒时间戳 + 自增序号，
  /// 避免连续创建时因 Windows 时钟只有毫秒级精度而拿到重复 id。
  factory Folder.create(String name) {
    return Folder(
      id: _nextId(),
      name: name,
      createdAt: DateTime.now(),
    );
  }

  static int _idSequence = 0;

  static String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-${++_idSequence}';

  Folder copyWith({String? name}) => Folder(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Folder && other.id == id && other.name == name && other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, createdAt);

  @override
  String toString() => 'Folder(id: $id, name: $name)';
}
