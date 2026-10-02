// 编辑器工具栏与双链的纯文本操作。
//
// 不依赖 Flutter 控制器，输入/输出都用 (text, start, end) 三元组，
// 方便单元测试直接验证插入/包裹结果。
import 'package:characters/characters.dart';

/// 一次编辑的结果文本与选区。
class EditResult {
  const EditResult({required this.text, required this.start, required this.end});
  final String text;
  final int start;
  final int end;
}

// 鼠标/触屏拖出的选区端点可能落在代理对中间，而下面的操作全按 UTF-16 code
// unit 做 substring，切在半截 emoji 上就会留下孤立代理对——写回文本框后渲染成
// U+FFFD，表现为"字符时不时显示不出来"。所以先统一夹到字素边界。

/// 不大于 [offset] 的最后一个字素边界。
int _boundaryBefore(String text, int offset) {
  var boundary = 0;
  var best = 0;
  for (final cluster in text.characters) {
    if (boundary > offset) return best;
    best = boundary;
    boundary += cluster.length;
  }
  return offset >= text.length ? text.length : best;
}

/// 不小于 [offset] 的第一个字素边界。
int _boundaryAfter(String text, int offset) {
  var boundary = 0;
  for (final cluster in text.characters) {
    if (boundary >= offset) return boundary;
    boundary += cluster.length;
  }
  return boundary;
}

/// 把任意 (start,end) 规范成有序的字素边界对：选区向外扩到完整字素，
/// 纯光标只左贴边界（否则会把旁边的 emoji 一起选中并替换掉）。
(int, int) _snapBounds(String text, int start, int end) {
  if (start == end) {
    final b = _boundaryBefore(text, start.clamp(0, text.length));
    return (b, b);
  }
  final s = _boundaryBefore(text, start.clamp(0, text.length));
  final e = _boundaryAfter(text, end.clamp(0, text.length));
  return e < s ? (e, s) : (s, e);
}

/// 用 before/after 包裹选区；未选中时插入标记并把光标放到中间。
EditResult wrapSelection(
  String text,
  int start,
  int end, {
  required String before,
  String after = '',
  String placeholder = '',
}) {
  final (s, e) = _snapBounds(text, start, end);
  final selected = text.substring(s, e);
  if (selected.isEmpty) {
    final inserted = '$before$placeholder$after';
    final cursor = s + before.length;
    return EditResult(
      text: text.substring(0, s) + inserted + text.substring(e),
      start: cursor,
      end: cursor + placeholder.length,
    );
  }
  // 已包裹则剥离（切换语义）。
  if (selected.startsWith(before) && after.isNotEmpty && selected.endsWith(after)) {
    final inner = selected.substring(before.length, selected.length - after.length);
    final replaced = text.substring(0, s) + inner + text.substring(e);
    return EditResult(text: replaced, start: s, end: s + inner.length);
  }
  final wrapped = '$before$selected$after';
  return EditResult(
    text: text.substring(0, s) + wrapped + text.substring(e),
    start: s,
    end: s + wrapped.length,
  );
}

/// 给选区覆盖的每一行加行首前缀（如 `- `、`# `、`- [ ] `）。
/// 已有该前缀的行会被去掉（切换语义）。
EditResult prefixLines(
  String text,
  int start,
  int end, {
  required String prefix,
}) {
  final lineStart = text.lastIndexOf('\n', start == 0 ? 0 : start - 1) + 1;
  var lineEnd = text.indexOf('\n', end);
  if (lineEnd == -1) lineEnd = text.length;

  final block = text.substring(lineStart, lineEnd);
  final lines = block.split('\n');
  final allPrefixed = lines.every((line) => line.startsWith(prefix));

  final transformed = <String>[
    for (final line in lines)
      allPrefixed ? line.substring(prefix.length) : '$prefix$line',
  ].join('\n');

  return EditResult(
    text: text.substring(0, lineStart) + transformed + text.substring(lineEnd),
    start: lineStart,
    end: lineStart + transformed.length,
  );
}

/// 在选区处插入一段文本（块级内容前后自动补空行）。
EditResult insertBlock(String text, int start, int end, String block) {
  final (s, e) = _snapBounds(text, start, end);
  final needsLeading = s > 0 && text[s - 1] != '\n';
  final needsTrailing = e < text.length && text[e] != '\n';
  final payload = '${needsLeading ? '\n' : ''}$block${needsTrailing ? '\n' : ''}';
  final cursor = s + payload.length;
  return EditResult(
    text: text.substring(0, s) + payload + text.substring(e),
    start: cursor,
    end: cursor,
  );
}

const String tableBlock = '| 列一 | 列二 | 列三 |\n'
    '| ---- | ---- | ---- |\n'
    '|      |      |      |';

/// 把 `[[标题]]` 双链转成 `note://` 协议的 Markdown 链接，
/// 供 flutter_markdown 渲染成可点击文本，点击后由外壳解析跳转。
String preprocessWikiLinks(String source) {
  final pattern = RegExp(r'\[\[([^\[\]\n]+)\]\]');
  final buffer = StringBuffer();
  var last = 0;
  for (final match in pattern.allMatches(source)) {
    buffer.write(source.substring(last, match.start));
    final title = match.group(1)!.trim();
    buffer.write('[$title](note://${Uri.encodeComponent(title)})');
    last = match.end;
  }
  buffer.write(source.substring(last));
  return buffer.toString();
}

/// 标准 Markdown 把单个换行当软换行，渲染时会并成一段，逼着用户敲两次回车。
/// 这里在代码围栏之外，给相邻的两行普通文字补上两个尾随空格，变成硬换行。
///
/// 表格行、列表项、标题、分割线、缩进代码块都有各自的块级语义，不参与；
/// 引用块的相邻两行之间照样断行。
String applySoftLineBreaks(String source) {
  final lines = source.split('\n');
  var inFence = false;
  for (var i = 0; i < lines.length - 1; i++) {
    if (RegExp(r'^\s*(```|~~~)').hasMatch(lines[i])) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (!_isPlainTextLine(lines[i]) || !_isPlainTextLine(lines[i + 1])) continue;
    if (lines[i].endsWith('  ')) continue;
    lines[i] = '${lines[i]}  ';
  }
  return lines.join('\n');
}

/// 参与硬换行判定的「普通文字行」：非空、不是块级语法、也不是缩进代码。
bool _isPlainTextLine(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.isEmpty) return false;
  if (line.startsWith('    ') || line.startsWith('\t')) return false;
  final body = trimmed.startsWith('>') ? trimmed.replaceFirst(RegExp(r'^>\s*'), '') : trimmed;
  if (body.isEmpty) return false;
  if (body.startsWith('|')) return false;
  return !RegExp(r'^(#{1,6}\s|[-*+]\s|\d+[.)]\s|---+$|\*\*\*+$|___+$)').hasMatch(body);
}

/// 从 onTapLink 收到的 href 里解析双链目标；非 note:// 返回 null。
String? wikiLinkTarget(String href) {
  if (!href.startsWith('note://')) return null;
  return Uri.decodeComponent(href.substring('note://'.length));
}
