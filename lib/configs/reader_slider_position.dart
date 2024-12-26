import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

import '../commons.dart';

enum ReaderSliderPosition { bottom, right, left }

const _positionNames = {
  ReaderSliderPosition.bottom: '下方',
  ReaderSliderPosition.right: '右侧',
  ReaderSliderPosition.left: '左侧',
};

const _propertyName = "readerSliderPosition";
late ReaderSliderPosition _readerSliderPosition;

Future initReaderSliderPosition() async {
  _readerSliderPosition = _readerSliderPositionFromString(
    await native.loadProperty(k: _propertyName),
  );
}

ReaderSliderPosition _readerSliderPositionFromString(String str) {
  for (var value in ReaderSliderPosition.values) {
    if (str == value.toString()) return value;
  }
  return ReaderSliderPosition.bottom;
}

ReaderSliderPosition get currentReaderSliderPosition => _readerSliderPosition;

String currentReaderSliderPositionName() =>
    _positionNames[_readerSliderPosition] ?? "";

Future<void> chooseReaderSliderPosition(BuildContext context) async {
  Map<String, ReaderSliderPosition> map = {};
  _positionNames.forEach((key, value) {
    map[value] = key;
  });
  ReaderSliderPosition? result = await chooseMapDialog<ReaderSliderPosition>(
      context,
      values: map,
      title: "选择滑动条位置");
  if (result != null) {
    await native.saveProperty(k: _propertyName, v: result.toString());
    _readerSliderPosition = result;
  }
}

Widget readerSliderPositionSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("滚动条的位置"),
        subtitle: Text(currentReaderSliderPositionName()),
        onTap: () async {
          await chooseReaderSliderPosition(context);
          setState(() {});
        },
      );
    },
  );
}
