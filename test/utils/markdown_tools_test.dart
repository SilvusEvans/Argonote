import 'package:argonote/utils/markdown_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wrapSelection', () {
    test('包裹选区', () {
      final r = wrapSelection('hello world', 0, 5, before: '**', after: '**');
      expect(r.text, '**hello** world');
      expect(r.start, 0);
      expect(r.end, 12);
    });

    test('已包裹则剥离（切换语义）', () {
      final r = wrapSelection('**hello** world', 0, 9, before: '**', after: '**');
      expect(r.text, 'hello world');
    });

    test('无选区时插入占位并选中占位文本', () {
      final r = wrapSelection('', 0, 0, before: '*', after: '*', placeholder: '斜体');
      expect(r.text, '*斜体*');
      expect(r.start, 1);
      expect(r.end, 3);
    });

    test('选区端点落在代理对中间时向外扩成完整字素', () {
      final grin = String.fromCharCodes([0xD83D, 0xDE00]);
      final r = wrapSelection('前$grin后', 2, 3, before: '*', after: '*');
      expect(r.text, '前*$grin*后');
    });

    test('光标在半截 emoji 内时只插入标记、不吞掉字形', () {
      final grin = String.fromCharCodes([0xD83D, 0xDE00]);
      final r = wrapSelection('前$grin后', 2, 2, before: '**', after: '**');
      expect(r.text, '前****$grin后');
      expect(r.start, 3);
    });
  });

  group('prefixLines', () {
    test('给覆盖的每一行加前缀', () {
      final r = prefixLines('- a\n- b', 0, 7, prefix: '- ');
      expect(r.text, 'a\nb'); // 全带前缀 → 剥离
    });

    test('未带前缀则加上，并扩展到整行', () {
      final r = prefixLines('one\ntwo\nthree', 5, 7, prefix: '> ');
      expect(r.text, 'one\n> two\nthree');
    });
  });

  group('insertBlock', () {
    test('行中插入时自动补前后换行', () {
      final r = insertBlock('abc', 1, 1, '---');
      expect(r.text, 'a\n---\nbc');
      expect(r.start, 6);
    });

    test('行首插入不再补前导换行', () {
      final r = insertBlock('text', 0, 0, '| a |');
      expect(r.text, '| a |text');
    });
  });

  group('wiki links', () {
    test('双链转成 note:// 链接', () {
      final out = preprocessWikiLinks('参考 [[会议纪要]] 与 [[项目计划]]');
      expect(out, contains('[会议纪要](note://%E4%BC%9A%E8%AE%AE%E7%BA%AA%E8%A6%81)'));
      expect(out, contains('[项目计划](note://'));
    });

    test('普通文本不受影响', () {
      expect(preprocessWikiLinks('没有链接 [正常](https://a.com)'), '没有链接 [正常](https://a.com)');
    });

    test('解析回目标标题', () {
      expect(wikiLinkTarget('note://%E4%BC%9A%E8%AE%AE%E7%BA%AA%E8%A6%81'), '会议纪要');
      expect(wikiLinkTarget('https://a.com'), isNull);
    });
  });
}
