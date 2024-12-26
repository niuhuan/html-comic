import 'package:flutter/material.dart';

import '../configs/export_rename.dart';
import '../configs/platform.dart';
import '../configs/proxy.dart';
import '../configs/android_display_mode.dart';
import '../configs/android_secure_flag.dart';
import '../configs/auto_clean.dart';
import '../configs/auto_full_screen.dart';
import '../configs/content_failed_reload_action.dart';
import '../configs/full_screen_action.dart';
import '../configs/keyboard_controller.dart';
import '../configs/list_layout.dart';
import '../configs/no_animation.dart';
import '../configs/pager_action.dart';
import '../configs/reader_direction.dart';
import '../configs/reader_slider_position.dart';
import '../configs/reader_type.dart';
import '../configs/themes.dart';
import '../configs/time_offset_hour.dart';
import '../configs/version.dart';
import '../configs/volume_controller.dart';
import '../cross.dart';
import '../ffi.dart';
import 'comics_screen.dart';

// 初始化界面
class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  initState() {
    _init();
    super.initState();
  }

  Future<dynamic> _init() async {
    // 初始化配置文件
    await native.init(root: await cross.root(context));
    await initPlatform(); // 必须第一个初始化, 加载设备信息
    await initAutoClean();
    await initProxy();
    await initFont();
    await initTheme();
    await initListLayout();
    await initReaderType();
    await initReaderDirection();
    await initReaderSliderPosition();
    await initAutoFullScreen();
    await initFullScreenAction();
    await initPagerAction();
    await initContentFailedReloadAction();
    await initVolumeController();
    await initKeyboardController();
    await initAndroidDisplayMode();
    await initTimeZone();
    await initAndroidSecureFlag();
    await initNoAnimation();
    await initExportRename();
    await initVersion();
    autoCheckNewVersion();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ComicsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8abedc),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Image.asset(
          "lib/assets/init.png",
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
