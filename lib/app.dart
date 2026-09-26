import 'package:flutter/material.dart';

import 'data/note_repository.dart';
import 'screens/note_list_screen.dart';

/// 应用根组件。
///
/// 仓储由外部注入（构造函数传入），而不是在 UI 里直接 new，
/// 这样测试时可以把内存实现塞进来，也方便以后换存储方案。
class ArgonoteApp extends StatelessWidget {
  const ArgonoteApp({super.key, required this.repository});

  final NoteRepository repository;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF4F7CFF);

    return MaterialApp(
      title: 'Argonote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: NoteListScreen(repository: repository),
    );
  }
}
