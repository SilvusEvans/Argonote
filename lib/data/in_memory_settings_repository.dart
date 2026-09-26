import '../models/app_settings.dart';
import 'settings_repository.dart';

/// 内存版设置仓储，供测试使用。
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([AppSettings? initial]) : _settings = initial;

  AppSettings? _settings;

  @override
  Future<AppSettings?> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> clear() async {
    _settings = null;
  }
}
