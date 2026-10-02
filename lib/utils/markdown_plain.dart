import 'package:characters/characters.dart';

/// 把 Markdown 粗略还原成纯文本，用于列表页的摘要行。
///
/// 只做展示用的「去标记」，不追求 100% 精确：
/// 去掉围栏代码块、标题符、列表符、引用符、加粗/斜体、行内代码，
/// 链接只保留文字，表格竖线换成空格，最后把换行折叠成空格。
///
/// 注意：需要保留分组内容的替换必须用 [String.replaceAllMapped]，
/// `replaceAll` 不支持 `$1` 组引用（会原样插入 "$1"）。
String plainTextFromMarkdown(String source, {int maxLength = 80}) {
  var text = source;

  // 围栏代码块整体去掉。
  text = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  text = text.replaceAll(RegExp(r'~~~[\s\S]*?~~~'), ' ');

  // 图片 / 链接只保留可见文字。
  text = text.replaceAllMapped(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1) ?? '');
  text = text.replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1) ?? '');

  // 行内代码、强调、删除线：只保留被包裹的内容。
  text = text.replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m.group(1) ?? '');
  text = text.replaceAllMapped(RegExp(r'\*\*([^*]*)\*\*'), (m) => m.group(1) ?? '');
  text = text.replaceAllMapped(RegExp(r'__([^_]*)__'), (m) => m.group(1) ?? '');
  text = text.replaceAllMapped(RegExp(r'~~([^~]*)~~'), (m) => m.group(1) ?? '');
  // 单星号斜体放在加粗之后处理，此时剩下的都是斜体。
  text = text.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');

  // 行首标记：标题、引用、列表。
  text = text.replaceAllMapped(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), (_) => '');
  text = text.replaceAllMapped(RegExp(r'^\s{0,3}>\s?', multiLine: true), (_) => '');
  text = text.replaceAllMapped(RegExp(r'^\s*[-*+]\s+', multiLine: true), (_) => '');
  text = text.replaceAllMapped(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), (_) => '');

  // 表格分隔行与竖线。
  text = text.replaceAllMapped(RegExp(r'^\s*\|?[\s:|-]+\|\s*$', multiLine: true), (_) => ' ');
  text = text.replaceAll('|', ' ');

  // 水平分割线与反斜杠转义。
  text = text.replaceAllMapped(RegExp(r'^\s*([-*_])\1{2,}\s*$', multiLine: true), (_) => ' ');
  text = text.replaceAllMapped(RegExp(r'\\(.)'), (m) => m.group(1) ?? '');

  // 折叠空白。
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  // 按「用户感知字符」（grapheme cluster）截断。
  //
  // 不能用 String.substring：它按 UTF-16 code unit 切，
  // emoji（如 😀 = 2 个 code unit）落在边界上时会被切成半个代理对，
  // 生成无效字符串，渲染成替换符 � —— 这就是摘要行偶发乱码的根因。
  final chars = text.characters;
  if (chars.length <= maxLength) return text;
  return '${chars.take(maxLength)}…';
}
