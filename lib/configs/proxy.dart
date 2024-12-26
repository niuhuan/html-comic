/// 代理设置
import 'package:flutter/material.dart';
import 'package:html/ffi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../commons.dart';

late String _currentProxy;
const String _k = "proxy";

Future initProxy() async {
  _currentProxy = await native.loadProperty(k: _k);
  await native.setProxy(url: _currentProxy);
}

String currentProxyName() {
  return _currentProxy == "" ? "未设置" : _currentProxy;
}

Future<dynamic> inputProxy(BuildContext context) async {
  String? input = await displayTextInputDialog(
    context,
    src: _currentProxy,
    title: AppLocalizations.of(context)!.proxy,
    hint: AppLocalizations.of(context)!.inputProxy,
    desc: AppLocalizations.of(context)!.proxyExample,
  );
  if (input != null) {
    await native.setProxy(url: input);
    await native.saveProperty(k: _k, v: input);
    _currentProxy = input;
  }
}

Widget proxySetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: Text(AppLocalizations.of(context)!.proxy),
        subtitle: Text(currentProxyName()),
        onTap: () async {
          await inputProxy(context);
          setState(() {});
        },
      );
    },
  );
}
