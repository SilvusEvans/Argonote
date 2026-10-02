import 'package:flutter/material.dart';

import '../models/note_tab.dart';

/// 编辑器顶部的多标签条（浏览器式）。
///
/// 溢出横向滚动、当前标签自动滚入可见区；
/// 中键关闭、右键弹「关闭其它 / 全部关闭」菜单。
class TabStrip extends StatefulWidget {
  const TabStrip({
    super.key,
    required this.tabs,
    required this.activeId,
    required this.untitledLabel,
    required this.closeOthersLabel,
    required this.closeAllLabel,
    required this.onSelect,
    required this.onClose,
    required this.onCloseOthers,
    required this.onCloseAll,
    this.onNewDraft,
    this.addNewLabel,
  });

  final List<NoteTab> tabs;
  final String activeId;
  final String untitledLabel;
  final String closeOthersLabel;
  final String closeAllLabel;
  final ValueChanged<NoteTab> onSelect;
  final ValueChanged<NoteTab> onClose;
  final ValueChanged<NoteTab> onCloseOthers;
  final VoidCallback onCloseAll;
  final VoidCallback? onNewDraft;
  final String? addNewLabel;

  @override
  State<TabStrip> createState() => _TabStripState();
}

class _TabStripState extends State<TabStrip> {
  final ScrollController _scrollController = ScrollController();

  /// 标签宽度随标题变化，无法再用「序号 × 固定宽」算滚动位置，
  /// 所以给每个标签挂一个 GlobalKey，靠真实布局定位。
  final Map<String, GlobalKey> _tabKeys = <String, GlobalKey>{};

  @override
  void didUpdateWidget(covariant TabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = <String>{for (final tab in widget.tabs) tab.id};
    _tabKeys.removeWhere((id, _) => !ids.contains(id));
    if (oldWidget.activeId != widget.activeId) _ensureActiveVisible();
  }

  void _ensureActiveVisible() {
    // 新增标签时这一帧还没有它的 context，放到帧尾再滚。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _tabKeys[widget.activeId]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 46,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.tabs.length,
              itemBuilder: (context, index) {
                final tab = widget.tabs[index];
                return _buildTab(tab, isActive: tab.id == widget.activeId);
              },
            ),
          ),
          if (widget.onNewDraft != null)
            IconButton(
              tooltip: widget.addNewLabel,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: widget.onNewDraft,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(NoteTab tab, {required bool isActive}) {
    final theme = Theme.of(context);
    final label = tab.label.isEmpty ? widget.untitledLabel : tab.label;

    return GestureDetector(
      onTap: () => widget.onSelect(tab),
      onSecondaryTapDown: (details) => _showContextMenu(details, tab),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          key: _tabKeys.putIfAbsent(tab.id, GlobalKey.new),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 6),
          // 不设 minWidth：短标题就该是短胶囊，只有长标题需要封顶后省略。
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            // Android 17 的胶囊标签：选中态才有色块，未选中与条带底色融为一体。
            color: isActive ? theme.colorScheme.surfaceContainerHighest : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tab.pinned) ...[
                Icon(Icons.push_pin, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isActive ? theme.colorScheme.onSurface : null,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              tab.dirty
                  ? Tooltip(
                      message: '●',
                      waitDuration: const Duration(milliseconds: 400),
                      child: Icon(Icons.circle, size: 8, color: theme.colorScheme.primary),
                    )
                  : IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      onPressed: () => widget.onClose(tab),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(TapDownDetails details, NoteTab tab) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          onTap: () => widget.onCloseOthers(tab),
          child: Text(widget.closeOthersLabel),
        ),
        PopupMenuItem<void>(
          onTap: widget.onCloseAll,
          child: Text(widget.closeAllLabel),
        ),
      ],
    );
  }
}
