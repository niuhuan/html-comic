import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// todo save origin image in android // like with filesystem_picker

import 'commons.dart';
import 'ffi.dart';

const cross = Cross._();

class Cross {
  const Cross._();

  static const _channel = MethodChannel("cross");

  Future<String> root(BuildContext context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _channel.invokeMethod("root");
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return await native.desktopRoot();
    }
    throw AppLocalizations.of(context)!.unsupportedPlatform;
  }

  Future saveImageFileToGallery(String path, BuildContext context) async {
    if (Platform.isIOS || Platform.isAndroid) {
      if (Platform.isAndroid) {
        if (!(await Permission.storage.request()).isGranted) {
          return;
        }
      }
      try {
        await _channel.invokeMethod("saveImageToGallery", path);
        defaultToast(context, AppLocalizations.of(context)!.success);
      } catch (e) {
        errorToast(context, AppLocalizations.of(context)!.failed + " : $e");
      }
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        try {
          await native.copyImageTo(srcPath: path, toDir: selectedDirectory);
          defaultToast(context, AppLocalizations.of(context)!.success);
        } catch (e) {
          errorToast(context, AppLocalizations.of(context)!.failed + " : $e");
        }
      }
    }
  }

  Future<List<String>> loadAndroidModes() async {
    return List.of(await _channel.invokeMethod("androidGetModes"))
        .map((e) => "$e")
        .toList();
  }

  Future setAndroidMode(String androidDisplayMode) {
    return _channel
        .invokeMethod("androidSetMode", {"mode": androidDisplayMode});
  }

  Future androidSecureFlag(bool flag) {
    return _channel.invokeMethod("androidSecureFlag", {
      "flag": flag,
    });
  }

  Future<int> androidGetVersion() async {
    return await _channel.invokeMethod("androidGetVersion", {});
  }
}

/// 打开web页面
Future<dynamic> openUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(
      url,
      forceSafariVC: false,
    );
  }
}
