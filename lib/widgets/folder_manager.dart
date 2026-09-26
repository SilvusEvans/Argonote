import 'package:flutter/material.dart';

import '../data/folder_repository.dart';
import '../l10n/app_strings.dart';
import '../models/folder.dart';

/// 文件夹管理弹窗：新建 / 重命名 / 删除。
///
/// 删除文件夹只解除笔记的归属关系，不会删笔记（列表里会显示为「未归类」）。
Future<void> showFolderManager({
  required BuildContext context,
  required FolderRepository repository,
  required AppStrings strings,
  required VoidCallback onChanged,
}) async {
  final nameController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          /// setState 会让下面的 FutureBuilder 重新拉取列表；
          /// onChanged 通知外层笔记列表刷新（文件夹改名 / 删除后要跟着变）。
          void refresh() {
            setState(() {});
            onChanged();
          }

          Future<void> create() async {
            final name = nameController.text.trim();
            if (name.isEmpty) return;
            await repository.create(name);
            nameController.clear();
            refresh();
          }

          Future<void> rename(Folder folder) async {
            final controller = TextEditingController(text: folder.name);
            final newName = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.folderLabel),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(hintText: strings.folderNameHint),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                    child: Text(strings.save),
                  ),
                ],
              ),
            );
            if (newName != null && newName.isNotEmpty) {
              await repository.rename(folder.id, newName);
              refresh();
            }
          }

          Future<void> remove(Folder folder) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.deleteFolderTitle),
                content: Text(strings.deleteFolderMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(strings.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(strings.delete),
                  ),
                ],
              ),
            );
            if (confirmed ?? false) {
              await repository.delete(folder.id);
              refresh();
            }
          }

          return AlertDialog(
            title: Text(strings.folderSection),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: strings.folderNameHint,
                            isDense: true,
                          ),
                          onSubmitted: (_) => create(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: create,
                        child: Text(strings.newFolder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: FutureBuilder<List<Folder>>(
                      // 每次 setState 都会生成新的 Future，从而重新加载。
                      future: repository.all(),
                      builder: (context, snapshot) {
                        final folders = snapshot.data ?? const <Folder>[];
                        if (folders.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(strings.tagNone),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.folder_open_outlined),
                              title: Text(folder.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: strings.editTitle,
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => rename(folder),
                                  ),
                                  IconButton(
                                    tooltip: strings.delete,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => remove(folder),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(strings.confirm),
              ),
            ],
          );
        },
      );
    },
  );
}
