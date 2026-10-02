import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/note_repository.dart';
import 'data/notebook_repository.dart';
import 'l10n/app_strings.dart';
import 'models/app_settings.dart';
import 'screens/home_shell.dart';
import 'settings/settings_controller.dart';

/// 应用根组件。
///
/// 仓储由外部注入（构造函数传入），而不是在 UI 里直接 new，
/// 这样测试时可以把内存实现塞进来，也方便以后换存储方案。
///
/// 用 [ListenableBuilder] 监听 [SettingsController]：
/// 语言 / 主色 / 深浅模式一改，这里整棵 MaterialApp 重建，立即生效。
class ArgonoteApp extends StatelessWidget {
  const ArgonoteApp({
    super.key,
    required this.noteRepository,
    required this.notebookRepository,
    required this.settingsController,
  });

  final NoteRepository noteRepository;
  final NotebookRepository notebookRepository;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, _) {
        final AppSettings settings = settingsController.settings;

        return MaterialApp(
          title: 'Argonote',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(settings.seedColor, Brightness.light),
          darkTheme: _buildTheme(settings.seedColor, Brightness.dark),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: AppLanguage.values.map((language) => language.locale).toList(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HomeShell(
            noteRepository: noteRepository,
            notebookRepository: notebookRepository,
            settingsController: settingsController,
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness),
      useMaterial3: true,
    );
  }
}
