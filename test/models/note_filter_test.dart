import 'package:argonote/models/note.dart';
import 'package:argonote/models/note_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // work / life 都归了文件夹，unfiled 没有，这样 unfiledOnly 才有区分度。
  final work = Note.create(
    title: '周报',
    content: '本周进展',
    tags: const <String>['工作'],
    folderId: 'folder-work',
  );
  final life = Note.create(
    title: '菜谱',
    content: '番茄炒蛋',
    tags: const <String>['生活'],
    folderId: 'folder-life',
  );
  final unfiled = Note.create(title: '随手记', content: '想到什么写什么');
  final english = Note.create(title: 'Weekly Report', content: 'progress', tags: const <String>['work']);

  final notes = <Note>[work, life, unfiled];

  group('NoteFilter', () {
    test('空筛选命中所有笔记', () {
      expect(notes.where(NoteFilter.empty.matches), hasLength(3));
      expect(NoteFilter.empty.isEmpty, isTrue);
    });

    test('按标签筛选', () {
      final filter = const NoteFilter(tag: '工作');
      expect(notes.where(filter.matches), <Note>[work]);
      expect(filter.isEmpty, isFalse);
    });

    test('按关键词筛选（标题 / 正文 / 标签都参与）', () {
      expect(notes.where(const NoteFilter(keyword: '周报').matches), <Note>[work]);
      expect(notes.where(const NoteFilter(keyword: '番茄').matches), <Note>[life]);
      expect(notes.where(const NoteFilter(keyword: '生活').matches), <Note>[life]);
    });

    test('关键词不区分大小写', () {
      // 用英文内容验证：中文没有大小写概念，拿中文测这个没有意义。
      expect(<Note>[english].where(const NoteFilter(keyword: 'WORK').matches), <Note>[english]);
      expect(<Note>[english].where(const NoteFilter(keyword: 'weekly').matches), <Note>[english]);
    });

    test('按文件夹筛选', () {
      expect(notes.where(const NoteFilter(folderId: 'folder-work').matches), <Note>[work]);
      expect(notes.where(const NoteFilter(folderId: 'folder-life').matches), <Note>[life]);
    });

    test('文件夹与关键词可以叠加', () {
      final inFolder = Note.create(
        title: '归档笔记',
        content: '内容',
        folderId: 'folder-1',
        tags: const <String>['工作'],
      );
      final filter = const NoteFilter(folderId: 'folder-1', keyword: '归档');
      expect(filter.matches(inFolder), isTrue);
      expect(filter.matches(work), isFalse);
    });

    test('只看未归类', () {
      final filter = const NoteFilter(unfiledOnly: true);
      final matched = notes.where(filter.matches).toList();
      expect(matched, <Note>[unfiled]);
    });

    test('copyWith 只改传入的部分', () {
      final filter = const NoteFilter(tag: '工作').copyWith(keyword: '周报');
      expect(filter.tag, '工作');
      expect(filter.keyword, '周报');

      final cleared = filter.copyWith(tag: null);
      expect(cleared.tag, isNull);
      expect(cleared.keyword, '周报');
    });

    test('collectTags 去重并排序', () {
      final duplicated = <Note>[
        work,
        Note.create(title: 'x', content: '', tags: const <String>['工作', '临时']),
      ];
      expect(NoteFilter.collectTags(duplicated), <String>['临时', '工作']);
    });
  });
}
