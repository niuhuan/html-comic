/// 音量键翻页
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html/cross.dart';
import 'package:html/ffi.dart';

import '../commons.dart';

const _propertyName = "androidSecureFlag";

late bool _androidSecureFlag;

Future<void> initAndroidSecureFlag() async {
  if (Platform.isAndroid) {
    _androidSecureFlag =
        (await native.loadProperty(k: _propertyName)) == "true";
    if (_androidSecureFlag) {
      await cross.androidSecureFlag(true);
    }
  }
}

Future<void> _chooseAndroidSecureFlag(BuildContext context) async {
  String? result = await chooseListDialog<String>(
    context,
    title: "禁止截图/禁止显示在任务视图",
    values: ["是", "否"],
  );
  if (result != null) {
    var target = result == "是";
    await native.saveProperty(k: _propertyName, v: "$target");
    _androidSecureFlag = target;
    await cross.androidSecureFlag(_androidSecureFlag);
  }
}

Widget androidSecureFlagSetting() {
  if (Platform.isAndroid) {
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
          title: const Text("禁止截图/禁止显示在任务视图"),
          subtitle: Text(_androidSecureFlag ? "是" : "否"),
          onTap: () async {
            await _chooseAndroidSecureFlag(context);
            setState(() {});
          });
    });
  }
  return Container();
}
