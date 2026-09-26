import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/folder.dart';
import '../models/note_filter.dart';

/// 列表页顶部的筛选栏：按文件夹、按标签各一行横滑的 FilterChip。
///
/// 纯展示组件，选中状态完全由外部传入的 [NoteFilter] 决定，
/// 点击时把新的 [NoteFilter] 回调出去。
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.folders,
    required this.tags,
    required this.filter,
    required this.hasUnfiledNotes,
    required this.strings,
    required this.onChanged,
  });

  final List<Folder> folders;
  final List<String> tags;

  /// 是否存在「未归类」的笔记，决定要不要显示那个 chip。
  final bool hasUnfiledNotes;
  final NoteFilter filter;
  final AppStrings strings;
  final ValueChanged<NoteFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final allSelected = filter.folderId == null && !filter.unfiledOnly;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipRow(
          icon: Icons.folder_open_outlined,
          children: [
            _FilterChipItem(
              label: strings.filterAll,
              selected: allSelected,
              onTap: () => onChanged(
                filter.copyWith(folderId: null, unfiledOnly: false),
              ),
            ),
            if (hasUnfiledNotes)
              _FilterChipItem(
                label: strings.folderNone,
                selected: filter.unfiledOnly,
                onTap: () => onChanged(
                  filter.copyWith(folderId: null, unfiledOnly: !filter.unfiledOnly),
                ),
              ),
            for (final folder in folders)
              _FilterChipItem(
                label: folder.name,
                selected: !filter.unfiledOnly && filter.folderId == folder.id,
                onTap: () {
                  final alreadySelected = !filter.unfiledOnly && filter.folderId == folder.id;
                  onChanged(
                    filter.copyWith(
                      folderId: alreadySelected ? null : folder.id,
                      unfiledOnly: false,
                    ),
                  );
                },
              ),
          ],
        ),
        _ChipRow(
          icon: Icons.label_outline,
          children: [
            if (tags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  '${strings.tagSection}：${strings.tagNone}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.6),
                      ),
                ),
              )
            else
              for (final tag in tags)
                _FilterChipItem(
                  label: tag,
                  selected: filter.tag == tag,
                  onTap: () => onChanged(
                    filter.copyWith(tag: filter.tag == tag ? null : tag),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.icon, required this.children});

  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.75),
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                for (var i = 0; i < children.length; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: 6),
                    child: children[i],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
