import 'package:flutter/material.dart';

import '../../configs/content_failed_reload_action.dart';

class ContentMessage extends StatelessWidget {
  final RefreshCallback? onRefresh;
  final IconData icon;
  final String message;

  const ContentMessage({
    required this.message,
    required this.icon,
    this.onRefresh,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onRefresh != null) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var width = constraints.maxWidth;
          var height = constraints.maxHeight;
          var min = width < height ? width : height;
          var iconSize = min / 2.3;
          var textSize = min / 16;
          var tipSize = min / 20;
          if (contentFailedReloadAction ==
              ContentFailedReloadAction.touchLoader) {
            return GestureDetector(
              onTap: () {
                onRefresh!();
              },
              child: ListView(
                children: [
                  SizedBox(
                    height: height,
                    child: Column(
                      children: [
                        Expanded(child: Container()),
                        Icon(
                          icon,
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
                        Text('(点击刷新)', style: TextStyle(fontSize: tipSize)),
                        Expanded(child: Container()),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              onRefresh!();
            },
            child: ListView(
              children: [
                SizedBox(
                  height: height,
                  child: Column(
                    children: [
                      Expanded(child: Container()),
                      Icon(
                        icon,
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
                      Text('(下拉刷新)', style: TextStyle(fontSize: tipSize)),
                      Container(height: min / 15),
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var width = constraints.maxWidth;
        var height = constraints.maxHeight;
        var min = width < height ? width : height;
        return Center(
          child: Column(
            children: [
              Expanded(child: Container()),
              SizedBox(
                width: min / 2,
                height: min / 2,
                child: Icon(icon, color: Colors.grey[100]),
              ),
              Container(height: min / 10),
              Text(message, style: TextStyle(fontSize: min / 15)),
              Expanded(child: Container()),
            ],
          ),
        );
      },
    );
  }
}
