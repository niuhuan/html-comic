/// 导航相关

import 'dart:async';
import 'package:flutter/material.dart';

// 用于监听返回到当前页面的事件
// (await Navigator.push 会在子页面pushReplacement时结束阻塞)
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// 路径深度计数

const _depthMax = 15;
var _depth = 0;

var navigatorObserver = _NavigatorObserver();

class _NavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    _depth--;
    print("DEPTH : $_depth");
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _depth++;
    print("DEPTH : $_depth");
    super.didPush(route, previousRoute);
  }
}

// 路径达到一定深度的时候使用 pushReplacement
Future<dynamic> navPushOrReplace(
    BuildContext context, WidgetBuilder builder) async {
  if (_depth < _depthMax) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: builder),
    );
  } else {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: builder),
    );
  }
}
