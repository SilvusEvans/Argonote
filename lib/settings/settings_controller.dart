import 'package:flutter/material.dart';

import '../data/settings_repository.dart';
import '../l10n/app_strings.dart';
import '../models/app_settings.dart';

/// 设置控制器：持有当前 [AppSettings]，负责「立即生效 + 落盘」。
///
/// 继承 [ChangeNotifier]，[app.dart] 里用 ListenableBuilder 包住 MaterialApp，
/// 任何一项设置变化都会重建整棵树，语言 / 配色 / 深浅模式立刻切换。
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository) : _settings = AppSettings.defaults();

  final SettingsRepository _repository;

  AppSettings _settings;
  bool _loaded = false;

  AppSettings get settings => _settings;
  AppLanguage get language => _settings.language;
  Locale get locale => _settings.locale;
  Color get seedColor => _settings.seedColor;
  ThemeMode get themeMode => _settings.themeMode;

  /// 启动时调用一次，载入上次保存的设置。
  Future<void> load() async {
    if (_loaded) return;
    final stored = await _repository.load();
    _settings = stored ?? AppSettings.defaults();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) =>
      _apply(_settings.copyWith(languageCode: language.code));

  Future<void> setSeedColor(Color color) =>
      _apply(_settings.copyWith(seedColorValue: color.toARGB32()));

  Future<void> setThemeMode(ThemeMode mode) =>
      _apply(_settings.copyWith(themeModeIndex: _themeModeIndex(mode)));

  Future<void> restoreDefaults() => _apply(AppSettings.defaults());

  /// 先更新内存并通知监听者（界面立即变），再写入存储。
  Future<void> _apply(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _repository.save(next);
  }

  static int _themeModeIndex(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 1,
        ThemeMode.dark => 2,
        ThemeMode.system => 0,
      };
}
