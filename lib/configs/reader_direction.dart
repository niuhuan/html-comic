/// 阅读器的方向
import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

enum ReaderDirection {
  topToBottom,
  leftToRight,
  rightToLeft,
}

const _types = {
  '从上到下': ReaderDirection.topToBottom,
  '从左到右': ReaderDirection.leftToRight,
  '从右到左': ReaderDirection.rightToLeft,
};

const _propertyName = "readerDirection";
late ReaderDirection _readerDirection;

ReaderDirection get gReaderDirection => _readerDirection;

Future<void> initReaderDirection() async {
  var value = await native.loadProperty(k: _propertyName);
  if (value == "") {
    value = ReaderDirection.topToBottom.toString();
  }
  _readerDirection = _pagerDirectionFromString(value);
}

ReaderDirection _pagerDirectionFromString(String pagerDirectionString) {
  for (var value in ReaderDirection.values) {
    if (pagerDirectionString == value.toString()) {
      return value;
    }
  }
  return ReaderDirection.topToBottom;
}

String currentReaderDirectionName() {
  for (var e in _types.entries) {
    if (e.value == _readerDirection) {
      return e.key;
    }
  }
  return '';
}

/// ?? to ActionButton And Event ??
Future<void> choosePagerDirection(BuildContext buildContext) async {
  ReaderDirection? choose = await showDialog<ReaderDirection>(
    context: buildContext,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text("选择翻页方向"),
        children: _types.entries
            .map((e) => SimpleDialogOption(
                  child: Text(e.key),
                  onPressed: () {
                    Navigator.of(context).pop(e.value);
                  },
                ))
            .toList(),
      );
    },
  );
  if (choose != null) {
    await native.saveProperty(k: _propertyName, v: choose.toString());
    _readerDirection = choose;
  }
}

Widget readerDirectionSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("阅读器方向"),
        subtitle: Text(currentReaderDirectionName()),
        onTap: () async {
          await choosePagerDirection(context);
          setState(() {});
        },
      );
    },
  );
}
