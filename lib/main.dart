import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/shared_prefs_note_repository.dart';

Future<void> main() async {
  // main 里要 await SharedPreferences（走平台通道），
  // 必须先确保 Flutter 引擎绑定已经初始化。
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final repository = SharedPrefsNoteRepository(prefs);

  runApp(ArgonoteApp(repository: repository));
}
