import 'package:flutter/material.dart';
import '../configs/themes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.theme)),
      body: ListView(
        children: [
          const Divider(),
          ListTile(
            onTap: () async {
              await chooseLightTheme(context);
              setState(() {});
            },
            title: Text(AppLocalizations.of(context)!.theme),
            subtitle: Text(currentLightThemeName()),
          ),
          const Divider(),
          ...androidNightModeDisplay
              ? [
                  SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.enableDarkMode),
                      value: androidNightMode,
                      onChanged: (value) async {
                        await setAndroidNightMode(value);
                        setState(() {});
                      }),
                ]
              : [],
          const Divider(),
          ...androidNightModeDisplay && androidNightMode
              ? [
                  ListTile(
                    onTap: () async {
                      await chooseDarkTheme(context);
                      setState(() {});
                    },
                    title: Text(AppLocalizations.of(context)!.themeDark),
                    subtitle: Text(currentDarkThemeName()),
                  ),
                ]
              : [],
          const Divider(),
        ],
      ),
    );
  }
}
