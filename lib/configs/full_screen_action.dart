/// 全屏操作
import 'package:flutter/material.dart';
import 'package:html/ffi.dart';
import '../commons.dart';

enum FullScreenAction {
  touchOnce,
  controller,
  touchDouble,
  touchDoubleOnceNext,
  threeArea,
}

Map<String, FullScreenAction> _fullScreenActionMap = {
  "点击屏幕一次全屏": FullScreenAction.touchOnce,
  "使用控制器全屏": FullScreenAction.controller,
  "双击屏幕全屏": FullScreenAction.touchDouble,
  "双击屏幕全屏 + 单击屏幕下一页": FullScreenAction.touchDoubleOnceNext,
  "将屏幕划分成三个区域 (上一页, 下一页, 全屏)": FullScreenAction.threeArea,
};

const _defaultController = FullScreenAction.touchOnce;
const _propertyName = "fullScreenAction";
late FullScreenAction _fullScreenAction;

Future<void> initFullScreenAction() async {
  var value = await native.loadProperty(k: _propertyName);
  if (value == "") value = FullScreenAction.touchOnce.toString();
  _fullScreenAction = _fullScreenActionFromString(value);
}

FullScreenAction get currentFullScreenAction => _fullScreenAction;

FullScreenAction _fullScreenActionFromString(String string) {
  for (var value in FullScreenAction.values) {
    if (string == value.toString()) {
      return value;
    }
  }
  return _defaultController;
}

String currentFullScreenActionName() {
  for (var e in _fullScreenActionMap.entries) {
    if (e.value == _fullScreenAction) {
      return e.key;
    }
  }
  return '';
}

Future<void> chooseFullScreenAction(BuildContext context) async {
  FullScreenAction? result = await chooseMapDialog<FullScreenAction>(context,
      values: _fullScreenActionMap, title: "选择操控方式");
  if (result != null) {
    await native.saveProperty(k: _propertyName, v: result.toString());
    _fullScreenAction = result;
  }
}

Widget fullScreenActionSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("操控方式"),
        subtitle: Text(currentFullScreenActionName()),
        onTap: () async {
          await chooseFullScreenAction(context);
          setState(() {});
        },
      );
    },
  );
}
