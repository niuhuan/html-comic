/// 阅读器的类型
import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

enum ReaderType {
  webToon,
  webToonZoom,
  gallery,
  webToonFreeZoom,
}

const _types = {
  'WebToon (默认)': ReaderType.webToon,
  'WebToon (双击放大)': ReaderType.webToonZoom,
  '相册': ReaderType.gallery,
  'WebToon (ListView双击放大)\n(此模式进度条无效)': ReaderType.webToonFreeZoom
};

const _propertyName = "readerType";
late ReaderType _readerType;

Future<dynamic> initReaderType() async {
  var value = await native.loadProperty(k: _propertyName);
  if (value == "") value = ReaderType.webToon.toString();
  _readerType = _readerTypeFromString(value);
}

ReaderType get currentReaderType => _readerType;

ReaderType _readerTypeFromString(String pagerTypeString) {
  for (var value in ReaderType.values) {
    if (pagerTypeString == value.toString()) {
      return value;
    }
  }
  return ReaderType.webToon;
}

String currentReaderTypeName() {
  for (var e in _types.entries) {
    if (e.value == _readerType) {
      return e.key;
    }
  }
  return '';
}

Future<void> choosePagerType(BuildContext buildContext) async {
  ReaderType? t = await showDialog<ReaderType>(
    context: buildContext,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text("选择阅读模式"),
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
  if (t != null) {
    await native.saveProperty(k: _propertyName, v: t.toString());
    _readerType = t;
  }
}

Widget readerTypeSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("阅读器模式"),
        subtitle: Text(currentReaderTypeName()),
        onTap: () async {
          await choosePagerType(context);
          setState(() {});
        },
      );
    },
  );
}
