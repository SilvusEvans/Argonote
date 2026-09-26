import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/shared_prefs_folder_repository.dart';
import 'data/shared_prefs_note_repository.dart';
import 'data/shared_prefs_settings_repository.dart';
import 'settings/settings_controller.dart';

Future<void> main() async {
  // main 里要 await SharedPreferences（走平台通道），
  // 必须先确保 Flutter 引擎绑定已经初始化。
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final noteRepository = SharedPrefsNoteRepository(prefs);
  final folderRepository = SharedPrefsFolderRepository(prefs);

  final settingsController = SettingsController(SharedPrefsSettingsRepository(prefs));
  // 先恢复上次的语言 / 配色，再渲染，避免启动瞬间闪一下默认主题。
  await settingsController.load();

  runApp(
    ArgonoteApp(
      repository: noteRepository,
      folderRepository: folderRepository,
      settingsController: settingsController,
    ),
  );
}
