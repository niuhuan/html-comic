/// 列表页下一页的行为
import 'package:flutter/material.dart';

import '../commons.dart';
import '../ffi.dart';

enum PagerAction {
  controller,
  stream,
}

Map<String, PagerAction> _pagerActionMap = {
  "使用按钮": PagerAction.controller,
  "瀑布流": PagerAction.stream,
};

const _propertyName = "pagerAction";
late PagerAction _pagerAction;

Future<void> initPagerAction() async {
  var value = await native.loadProperty(k: _propertyName);
  if (value == "") value = PagerAction.controller.toString();
  _pagerAction = _pagerActionFromString(value);
}

PagerAction currentPagerAction() {
  return _pagerAction;
}

PagerAction _pagerActionFromString(String string) {
  for (var value in PagerAction.values) {
    if (string == value.toString()) {
      return value;
    }
  }
  return PagerAction.controller;
}

String _currentPagerActionName() {
  for (var e in _pagerActionMap.entries) {
    if (e.value == _pagerAction) {
      return e.key;
    }
  }
  return '';
}

Future<void> _choosePagerAction(BuildContext context) async {
  PagerAction? result = await chooseMapDialog<PagerAction>(
    context,
    values: _pagerActionMap,
    title: "选择列表页加载方式",
  );
  if (result != null) {
    await native.saveProperty(k: _propertyName, v: result.toString());
    _pagerAction = result;
  }
}

Widget pagerActionSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("列表页加载方式"),
        subtitle: Text(_currentPagerActionName()),
        onTap: () async {
          await _choosePagerAction(context);
          setState(() {});
        },
      );
    },
  );
}
