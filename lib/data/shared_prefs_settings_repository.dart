import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import 'settings_repository.dart';

/// 基于 shared_preferences 的设置持久化。
///
/// 设置项很少，直接整体序列化成一个 JSON 对象存在单个 key 下。
class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  static const String storageKey = 'argonote.settings.v1';

  final SharedPreferences _prefs;

  @override
  Future<AppSettings?> load() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return AppSettings.fromJson(decoded);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(storageKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(storageKey);
  }
}
