/// 音量键翻页
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

import '../commons.dart';

const _propertyName = "volumeController";
late bool volumeController;

Future<void> initVolumeController() async {
  volumeController = (await native.loadProperty(k: _propertyName)) == "true";
}

Future<void> _chooseVolumeController(BuildContext context) async {
  String? result = await chooseListDialog<String>(
    context,
    title: "音量键控制翻页",
    values: ["是", "否"],
  );
  if (result != null) {
    var target = result == "是";
    await native.saveProperty(k: _propertyName, v: "$target");
    volumeController = target;
  }
}

Widget volumeControllerSetting() {
  if (Platform.isAndroid) {
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
          title: const Text("阅读器音量键翻页"),
          subtitle: Text(volumeController ? "是" : "否"),
          onTap: () async {
            await _chooseVolumeController(context);
            setState(() {});
          });
    });
  }
  return Container();
}
