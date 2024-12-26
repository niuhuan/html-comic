import 'package:flutter/material.dart';
import 'package:html/configs/proxy.dart';
import 'package:html/screens/about_screen.dart';
import 'package:html/screens/components/badge.dart';
import 'package:html/screens/theme_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../configs/themes.dart';
import '../configs/android_secure_flag.dart';
import '../configs/auto_clean.dart';
import '../configs/auto_full_screen.dart';
import '../configs/content_failed_reload_action.dart';
import '../configs/full_screen_action.dart';
import '../configs/keyboard_controller.dart';
import '../configs/no_animation.dart';
import '../configs/pager_action.dart';
import '../configs/reader_direction.dart';
import '../configs/reader_slider_position.dart';
import '../configs/reader_type.dart';
import '../configs/time_offset_hour.dart';
import '../configs/volume_controller.dart';
import '../configs/android_display_mode.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(children: [
        const Divider(),
        ListTile(
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            );
          },
          title: VersionBadged(
            child: Text(AppLocalizations.of(context)!.about),
          ),
        ),
        const Divider(),
        ListTile(
          onTap: () async {
            if (androidNightModeDisplay) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemeScreen()),
              );
            } else {
              chooseLightTheme(context);
            }
          },
          title: Text(AppLocalizations.of(context)!.theme),
        ),
        const Divider(),
        proxySetting(),
        const Divider(),
        const Divider(),
        pagerActionSetting(),
        contentFailedReloadActionSetting(),
        timeZoneSetting(),
        const Divider(),
        readerTypeSetting(),
        readerDirectionSetting(),
        readerSliderPositionSetting(),
        autoFullScreenSetting(),
        fullScreenActionSetting(),
        volumeControllerSetting(),
        keyboardControllerSetting(),
        noAnimationSetting(),
        const Divider(),
        const Divider(),
        autoCleanSecSetting(),
        ListTile(
          onTap: () {
            // todo
          },
          title: Text(AppLocalizations.of(context)!.clearCache),
        ),
        const Divider(),
        const Divider(),
        androidDisplayModeSetting(),
        androidSecureFlagSetting(),
        const Divider(),
        fontSetting(),
        const Divider(),
      ]),
    );
  }
}
