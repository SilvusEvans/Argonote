import 'package:argonote/models/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note', () {
    test('create 生成唯一 id，当前时间戳齐', () {
      final note = Note.create(title: 't', content: 'c');
      expect(note.id, isNotEmpty);
      expect(note.createdAt.difference(note.updatedAt).abs(), Duration.zero);
      expect(note.sectionId, isNull);
      expect(note.pinned, isFalse);
      expect(note.archived, isFalse);
    });

    test('isBlank：标题正文标签全空才算空，分区归属不参与', () {
      expect(Note.create().isBlank, isTrue);
      expect(Note.create(title: '  ').isBlank, isTrue);
      expect(Note.create(tags: const <String>['x']).isBlank, isFalse);
      expect(Note.create(sectionId: 's').isBlank, isTrue);
      expect(Note.create(content: '# hi').isBlank, isFalse);
    });

    test('copyWith 保留 id 与 createdAt，默认刷新 updatedAt', () {
      final note = Note.create(title: 't', content: 'c', sectionId: 'sec');
      final later = note.copyWith(content: 'new');

      expect(later.id, note.id);
      expect(later.createdAt, note.createdAt);
      expect(later.updatedAt.isAfter(note.updatedAt) || later.updatedAt == note.updatedAt, isTrue);
      expect(later.content, 'new');
      expect(later.sectionId, 'sec');
    });

    test('copyWith 哨兵：不传归属保持原值，显式传 null 清空', () {
      final note = Note.create(notebookId: 'nb', sectionId: 'sec');
      expect(note.copyWith(title: 'x').sectionId, 'sec');
      expect(note.copyWith(title: 'x').notebookId, 'nb');
      expect(note.copyWith(sectionId: null).sectionId, isNull);
      expect(note.copyWith(notebookId: null).notebookId, isNull);
      expect(note.copyWith(deletedAt: null).deletedAt, isNull);
    });

    test('JSON 往返保留全部字段', () {
      final note = Note.create(
        title: '标题',
        content: '正文',
        tags: const <String>['a', 'b'],
        notebookId: 'nb-1',
        sectionId: 'sec-1',
      );
      final moved = note.copyWith(archived: true, deletedAt: DateTime.now());

      final restored = Note.fromJson(moved.toJson());
      expect(restored.id, note.id);
      expect(restored.tags, <String>['a', 'b']);
      expect(restored.notebookId, 'nb-1');
      expect(restored.sectionId, 'sec-1');
      expect(restored.archived, isTrue);
      expect(restored.deletedAt, isNotNull);
    });

    test('脏 JSON 不炸：缺失字段与错误类型都有兜底', () {
      final restored = Note.fromJson(<String, dynamic>{
        'id': 'x',
        'tags': 'not-a-list',
        'createdAt': 'garbage',
      });
      expect(restored.id, 'x');
      expect(restored.tags, isEmpty);
      expect(restored.createdAt.isBefore(DateTime.now()), isTrue);
    });

    test('plainPreview 对 emoji 边界安全（不产生替换符）', () {
      // 摘要截断点正好落在 emoji 中间时，旧实现（substring）会切坏代理对。
      final emoji = '😀' * 100;
      final preview = Note.create(content: emoji).plainPreview;
      expect(preview.contains('\uFFFD'), isFalse);
    });

    test('graphemeCount 按字素计数：emoji 记 1，组合音标不翻倍', () {
      expect(Note.create(content: '😀').graphemeCount, 1);
      expect(Note.create(content: '👩‍👩‍👧').graphemeCount, 1);
      expect(Note.create(content: '你好').graphemeCount, 2);
    });

    test('wordCount 中英混合分别计量', () {
      expect(Note(content: 'hello world', id: 'x', title: '', createdAt: DateTime(2026), updatedAt: DateTime(2026)).wordCount, 2);
      expect(Note(content: '你好世界', id: 'x', title: '', createdAt: DateTime(2026), updatedAt: DateTime(2026)).wordCount, 4);
    });
  });
}
