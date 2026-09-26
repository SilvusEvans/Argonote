import 'package:argonote/utils/markdown_plain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

void main() {
  group('plainTextFromMarkdown', () {
    test('去掉标题与列表标记', () {
      expect(
        plainTextFromMarkdown('# 标题\n\n- 第一项\n- 第二项'),
        '标题 第一项 第二项',
      );
    });

    test('去掉代码块', () {
      expect(
        plainTextFromMarkdown('说明\n\n```dart\nfinal a = 1;\n```\n\n结尾'),
        '说明 结尾',
      );
    });

    test('链接只保留文字', () {
      expect(
        plainTextFromMarkdown('见 [官网](https://example.com) 说明'),
        '见 官网 说明',
      );
    });

    test('去掉加粗、行内代码与引用', () {
      expect(
        plainTextFromMarkdown('**重点** 与 `code`\n\n> 引用内容'),
        '重点 与 code 引用内容',
      );
    });

    test('表格竖线换成空格', () {
      expect(
        plainTextFromMarkdown('| 列一 | 列二 |\n| --- | --- |\n| 甲 | 乙 |'),
        '列一 列二 甲 乙',
      );
    });

    test('超长文本会截断', () {
      final result = plainTextFromMarkdown('字' * 200, maxLength: 10);
      expect(result, '字字字字字字字字字字…');
    });
  });

  group('Markdown 解析（GFM）', () {
    final html = md.markdownToHtml(
      '# 标题\n\n- 项目一\n- 项目二\n\n```dart\nfinal a = 1;\n```\n\n'
          '| 列一 | 列二 |\n| --- | --- |\n| 甲 | 乙 |\n\n'
          '[链接](https://example.com)\n\n> 引用',
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );

    test('标题', () {
      expect(html, contains('<h1>标题</h1>'));
    });

    test('列表', () {
      expect(html, contains('<li>项目一</li>'));
    });

    test('代码块', () {
      expect(html, contains('<code'));
    });

    test('表格', () {
      expect(html, contains('<table'));
      expect(html, contains('<th>列一</th>'));
      expect(html, contains('<td>甲</td>'));
    });

    test('链接', () {
      expect(html, contains('href="https://example.com"'));
    });

    test('引用', () {
      expect(html, contains('<blockquote>'));
    });
  });
}
