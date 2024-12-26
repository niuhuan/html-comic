import 'package:flutter/material.dart';
import '../../configs/content_failed_reload_action.dart';
import 'error_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ContentError extends StatelessWidget {
  final Object? error;
  final StackTrace? stackTrace;
  final Future<void> Function() onRefresh;

  const ContentError({
    Key? key,
    required this.error,
    required this.stackTrace,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var type = errorType("$error");
    late String message;
    late IconData iconData;
    switch (type) {
      case errorTypeNetwork:
        iconData = Icons.wifi_off_rounded;
        message = AppLocalizations.of(context)!.connectExceptionCheckNetwork;
        break;
      case errorTypePermission:
        iconData = Icons.highlight_off;
        message = AppLocalizations.of(context)!.illegalPermissions;
        break;
      case errorTypeTime:
        iconData = Icons.timer_off;
        message = AppLocalizations.of(context)!.checkDeviceTime;
        break;
      default:
        iconData = Icons.highlight_off;
        message = AppLocalizations.of(context)!.hasBroken;
        break;
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        print("$error");
        print("$stackTrace");
        var width = constraints.maxWidth;
        var height = constraints.maxHeight;
        var min = width < height ? width : height;
        var iconSize = min / 2.3;
        var textSize = min / 16;
        var tipSize = min / 20;
        var infoSize = min / 30;
        if (contentFailedReloadAction ==
            ContentFailedReloadAction.touchLoader) {
          return GestureDetector(
            onTap: onRefresh,
            child: ListView(
              children: [
                SizedBox(
                  height: height,
                  child: Column(
                    children: [
                      Expanded(child: Container()),
                      Icon(
                        iconData,
                        size: iconSize,
                        color: Colors.grey.shade600,
                      ),
                      Container(height: min / 10),
                      Container(
                        padding: const EdgeInsets.only(
                          left: 30,
                          right: 30,
                        ),
                        child: Text(
                          message,
                          style: TextStyle(fontSize: textSize),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Text('(${AppLocalizations.of(context)!.tapToRefresh})', style: TextStyle(fontSize: tipSize)),
                      Container(height: min / 15),
                      Text('$error', style: TextStyle(fontSize: infoSize)),
                      Expanded(child: Container()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: [
              SizedBox(
                height: height,
                child: Column(
                  children: [
                    Expanded(child: Container()),
                    Icon(
                      iconData,
                      size: iconSize,
                      color: Colors.grey.shade600,
                    ),
                    Container(height: min / 10),
                    Container(
                      padding: const EdgeInsets.only(
                        left: 30,
                        right: 30,
                      ),
                      child: Text(
                        message,
                        style: TextStyle(fontSize: textSize),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text('(${AppLocalizations.of(context)!.pullDownToRefresh})', style: TextStyle(fontSize: tipSize)),
                    Container(height: min / 15),
                    Text('$error'.split("\n")[0],
                        style: TextStyle(fontSize: infoSize)),
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
