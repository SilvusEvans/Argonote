import 'package:argonote/models/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note', () {
    test('create 生成 id 并初始化时间', () {
      final note = Note.create(title: '标题', content: '正文');

      expect(note.id, isNotEmpty);
      expect(note.title, '标题');
      expect(note.content, '正文');
      expect(note.createdAt, note.updatedAt);
      expect(note.tags, isEmpty);
      expect(note.folderId, isNull);
    });

    test('create 可以带上标签与文件夹', () {
      final note = Note.create(tags: const <String>['工作'], folderId: 'folder-1');

      expect(note.tags, <String>['工作']);
      expect(note.folderId, 'folder-1');
    });

    test('copyWith 只覆盖传入字段，并刷新 updatedAt', () {
      final note = Note.create(title: '旧标题', content: '旧正文');
      final later = note.createdAt.add(const Duration(minutes: 5));
      final updated = note.copyWith(title: '新标题', updatedAt: later);

      expect(updated.id, note.id);
      expect(updated.title, '新标题');
      expect(updated.content, '旧正文');
      expect(updated.createdAt, note.createdAt);
      expect(updated.updatedAt, later);
    });

    test('copyWith 传 null 可以把文件夹清空，不传则保持原值', () {
      final note = Note.create(folderId: 'folder-1');

      expect(note.copyWith(folderId: null).folderId, isNull);
      expect(note.copyWith(title: 'x').folderId, 'folder-1');
    });

    test('空标题回退为「无标题」，isBlank 判断正确', () {
      expect(Note.create(title: '   ').displayTitle, '无标题');
      expect(Note.create().isBlank, isTrue);
      expect(Note.create(content: '有内容').isBlank, isFalse);
      // 只有标签也算是「有内容」，不该被当成空笔记丢掉。
      expect(Note.create(tags: const <String>['待办']).isBlank, isFalse);
    });

    test('plainPreview 去掉 Markdown 标记', () {
      final note = Note.create(content: '# 标题\n\n- 第一项\n- 第二项');

      expect(note.plainPreview, '标题 第一项 第二项');
    });

    test('JSON 序列化可往返（含标签与文件夹）', () {
      final note = Note.create(
        title: '会议纪要',
        content: '1. 结论\n2. 待办',
        tags: const <String>['会议', '重要'],
        folderId: 'folder-1',
      );
      final restored = Note.fromJson(note.toJson());

      expect(restored, note);
      expect(restored.tags, <String>['会议', '重要']);
      expect(restored.folderId, 'folder-1');
    });

    test('旧数据（没有 tags / folderId 字段）也能正常读取', () {
      final note = Note.fromJson(<String, dynamic>{
        'id': 'legacy',
        'title': '老笔记',
        'content': '内容',
        'updatedAt': DateTime(2024).toIso8601String(),
      });

      expect(note.tags, isEmpty);
      expect(note.folderId, isNull);
    });

    test('脏数据不会抛异常，缺失字段有兜底', () {
      final note = Note.fromJson(<String, dynamic>{});

      expect(note.id, isEmpty);
      expect(note.title, isEmpty);
      expect(note.isBlank, isTrue);
    });
  });
}
