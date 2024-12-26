/// 上下键翻页
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

import '../commons.dart';

const _propertyName = "keyboardController";

late bool keyboardController;

Future<void> initKeyboardController() async {
  keyboardController = (await native.loadProperty(k: _propertyName)) == "true";
}

Future<void> _chooseKeyboardController(BuildContext context) async {
  String? result = await chooseListDialog<String>(
    context,
    title: "键盘控制翻页",
    values: ["是", "否"],
  );
  if (result != null) {
    var target = result == "是";
    await native.saveProperty(k: _propertyName, v: "$target");
    keyboardController = target;
  }
}

Widget keyboardControllerSetting() {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        return ListTile(
          title: const Text("阅读器键盘翻页(仅PC)"),
          subtitle: Text(keyboardController ? "是" : "否"),
          onTap: () async {
            await _chooseKeyboardController(context);
            setState(() {});
          },
        );
      },
    );
  }
  return Container();
}
