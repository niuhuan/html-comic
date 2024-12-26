/// 自动全屏
import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

import '../commons.dart';

const _propertyName = "exportRename";
late bool _exportRename;

Future<void> initExportRename() async {
  _exportRename = (await native.loadProperty(k: _propertyName)) == "true";
}

bool currentExportRename() {
  return _exportRename;
}

Future<void> _chooseExportRename(BuildContext context) async {
  String? result = await chooseListDialog<String>(
    context,
    title: "导出时进行重命名",
    values: ["是", "否"],
  );
  if (result != null) {
    var target = result == "是";
    await native.saveProperty(k: _propertyName, v: "$target");
    _exportRename = target;
  }
}

Widget exportRenameSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("导出时进行重命名"),
        subtitle: Text(_exportRename ? "是" : "否"),
        onTap: () async {
          await _chooseExportRename(context);
          setState(() {});
        },
      );
    },
  );
}
