/// 全屏操作
import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

import '../commons.dart';

enum ContentFailedReloadAction {
  pullDown,
  touchLoader,
}

const _propertyName = "contentFailedReloadAction";
late ContentFailedReloadAction contentFailedReloadAction;

Future<void> initContentFailedReloadAction() async {
  var value = await native.loadProperty(k: _propertyName);
  if (value == "") {
    value = ContentFailedReloadAction.pullDown.toString();
  }
  contentFailedReloadAction = _contentFailedReloadActionFromString(value);
}

ContentFailedReloadAction _contentFailedReloadActionFromString(String string) {
  for (var value in ContentFailedReloadAction.values) {
    if (string == value.toString()) {
      return value;
    }
  }
  return ContentFailedReloadAction.pullDown;
}

Map<String, ContentFailedReloadAction> _contentFailedReloadActionMap = {
  "下拉刷新": ContentFailedReloadAction.pullDown,
  "点击屏幕刷新": ContentFailedReloadAction.touchLoader,
};

String _currentContentFailedReloadActionName() {
  for (var e in _contentFailedReloadActionMap.entries) {
    if (e.value == contentFailedReloadAction) {
      return e.key;
    }
  }
  return '';
}

Future<void> _chooseContentFailedReloadAction(BuildContext context) async {
  ContentFailedReloadAction? result =
      await chooseMapDialog<ContentFailedReloadAction>(
    context,
    values: _contentFailedReloadActionMap,
    title: "选择页面加载失败刷新的方式",
  );
  if (result != null) {
    await native.saveProperty(k: _propertyName, v: result.toString());
    contentFailedReloadAction = result;
  }
}

Widget contentFailedReloadActionSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("加载失败时"),
        subtitle: Text(_currentContentFailedReloadActionName()),
        onTap: () async {
          await _chooseContentFailedReloadAction(context);
          setState(() {});
        },
      );
    },
  );
}
