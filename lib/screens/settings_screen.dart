import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../settings/settings_controller.dart';

/// 设置页：界面语言 + 主题配色 + 深浅模式。
///
/// 全部采用 Material 3 控件（Card / RadioListTile / SegmentedButton / FilledButton），
/// 与列表页、编辑页的视觉风格保持一致。
/// 任何一项改动都会通过 [SettingsController] 立即生效并写入本地存储。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final settings = controller.settings;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SectionCard(
                title: strings.languageSection,
                subtitle: strings.languageSubtitle,
                child: RadioGroup<AppLanguage>(
                  groupValue: settings.language,
                  onChanged: (value) {
                    if (value == null) return;
                    _apply(context, () => controller.setLanguage(value));
                  },
                  child: Column(
                    children: [
                      for (final language in AppLanguage.values)
                        RadioListTile<AppLanguage>(
                          value: language,
                          title: Text(language.label),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: strings.themeColorSection,
                subtitle: strings.themeColorSubtitle,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in AppSettings.seedColorPresets)
                      _ColorSwatch(
                        color: color,
                        selected: settings.seedColor.toARGB32() == color.toARGB32(),
                        onTap: () => _apply(context, () => controller.setSeedColor(color)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: strings.themeModeSection,
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto_outlined),
                        label: Text(strings.themeModeSystem),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined),
                        label: Text(strings.themeModeLight),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(strings.themeModeDark),
                      ),
                    ],
                    selected: <ThemeMode>{settings.themeMode},
                    onSelectionChanged: (selection) {
                      _apply(context, () => controller.setThemeMode(selection.first));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _apply(context, controller.restoreDefaults),
                icon: const Icon(Icons.restart_alt),
                label: Text(strings.restoreDefaults),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 统一处理「改设置 → 提示已保存」。
  ///
  /// 提示文案必须等这一帧重建之后再取：改语言的那一次操作会让整棵
  /// MaterialApp 用新 locale 重建，若在 await 之前读 AppStrings，
  /// 切到英文后弹出的确认条还是旧语言（中文）的。
  Future<void> _apply(BuildContext context, Future<void> Function() action) async {
    await action();
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;
    final strings = AppStrings.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.settingsApplied),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                ),
              ),
            ],
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? theme.colorScheme.onSurface : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 26)
            : null,
      ),
    );
  }
}
