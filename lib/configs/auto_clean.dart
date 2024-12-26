/// 自动清理
import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

const _autoCleanMap = {
  "一个月前": "${1000 * 3600 * 24 * 30}",
  "一周前": "${1000 * 3600 * 24 * 7}",
  "一天前": "${1000 * 3600 * 24 * 1}",
  "不自动清理": "${0}",
};
late String _autoCleanSec;

Future<dynamic> initAutoClean() async {
  _autoCleanSec = await native.loadProperty(k: "autoCleanSec");
  if (_autoCleanSec == "") {
    _autoCleanSec = "${3600 * 24 * 30}";
  }
  if ("0" != _autoCleanSec) {
    await native.autoClean(time: int.parse(_autoCleanSec));
  }
}

String _currentAutoCleanSec() {
  for (var value in _autoCleanMap.entries) {
    if (value.value == _autoCleanSec) {
      return value.key;
    }
  }
  return "";
}

Future<void> _chooseAutoCleanSec(BuildContext context) async {
  String? choose = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text('选择自动清理周期'),
        children: <Widget>[
          ..._autoCleanMap.entries.map(
            (e) => SimpleDialogOption(
              child: Text(e.key),
              onPressed: () {
                Navigator.of(context).pop(e.value);
              },
            ),
          ),
        ],
      );
    },
  );
  if (choose != null) {
    await native.saveProperty(k: "autoCleanSec", v: choose);
    _autoCleanSec = choose;
  }
}

Widget autoCleanSecSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("自动清理缓存"),
        subtitle: Text(_currentAutoCleanSec()),
        onTap: () async {
          await _chooseAutoCleanSec(context);
          setState(() {});
        },
      );
    },
  );
}
