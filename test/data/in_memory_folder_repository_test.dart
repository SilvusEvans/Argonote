import 'package:argonote/data/in_memory_folder_repository.dart';
import 'package:argonote/models/folder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryFolderRepository repository;

  setUp(() {
    repository = InMemoryFolderRepository();
  });

  test('create 后可以列出来', () async {
    final folder = await repository.create('工作');

    expect(folder.name, '工作');
    expect(await repository.findById(folder.id), folder);
  });

  test('all 按名称排序（忽略大小写）', () async {
    await repository.create('zeta');
    await repository.create('Alpha');

    final folders = await repository.all();
    expect(folders.first.name, 'Alpha');
    expect(folders.last.name, 'zeta');
  });

  test('rename 改名字且 id 不变', () async {
    final folder = await repository.create('旧名字');
    final renamed = await repository.rename(folder.id, '新名字');

    expect(renamed.id, folder.id);
    expect(renamed.name, '新名字');
    expect((await repository.findById(folder.id))?.name, '新名字');
  });

  test('delete 后查不到，但不影响其它文件夹', () async {
    final a = await repository.create('A');
    await repository.create('B');

    await repository.delete(a.id);

    expect(await repository.findById(a.id), isNull);
    expect(await repository.all(), hasLength(1));
  });

  test('初始化可以塞入种子数据', () async {
    final seeded = InMemoryFolderRepository(<Folder>[Folder.create('已有')]);
    expect(await seeded.all(), hasLength(1));
  });
}
