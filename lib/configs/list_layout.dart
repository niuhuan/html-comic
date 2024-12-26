/// 列表页的布局
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:html/ffi.dart';

import '../commons.dart';

enum ListLayout {
  infoCard,
  onlyImage,
  coverAndTitle,
}

const Map<String, ListLayout> _listLayoutMap = {
  '详情': ListLayout.infoCard,
  '封面': ListLayout.onlyImage,
  '封面+标题': ListLayout.coverAndTitle,
};

const _propertyName = "listLayout";
late ListLayout currentLayout;

var listLayoutEvent = Event<EventArgs>();

Future<void> initListLayout() async {
  var value = await native.loadProperty(
    k: _propertyName,
  );
  if (value == "") value = ListLayout.infoCard.toString();
  currentLayout = _listLayoutFromString(value);
}

ListLayout _listLayoutFromString(String layoutString) {
  for (var value in ListLayout.values) {
    if (layoutString == value.toString()) {
      return value;
    }
  }
  return ListLayout.infoCard;
}

void _chooseListLayout(BuildContext context) async {
  ListLayout? layout = await chooseMapDialog(
    context,
    values: _listLayoutMap,
    title: '请选择布局',
  );
  if (layout != null) {
    await native.saveProperty(k: _propertyName, v: layout.toString());
    currentLayout = layout;
    listLayoutEvent.broadcast();
  }
}

IconButton chooseLayoutActionButton(BuildContext context) => IconButton(
      onPressed: () {
        _chooseListLayout(context);
      },
      icon: const Icon(Icons.view_quilt),
    );
