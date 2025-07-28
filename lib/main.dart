import 'dart:io';

import 'package:flutter/material.dart';
import 'package:auto_format_folder/tab_manager.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理器
  if (Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '格式化文件夹',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TabManager(),
      // 添加窗口圆角
      builder: (context, child) {
        if (Platform.isLinux) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: child!,
            ),
          );
        } else if (Platform.isWindows || Platform.isMacOS) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child!,
          );
        }
        return child!;
      },
    );
  }
}

