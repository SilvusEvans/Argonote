import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// Markdown 渲染视图。
///
/// 用 GitHub Flavored 扩展集，因此标题、列表、任务列表、代码块、
/// 链接、表格、引用、分割线都能正常渲染；样式由当前主题派生，
/// 切换主色 / 深浅模式时预览会跟着变。
class MarkdownView extends StatelessWidget {
  const MarkdownView({
    super.key,
    required this.data,
    this.onTapLink,
  });

  final String data;

  /// 点击链接时回调（应用内不额外引入 url_launcher，交由调用方决定怎么处理）。
  final void Function(String href)? onTapLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = MarkdownStyleSheet.fromTheme(theme);
    final outline = theme.colorScheme.outlineVariant;

    final style = base.copyWith(
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      code: (base.code ?? const TextStyle()).copyWith(
        // 行内代码（工具栏 `<>` 就是单反引号）要有底色框才看得出是代码；
        // 取和代码块一样的底色，代码块内部再叠一层也不会变色。
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        // 'monospace' 是 Android 的逻辑字体名，Windows 上根本解析不到；
        // 命中不到字形时中文和 emoji 就先落到没有对应字形的字体上，
        // 表现为代码块/行内代码里「有时字符显示成方块」。这里换成真实字体
        // 并给出中文、emoji 的回退链。
        fontFamily: 'Consolas',
        fontFamilyFallback: const <String>[
          'Cascadia Mono',
          'Microsoft YaHei UI',
          'Segoe UI Emoji',
        ],
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      blockquotePadding: const EdgeInsets.all(12),
      tableBorder: TableBorder.all(
        color: outline,
        borderRadius: BorderRadius.circular(8),
      ),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: outline)),
      ),
    );

    return MarkdownBody(
      data: data,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: style,
      onTapLink: (text, href, title) {
        final target = href;
        if (target != null && target.isNotEmpty) {
          onTapLink?.call(target);
        }
      },
    );
  }
}
