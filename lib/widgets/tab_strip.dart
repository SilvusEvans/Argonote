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

  @override
  void didUpdateWidget(covariant TabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeId != widget.activeId) _ensureActiveVisible();
  }

  void _ensureActiveVisible() {
    final index = widget.tabs.indexWhere((tab) => tab.id == widget.activeId);
    if (index < 0 || !_scrollController.hasClients) return;
    const tabWidth = 190.0;
    final target = (index * tabWidth) - _scrollController.position.viewportDimension / 2 + tabWidth / 2;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
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
      height: 40,
      color: theme.colorScheme.surfaceContainerLow,
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: 190, minWidth: 90),
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.surface : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: isActive ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Row(
                    children: [
                      if (tab.pinned) ...[
                        Icon(Icons.push_pin, size: 12, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: tab.dirty
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
