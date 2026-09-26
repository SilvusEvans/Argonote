import '../models/app_settings.dart';

/// 设置仓储接口。
///
/// 和 [NoteRepository] 一样只暴露抽象，UI 不关心落在 SharedPreferences 还是内存里。
abstract class SettingsRepository {
  /// 读取已保存的设置；从未保存过时返回 null（由调用方使用默认值）。
  Future<AppSettings?> load();

  Future<void> save(AppSettings settings);

  Future<void> clear();
}
