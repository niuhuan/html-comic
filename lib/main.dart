import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:html/configs/themes.dart';
import 'package:html/screens/components/mouse_and_touch_scroll_behavior.dart';
import 'package:html/screens/components/navigator.dart';
import 'package:html/screens/init_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: currentLightThemeData(),
      darkTheme: currentDarkThemeData(),
      navigatorObservers: [
        routeObserver,
        navigatorObserver,
      ],
      debugShowCheckedModeBanner: false,
      scrollBehavior: mouseAndTouchScrollBehavior,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const InitScreen(),
    );
  }
}
