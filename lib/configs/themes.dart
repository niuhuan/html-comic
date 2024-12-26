/// 主题
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/ffi.dart';

import '../commons.dart';
import 'platform.dart';

// 字体相关

const _fontFamilyProperty = "fontFamily";

String? _fontFamily;

Future initFont() async {
  _fontFamily = await native.loadProperty(k: _fontFamilyProperty);
}

ThemeData _fontThemeData(bool dark) {
  return ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: _fontFamily == "" ? null : _fontFamily,
  );
}

Future<void> inputFont(BuildContext context) async {
  var font = await displayTextInputDialog(
    context,
    src: "$_fontFamily",
    title: "字体",
    hint: "请输入字体",
    desc:
        "请输入字体的名称, 例如宋体/黑体, 如果您保存后没有发生变化, 说明字体无法使用或名称错误, 可以去参考C:\\Windows\\Fonts寻找您的字体。",
  );
  if (font != null) {
    await native.saveProperty(k: _fontFamilyProperty, v: font);
    _fontFamily = font;
    _reloadTheme();
  }
}

Widget fontSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text("字体"),
        subtitle: Text("$_fontFamily"),
        onTap: () async {
          await inputFont(context);
          setState(() {});
        },
      );
    },
  );
}

// 主题相关

// 主题包
abstract class _ThemePackage {
  String code();

  String name();

  ThemeData themeData(ThemeData rawData);

  bool isDark();
}

class _OriginTheme extends _ThemePackage {
  @override
  String code() => "origin";

  @override
  String name() => "原生";

  @override
  ThemeData themeData(ThemeData rawData) => rawData;

  @override
  bool isDark() => false;
}

class _PinkTheme extends _ThemePackage {
  @override
  String code() => "pink";

  @override
  String name() => "粉色";

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          secondary: Colors.pink.shade200,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Colors.pink.shade200,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.pink[300],
          unselectedItemColor: Colors.grey[500],
        ),
        dividerColor: Colors.grey.shade200,
        primaryColor: Colors.pink.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.pink.shade200,
          selectionColor: Colors.pink.shade300.withAlpha(150),
          selectionHandleColor: Colors.pink.shade300.withAlpha(200),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink.shade200),
          ),
        ),
      );

  @override
  bool isDark() => false;
}

class _BlackTheme extends _ThemePackage {
  @override
  String code() => "black";

  @override
  String name() => "酷黑";

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          secondary: Colors.pink.shade200,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Colors.grey.shade800,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.grey.shade800,
        ),
        dividerColor: Colors.grey.shade200,
        primaryColor: Colors.pink.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.pink.shade200,
          selectionColor: Colors.pink.shade300.withAlpha(150),
          selectionHandleColor: Colors.pink.shade300.withAlpha(200),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink.shade200),
          ),
        ),
      );

  @override
  bool isDark() => false;
}

class _DarkTheme extends _ThemePackage {
  @override
  String code() => "dark";

  @override
  String name() => "暗黑";

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.light(
          secondary: Colors.pink.shade200,
        ),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade300,
          backgroundColor: Colors.grey.shade900,
        ),
        primaryColor: Colors.pink.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.pink.shade200,
          selectionColor: Colors.pink.shade300.withAlpha(150),
          selectionHandleColor: Colors.pink.shade300.withAlpha(200),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink.shade200),
          ),
        ),
      );

  @override
  bool isDark() => true;
}

class _DustyBlueTheme extends _ThemePackage {
  @override
  String code() => "dustyBlue";

  @override
  String name() => "灰蓝";

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color.alphaBlend(
          const Color(0x11999999),
          const Color(0xff20253b),
        ),
        cardColor: Color.alphaBlend(
          const Color(0x11AAAAAA),
          const Color(0xff20253b),
        ),
        colorScheme: ColorScheme.light(
          secondary: Colors.blue.shade200,
        ),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Color(0xff20253b),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        dialogTheme: const DialogTheme(
          backgroundColor: Color(0xff20253b),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xff191b26),
          selectedItemColor: Colors.blue.shade200,
          unselectedItemColor: Colors.grey.shade500,
        ),
        dividerColor: Colors.grey.shade800,
        primaryColor: Colors.blue.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue.shade200,
          selectionColor: Colors.blue.shade900,
          selectionHandleColor: Colors.blue.shade800,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade500),
          ),
        ),
      );

  @override
  bool isDark() => true;
}

class _DarkBlackTheme extends _ThemePackage {
  @override
  String code() => "dark_black";

