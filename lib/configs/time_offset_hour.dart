/// 时区设置
import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

import '../commons.dart';

const _propertyName = "timeOffsetHour";
int _timeOffsetHour = 8;

Future<void> initTimeZone() async {
  var value = await native.loadProperty(k: _propertyName);
  if (value == "") value = "8";
  _timeOffsetHour = int.parse(value);
}

int currentTimeOffsetHour() {
  return _timeOffsetHour;
}

Future<void> _chooseTimeZone(BuildContext context) async {
  List<String> timeZones = [];
  for (var i = -12; i <= 12; i++) {
    var str = i.toString();
    if (!str.startsWith("-")) {
      str = "+" + str;
    }
    timeZones.add(str);
  }
  String? result = await chooseListDialog<String>(
    context,
    title: "时区选择",
    values: timeZones,
  );
  if (result != null) {
    if (result.startsWith("+")) {
      result = result.substring(1);
    }
    _timeOffsetHour = int.parse(result);
    await native.saveProperty(k: _propertyName, v: result);
  }
}

Widget timeZoneSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      var c = "$_timeOffsetHour";
      if (!c.startsWith("-")) {
        c = "+" + c;
      }
      return ListTile(
        title: const Text("时区"),
        subtitle: Text(c),
        onTap: () async {
          await _chooseTimeZone(context);
          setState(() {});
        },
      );
    },
  );
}
