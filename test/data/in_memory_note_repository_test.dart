import 'package:argonote/data/in_memory_note_repository.dart';
import 'package:argonote/models/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryNoteRepository repository;

  setUp(() {
    repository = InMemoryNoteRepository();
  });

  test('初始为空', () async {
    expect(await repository.all(), isEmpty);
  });

  test('create 后可以按 id 查到', () async {
    final created = await repository.create(title: 'A', content: 'a');

    final found = await repository.findById(created.id);
    expect(found?.title, 'A');
    expect(await repository.all(), hasLength(1));
  });

  test('all 按更新时间倒序返回', () async {
    final repository = InMemoryNoteRepository(<Note>[
      Note(
        id: 'older',
        title: '较早的一条',
        content: '',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
      Note(
        id: 'newer',
        title: '较新的一条',
        content: '',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      ),
    ]);

    final notes = await repository.all();
    expect(notes.first.id, 'newer');
    expect(notes.last.id, 'older');
  });

  test('update 修改内容并刷新 updatedAt', () async {
    final note = await repository.create(title: '原标题', content: '原正文');
    final updated = await repository.update(
      id: note.id,
      title: '新标题',
      content: '新正文',
    );

    expect(updated.id, note.id);
    expect(updated.title, '新标题');
    expect(updated.content, '新正文');
    expect(updated.createdAt, note.createdAt);
    // 同一毫秒内可能相等，所以只断言「没有被改早」。
    expect(updated.updatedAt.isBefore(note.updatedAt), isFalse);

    final stored = await repository.findById(note.id);
    expect(stored?.title, '新标题');
  });

  test('delete 后查不到，restore 可以完整还原', () async {
    final note = await repository.create(title: '待删除', content: '内容');
    await repository.delete(note.id);
    expect(await repository.findById(note.id), isNull);

    await repository.restore(note);
    final restored = await repository.findById(note.id);
    expect(restored, note);
  });

  test('删除不存在的 id 不报错', () async {
    await repository.delete('not-exist');
    expect(await repository.all(), isEmpty);
  });
}