  @override
  String name() => "纯黑";

  @override
  ThemeData themeData(ThemeData rawData) => rawData.copyWith(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.light(
          secondary: Colors.pink.shade200,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          color: Color.fromARGB(0xff, 10, 10, 10),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade300,
          backgroundColor: const Color.fromARGB(0xff, 10, 10, 10),
        ),
        primaryColor: Colors.pink.shade200,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.pink.shade200,
          selectionColor: Colors.pink.shade300.withAlpha(150),
          selectionHandleColor: Colors.pink.shade300.withAlpha(200),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink.shade200),
          ),
        ),
        dividerColor: const Color.fromARGB(0xff, 64, 64, 64),
      );

  @override
  bool isDark() => true;
}

final _themePackages = <_ThemePackage>[
  _OriginTheme(),
  _PinkTheme(),
  _BlackTheme(),
  _DarkTheme(),
  _DustyBlueTheme(),
  _DarkBlackTheme(),
];

// 主题更换事件
var themeEvent = Event<EventArgs>();

const _nightModePropertyName = "androidNightMode";
const _lightThemePropertyName = "theme";
const _darkThemePropertyName = "theme.dark";
const _defaultLightThemeCode = "origin";
const _defaultDarkThemeCode = "dark";
bool androidNightModeDisplay = false;
bool androidNightMode = false;

String? _lightThemeCode;
ThemeData? _lightThemeData;
String? _darkThemeCode;
ThemeData? _darkThemeData;

// _changeThemeByCode

String _codeToName(String? code) {
  for (var package in _themePackages) {
    if (code == package.code()) {
      return package.name();
    }
  }
  return "";
}

String currentLightThemeName() {
  return _codeToName(_lightThemeCode);
}

String currentDarkThemeName() {
  return _codeToName(_darkThemeCode);
}

ThemeData? currentLightThemeData() {
  return _lightThemeData;
}

ThemeData? currentDarkThemeData() {
  return _darkThemeData;
}

// 根据Code选择主题, 并发送主题更换事件

ThemeData? _themeByCode(String? themeCode) {
  for (var package in _themePackages) {
    if (themeCode == package.code()) {
      return package.themeData(_fontThemeData(package.isDark()));
    }
  }
  return null;
}

void _reloadTheme() {
  _lightThemeData = _themeByCode(_lightThemeCode);
  if (androidNightMode) {
    _darkThemeData = _themeByCode(_darkThemeCode);
  } else {
    _darkThemeData = _lightThemeData;
  }
  themeEvent.broadcast();
}

Future<dynamic> initTheme() async {
  androidNightModeDisplay = androidVersion >= 29;
  var an = await native.loadProperty(k: _nightModePropertyName);
  androidNightMode = an == "" || an == "true";
  _lightThemeCode = await native.loadProperty(k: _lightThemePropertyName);
  if (_lightThemeCode == "") {
    _lightThemeCode = _defaultLightThemeCode;
  }
  _darkThemeCode = await native.loadProperty(k: _darkThemePropertyName);
  if (_darkThemeCode == "") _darkThemeCode = _defaultDarkThemeCode;
  _reloadTheme();
}

// 选择主题的对话框
Future<String?> _chooseTheme(BuildContext buildContext) {
  return showDialog<String>(
    context: buildContext,
    builder: (BuildContext context) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
        var list = <SimpleDialogOption>[];
        list.addAll(_themePackages.map((e) => SimpleDialogOption(
              child: Text(e.name()),
              onPressed: () {
                Navigator.of(context).pop(e.code());
              },
            )));
        return SimpleDialog(
          title: const Text("选择主题"),
          children: list,
        );
      });
    },
  );
}

Future<dynamic> chooseLightTheme(BuildContext buildContext) async {
  String? theme = await _chooseTheme(buildContext);
  if (theme != null) {
    await native.saveProperty(k: _lightThemePropertyName, v: theme);
    _lightThemeCode = theme;
    _reloadTheme();
  }
}

Future<dynamic> chooseDarkTheme(BuildContext buildContext) async {
  String? theme = await _chooseTheme(buildContext);
  if (theme != null) {
    await native.saveProperty(k: _darkThemePropertyName, v: theme);
    _darkThemeCode = theme;
    _reloadTheme();
  }
}

Future setAndroidNightMode(bool value) async {
  await native.saveProperty(k: _nightModePropertyName, v: "$value");
  androidNightMode = value;
  _reloadTheme();
}
