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

    test('空标题回退为「无标题」，isBlank 判断正确', () {
      expect(Note.create(title: '   ').displayTitle, '无标题');
      expect(Note.create().isBlank, isTrue);
      expect(Note.create(content: '有内容').isBlank, isFalse);
    });

    test('JSON 序列化可往返', () {
      final note = Note.create(title: '会议纪要', content: '1. 结论\n2. 待办');
      final restored = Note.fromJson(note.toJson());

      expect(restored, note);
    });

    test('脏数据不会抛异常，缺失字段有兜底', () {
      final note = Note.fromJson(<String, dynamic>{});

      expect(note.id, isEmpty);
      expect(note.title, isEmpty);
      expect(note.isBlank, isTrue);
    });
  });
}
