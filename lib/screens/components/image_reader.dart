import 'dart:async';
import 'dart:io';

import 'package:another_xlider/another_xlider.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../bridge_generated.dart';
import '../../configs/full_screen_action.dart';
import '../../configs/keyboard_controller.dart';
import '../../configs/no_animation.dart';
import '../../configs/reader_direction.dart';
import '../../configs/reader_slider_position.dart';
import '../../configs/reader_type.dart';
import '../../configs/volume_controller.dart';
import 'gesture_zoom_box.dart';

import 'images.dart';

///////////////

Event<_ReaderControllerEventArgs> _readerControllerEvent =
    Event<_ReaderControllerEventArgs>();

class _ReaderControllerEventArgs extends EventArgs {
  final String key;

  _ReaderControllerEventArgs(this.key);
}

Widget readerKeyboardHolder(Widget widget) {
  if (keyboardController &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    widget = RawKeyboardListener(
      focusNode: FocusNode(),
      child: widget,
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
            _readerControllerEvent.broadcast(_ReaderControllerEventArgs("UP"));
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
            _readerControllerEvent
                .broadcast(_ReaderControllerEventArgs("DOWN"));
          }
        }
      },
    );
  }
  return widget;
}

void _onVolumeEvent(dynamic args) {
  _readerControllerEvent.broadcast(_ReaderControllerEventArgs("$args"));
}

var _volumeListenCount = 0;

// 仅支持安卓
// 监听后会拦截安卓手机音量键
// 仅最后一次监听生效
// event可能为DOWN/UP
EventChannel volumeButtonChannel = const EventChannel("volume_button");
StreamSubscription? volumeS;

void addVolumeListen() {
  _volumeListenCount++;
  if (_volumeListenCount == 1) {
    volumeS =
        volumeButtonChannel.receiveBroadcastStream().listen(_onVolumeEvent);
  }
}

void delVolumeListen() {
  _volumeListenCount--;
  if (_volumeListenCount == 0) {
    volumeS?.cancel();
  }
}

///////////////////////////////////////////////////////////////////////////////

// 对Reader的传参以及封装

class ImageReaderStruct {
  final int comicId;
  final ComicIntroduction comicIntroduction;
  final bool fullScreen;
  final FutureOr<dynamic> Function(bool fullScreen) onFullScreenChange;
  final FutureOr<dynamic> Function(int) onPositionChange;
  final int initPosition;
  final FutureOr<dynamic> Function() onReload;
  final FutureOr<dynamic> Function() onDownload;
  final ComicReaderInfo readerInfo;
  final List<ReaderInfoFile> readerInfoFiles;

  const ImageReaderStruct({
    required this.comicId,
    required this.comicIntroduction,
    required this.fullScreen,
    required this.onFullScreenChange,
    required this.onPositionChange,
    required this.initPosition,
    required this.onReload,
    required this.onDownload,
    required this.readerInfo,
    required this.readerInfoFiles,
  });
}

//

class ImageReader extends StatefulWidget {
  final ImageReaderStruct struct;

  const ImageReader(this.struct, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImageReaderState();
}

class _ImageReaderState extends State<ImageReader> {
  // 记录初始方向
  final ReaderDirection _pagerDirection = gReaderDirection;

  // 记录初始阅读器类型
  final ReaderType _pagerType = currentReaderType;

  // 记录了控制器
  late final FullScreenAction _fullScreenAction = currentFullScreenAction;

  late final ReaderSliderPosition _readerSliderPosition =
      currentReaderSliderPosition;

  @override
  Widget build(BuildContext context) {
    return _ImageReaderContent(
      widget.struct,
      _pagerDirection,
      _pagerType,
      _fullScreenAction,
      _readerSliderPosition,
    );
  }
}

//

class _ImageReaderContent extends StatefulWidget {
  // 记录初始方向
  final ReaderDirection pagerDirection;

  // 记录初始阅读器类型
  final ReaderType pagerType;

  final FullScreenAction fullScreenAction;

  final ReaderSliderPosition readerSliderPosition;

  final ImageReaderStruct struct;

  const _ImageReaderContent(
    this.struct,
    this.pagerDirection,
    this.pagerType,
    this.fullScreenAction,
    this.readerSliderPosition,
  );

  @override
  State<StatefulWidget> createState() {
    switch (pagerType) {
      case ReaderType.webToon:
        return _WebToonReaderState();
      case ReaderType.webToonZoom:
        return _WebToonZoomReaderState();
      case ReaderType.gallery:
        return _GalleryReaderState();
      case ReaderType.webToonFreeZoom:
        return _ListViewReaderState();
      default:
        throw Exception("ERROR READER TYPE");
    }
  }
}

abstract class _ImageReaderContentState extends State<_ImageReaderContent> {
  // 阅读器
  Widget _buildViewer();

  // 键盘, 音量键 等事件
  void _needJumpTo(int index, bool animation);

  // 记录了是否切换了音量
  late bool _listVolume;

  // 和初始化与翻页有关

  @override
  void initState() {
    _initCurrent();
    _readerControllerEvent.subscribe(_onPageControl);
    _listVolume = volumeController;
    if (_listVolume) {
      addVolumeListen();
    }
    super.initState();
  }

  @override
  void dispose() {
    _readerControllerEvent.unsubscribe(_onPageControl);
    if (_listVolume) {
      delVolumeListen();
    }
    super.dispose();
  }

  void _onPageControl(_ReaderControllerEventArgs? args) {
    if (args != null) {
      var event = args.key;
      switch (event) {
        case "UP":
          if (_current > 0) {
            _needJumpTo(_current - 1, true);
          }
          break;
        case "DOWN":
          if (_current < widget.struct.readerInfoFiles.length - 1) {
            _needJumpTo(_current + 1, true);
          }
          break;
      }
    }
  }

  late int _startIndex;
  late int _current;
  late int _slider;

  void _initCurrent() {
    if (widget.struct.readerInfoFiles.length > widget.struct.initPosition) {
      _startIndex = widget.struct.initPosition;
    } else {
      _startIndex = 0;
    }
    _current = _startIndex;
    _slider = _startIndex;
  }

  void _onCurrentChange(int index) {
    if (index != _current) {
      setState(() {
        _current = index;
        _slider = index;
        widget.struct.onPositionChange(index);
      });
    }
  }

  // 与显示有关的方法

  @override
  Widget build(BuildContext context) {
    switch (currentFullScreenAction) {
      // 按钮
      case FullScreenAction.controller:
        return Stack(
          children: [
            _buildViewer(),
            _buildBar(_buildFullScreenControllerStackItem()),
          ],
        );
      case FullScreenAction.touchOnce:
        return Stack(
          children: [
            _buildTouchOnceControllerAction(_buildViewer()),
            _buildBar(Container()),
          ],
        );
      case FullScreenAction.touchDouble:
        return Stack(
          children: [
            _buildTouchDoubleControllerAction(_buildViewer()),
            _buildBar(Container()),
          ],
        );
      case FullScreenAction.touchDoubleOnceNext:
        return Stack(
          children: [
            _buildTouchDoubleOnceNextControllerAction(_buildViewer()),
            _buildBar(Container()),
          ],
        );
      case FullScreenAction.threeArea:
        return Stack(
          children: [
            _buildViewer(),
            _buildBar(_buildThreeAreaControllerAction()),
          ],
        );
    }
  }

  Widget _buildBar(Widget child) {
    switch (widget.readerSliderPosition) {
      case ReaderSliderPosition.bottom:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(child: child),
            widget.struct.fullScreen
                ? Container()
                : Container(
                    height: 45,
                    color: const Color(0x88000000),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(width: 15),
                        IconButton(
                          icon: const Icon(Icons.fullscreen),
                          color: Colors.white,
                          onPressed: () {
                            widget.struct
                                .onFullScreenChange(!widget.struct.fullScreen);
                          },
                        ),
                        Container(width: 10),
                        Expanded(
                          child: widget.pagerType != ReaderType.webToonFreeZoom
                              ? _buildSliderBottom()
                              : Container(),
                        ),
                        Container(width: 10),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: Colors.white,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        Container(width: 15),
                      ],
                    ),
                  ),
          ],
        );
      case ReaderSliderPosition.right:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  child,
                  _buildSliderRight(),
                ],
              ),
            ),
          ],
        );
      case ReaderSliderPosition.left:
        return Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  child,
                  _buildSliderLeft(),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAppBar() => widget.struct.fullScreen
      ? Container()
      : AppBar(
          title: Text(widget.struct.comicIntroduction.title),
          actions: [
            IconButton(
              onPressed: _onMoreSetting,
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        );

  Widget _buildSliderBottom() {
    return Column(
      children: [
        Expanded(child: Container()),
        SizedBox(
          height: 25,
          child: _buildSliderWidget(Axis.horizontal),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildSliderLeft() => widget.struct.fullScreen
      ? Container()
      : Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 35,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding:
                  const EdgeInsets.only(top: 10, bottom: 10, left: 6, right: 5),
              child: Center(
                child: _buildSliderWidget(Axis.vertical),
              ),
            ),
          ),
        );

  Widget _buildSliderRight() => widget.struct.fullScreen
      ? Container()
      : Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 35,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              padding:
                  const EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 6),
              child: Center(
                child: _buildSliderWidget(Axis.vertical),
              ),
            ),
          ),
        );

  Widget _buildSliderWidget(Axis axis) {
    return FlutterSlider(
      axis: axis,
      values: [_slider.toDouble()],
      min: 0,
      max: (widget.struct.readerInfoFiles.length - 1).toDouble(),
      onDragging: (handlerIndex, lowerValue, upperValue) {
        _slider = (lowerValue.toInt());
      },
      onDragCompleted: (handlerIndex, lowerValue, upperValue) {
        _slider = (lowerValue.toInt());
        if (_slider != _current) {
          _needJumpTo(_slider, false);
        }
      },
      trackBar: FlutterSliderTrackBar(
        inactiveTrackBar: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade300,
        ),
        activeTrackBar: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      step: const FlutterSliderStep(
        step: 1,
        isPercentRange: false,
      ),
      tooltip: FlutterSliderTooltip(custom: (value) {
        double a = value + 1;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: Colors.black.withAlpha(0xCC),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.circular(3)),
          ),
          child: Text(
            '${a.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFullScreenControllerStackItem() {
    if (widget.readerSliderPosition == ReaderSliderPosition.bottom &&
        !widget.struct.fullScreen) {
      return Container();
    }
    return Align(
      alignment: Alignment.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            color: Color(0x88000000),
          ),
          child: GestureDetector(
            onTap: () {
              widget.struct.onFullScreenChange(!widget.struct.fullScreen);
            },
            child: Icon(
              widget.struct.fullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen_outlined,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTouchOnceControllerAction(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        widget.struct.onFullScreenChange(!widget.struct.fullScreen);
      },
      child: child,
    );
  }

  Widget _buildTouchDoubleControllerAction(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        widget.struct.onFullScreenChange(!widget.struct.fullScreen);
      },
      child: child,
    );
  }

  Widget _buildTouchDoubleOnceNextControllerAction(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _readerControllerEvent.broadcast(_ReaderControllerEventArgs("DOWN"));
      },
      onDoubleTap: () {
        widget.struct.onFullScreenChange(!widget.struct.fullScreen);
      },
      child: child,
    );
  }

  Widget _buildThreeAreaControllerAction() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var up = Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _readerControllerEvent
                  .broadcast(_ReaderControllerEventArgs("UP"));
            },
            child: Container(),
          ),
        );
        var down = Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _readerControllerEvent
                  .broadcast(_ReaderControllerEventArgs("DOWN"));
            },
            child: Container(),
          ),
        );
        var fullScreen = Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () =>
                widget.struct.onFullScreenChange(!widget.struct.fullScreen),
            child: Container(),
          ),
        );
        late Widget child;
        switch (widget.pagerDirection) {
          case ReaderDirection.topToBottom:
            child = Column(children: [
              up,
              fullScreen,
              down,
            ]);
            break;
          case ReaderDirection.leftToRight:
            child = Row(children: [
              up,
              fullScreen,
              down,
            ]);
            break;
          case ReaderDirection.rightToLeft:
            child = Row(children: [
              down,
              fullScreen,
              up,
            ]);
            break;
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: child,
        );
      },
    );
  }

  Future _onMoreSetting() async {
    // 记录开始的画质
    final cReaderSliderPosition = currentReaderSliderPosition;
    //
    await showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * (.45),
          child: _SettingPanel(
            widget.struct.onReload,
            widget.struct.onDownload,
          ),
        );
      },
    );
    if (widget.pagerDirection != gReaderDirection ||
        widget.pagerType != currentReaderType ||
        widget.fullScreenAction != currentFullScreenAction ||
        cReaderSliderPosition != currentReaderSliderPosition) {
      widget.struct.onReload();
    }
  }

  // 给子类调用的方法

  bool _fullscreenController() {
    switch (currentFullScreenAction) {
      case FullScreenAction.controller:
        return false;
      case FullScreenAction.touchOnce:
        return false;
      case FullScreenAction.touchDouble:
        return false;
      case FullScreenAction.touchDoubleOnceNext:
        return false;
      case FullScreenAction.threeArea:
        return true;
    }
  }

  double _topBarHeight() => Scaffold.of(context).appBarMaxHeight ?? 0;

  double _bottomBarHeight() =>
      widget.readerSliderPosition == ReaderSliderPosition.bottom ? 45 : 0;
}

class _SettingPanel extends StatefulWidget {
  final FutureOr Function() onReloadEp;
  final FutureOr Function() onDownload;

  const _SettingPanel(this.onReloadEp, this.onDownload);

  @override
  State<StatefulWidget> createState() => _SettingPanelState();
}

class _SettingPanelState extends State<_SettingPanel> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            _bottomIcon(
              icon: Icons.crop_sharp,
              title: currentReaderDirectionName(),
              onPressed: () async {
                await choosePagerDirection(context);
                setState(() {});
              },
            ),
            _bottomIcon(
              icon: Icons.view_day_outlined,
              title: currentReaderTypeName(),
              onPressed: () async {
                await choosePagerType(context);
                setState(() {});
              },
            ),
            _bottomIcon(
              icon: Icons.control_camera_outlined,
              title: currentFullScreenActionName(),
              onPressed: () async {
                await chooseFullScreenAction(context);
                setState(() {});
              },
            ),
          ],
        ),
        Row(
          children: [
            _bottomIcon(
              icon: Icons.refresh,
              title: "重载页面",
              onPressed: () {
                Navigator.of(context).pop();
                widget.onReloadEp();
              },
            ),
            _bottomIcon(
              icon: Icons.file_download,
              title: "下载本作",
              onPressed: widget.onDownload,
            ),
          ],
        ),
      ],
    );
  }

  Widget _bottomIcon({
    required IconData icon,
    required String title,
    required void Function() onPressed,
  }) {
    return Expanded(
      child: Center(
        child: Column(
          children: [
            IconButton(
              iconSize: 55,
              icon: Column(
                children: [
                  Container(height: 3),
                  Icon(
                    icon,
                    size: 25,
                    color: Colors.white,
                  ),
                  Container(height: 3),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  Container(height: 3),
                ],
              ),
              onPressed: onPressed,
            )
          ],
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////

class _WebToonReaderState extends _ImageReaderContentState {
  var _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;

  @override
  void initState() {
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _itemPositionsListener.itemPositions.addListener(_onListCurrentChange);
    super.initState();
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onListCurrentChange);
    super.dispose();
  }

  void _onListCurrentChange() {
    var to = _itemPositionsListener.itemPositions.value.first.index;
    // 包含一个下一章, 假设5张图片 0,1,2,3,4 length=5, 下一章=5
    if (to >= 0 && to < widget.struct.readerInfoFiles.length) {
      super._onCurrentChange(to);
    }
  }

  @override
  void _needJumpTo(int index, bool animation) {
    if (noAnimation() || animation == false) {
      _itemScrollController.jumpTo(
        index: index,
      );
    } else {
      if (DateTime.now().millisecondsSinceEpoch < _controllerTime) {
        return;
      }
      _controllerTime = DateTime.now().millisecondsSinceEpoch + 400;
      _itemScrollController.scrollTo(
        index: index, // 减1 当前position 再减少1 前一个
        duration: const Duration(milliseconds: 400),
      );
    }
  }

  @override
  Widget _buildViewer() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // reload _images size
        List<Widget> _images = [];
        for (var index = 0;
            index < widget.struct.readerInfoFiles.length;
            index++) {
          var e = widget.struct.readerInfoFiles[index];
          late Size renderSize;
          if (widget.pagerDirection == ReaderDirection.topToBottom) {
            renderSize = Size(
              constraints.maxWidth,
              constraints.maxWidth * e.height / e.width,
            );
          } else {
            var maxHeight = constraints.maxHeight -
                super._topBarHeight() -
                (widget.struct.fullScreen
                    ? super._topBarHeight()
                    : super._bottomBarHeight());
            renderSize = Size(
              maxHeight * e.width / e.height,
              maxHeight,
            );
          }
          _images.add(ReaderInfoFileImg(
            width: renderSize.width,
            height: renderSize.height,
            file: e,
          ));
        }
        return ScrollablePositionedList.builder(
          initialScrollIndex: super._startIndex,
          scrollDirection: widget.pagerDirection == ReaderDirection.topToBottom
              ? Axis.vertical
              : Axis.horizontal,
          reverse: widget.pagerDirection == ReaderDirection.rightToLeft,
          padding: EdgeInsets.only(
            // 不管全屏与否, 滚动方向如何, 顶部永远保持间距
            top: super._topBarHeight(),
            bottom: widget.pagerDirection == ReaderDirection.topToBottom
                ? 130 // 纵向滚动 底部永远都是130的空白
                : ( // 横向滚动
                    widget.struct.fullScreen
                        ? super._topBarHeight() // 全屏时底部和顶部到屏幕边框距离一样保持美观
                        : super._bottomBarHeight())
            // 非全屏时, 顶部去掉顶部BAR的高度, 底部去掉底部BAR的高度, 形成看似填充的效果
            ,
          ),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: widget.struct.readerInfoFiles.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (widget.struct.readerInfoFiles.length == index) {
              return _buildNextEp();
            }
            return _images[index];
          },
        );
      },
    );
  }

  Widget _buildNextEp() {
    if (super._fullscreenController()) {
      return Container();
    }
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(20),
      child: MaterialButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        textColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: Text("结束阅读"),
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////

class _WebToonZoomReaderState extends _WebToonReaderState {
  @override
  Widget _buildList() {
    return GestureZoomBox(child: super._buildList());
  }
}

///////////////////////////////////////////////////////////////////////////////

class _ListViewReaderState extends _ImageReaderContentState
    with SingleTickerProviderStateMixin {
  final _transformationController = TransformationController();
  late TapDownDetails _doubleTapDetails;
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void _needJumpTo(int index, bool animation) {}

  @override
  Widget _buildViewer() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // reload _images size
        List<Widget> _images = [];
        for (var index = 0;
            index < widget.struct.readerInfoFiles.length;
            index++) {
          var e = widget.struct.readerInfoFiles[index];
          late Size renderSize;
          if (widget.pagerDirection == ReaderDirection.topToBottom) {
            renderSize = Size(
              constraints.maxWidth,
              constraints.maxWidth * e.height / e.width,
            );
          } else {
            var maxHeight = constraints.maxHeight -
                super._topBarHeight() -
                (widget.struct.fullScreen
                    ? super._topBarHeight()
                    : super._bottomBarHeight());
            renderSize = Size(
              maxHeight * e.width / e.height,
              maxHeight,
            );
          }
          _images.add(ReaderInfoFileImg(
            width: renderSize.width,
            height: renderSize.height,
            file: e,
          ));
        }
        var list = ListView.builder(
          scrollDirection: widget.pagerDirection == ReaderDirection.topToBottom
              ? Axis.vertical
              : Axis.horizontal,
          reverse: widget.pagerDirection == ReaderDirection.rightToLeft,
          padding: EdgeInsets.only(
            // 不管全屏与否, 滚动方向如何, 顶部永远保持间距
            top: super._topBarHeight(),
            bottom: widget.pagerDirection == ReaderDirection.topToBottom
                ? 130 // 纵向滚动 底部永远都是130的空白
                : ( // 横向滚动
                    widget.struct.fullScreen
                        ? super._topBarHeight() // 全屏时底部和顶部到屏幕边框距离一样保持美观
                        : super._bottomBarHeight())
            // 非全屏时, 顶部去掉顶部BAR的高度, 底部去掉底部BAR的高度, 形成看似填充的效果
            ,
          ),
          itemCount: widget.struct.readerInfoFiles.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (widget.struct.readerInfoFiles.length == index) {
              return _buildNextEp();
            }
            return _images[index];
          },
        );
        var viewer = InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1,
          maxScale: 2,
          child: list,
        );
        return GestureDetector(
          onDoubleTap: _handleDoubleTap,
          onDoubleTapDown: _handleDoubleTapDown,
          child: viewer,
        );
      },
    );
  }

  Widget _buildNextEp() {
    if (super._fullscreenController()) {
      return Container();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      child: MaterialButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        textColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: const Text('结束阅读'),
        ),
      ),
    );
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_animationController.isAnimating) {
      return;
    }
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      var position = _doubleTapDetails.localPosition;
      var animation = Tween(begin: 0, end: 1.0).animate(_animationController);
      animation.addListener(() {
        _transformationController.value = Matrix4.identity()
          ..translate(
              -position.dx * animation.value, -position.dy * animation.value)
          ..scale(animation.value + 1.0);
      });
      _animationController.forward(from: 0);
    }
  }
}

///////////////////////////////////////////////////////////////////////////////

class _GalleryReaderState extends _ImageReaderContentState {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 需要先初始化 super._startIndex 才能使用, 所以在上面
    _pageController = PageController(initialPage: super._startIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void _needJumpTo(int index, bool animation) {
    if (noAnimation() || animation == false) {
      _pageController.jumpToPage(
        index,
      );
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    }
  }

  void _onGalleryPageChange(int to) {
    // 包含一个下一章, 假设5张图片 0,1,2,3,4 length=5, 下一章=5
    if (to >= 0 && to < widget.struct.readerInfoFiles.length) {
      super._onCurrentChange(to);
    }
  }

  @override
  Widget _buildViewer() {
    Widget gallery = PhotoViewGallery.builder(
      scrollDirection: widget.pagerDirection == ReaderDirection.topToBottom
          ? Axis.vertical
          : Axis.horizontal,
      reverse: widget.pagerDirection == ReaderDirection.rightToLeft,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return buildLoading(constraints.maxWidth, constraints.maxHeight);
        },
      ),
      pageController: _pageController,
      onPageChanged: _onGalleryPageChange,
      itemCount: widget.struct.readerInfoFiles.length,
      builder: (BuildContext context, int index) {
        var e = widget.struct.readerInfoFiles[index];
        return PhotoViewGalleryPageOptions.customChild(
          // todo image provider
          child: ReaderInfoFileImg(
            file: e,
          ),
          filterQuality: FilterQuality.high,
        );
      },
      allowImplicitScrolling: true,
    );
    // todo if image provider
    // gallery = GestureDetector(
    //   child: gallery,
    //   onLongPress: () async {
    //     if (_current >= 0 && _current < widget.struct.readerInfoFiles.length) {
    //       Future<String> load() async {
    //         var item = widget.struct.readerInfoFiles[_current];
    //         if (item.downloadLocalPath != null) {
    //           return method.downloadImagePath(item.downloadLocalPath!);
    //         }
    //         var data = await method.remoteImageData(item.fileServer, item.path);
    //         return data.finalPath;
    //       }
    //
    //       String? choose =
    //           await chooseListDialog(context, '请选择', ['预览图片', '保存图片']);
    //       switch (choose) {
    //         case '预览图片':
    //           try {
    //             var file = await load();
    //             Navigator.of(context).push(MaterialPageRoute(
    //               builder: (context) => FilePhotoViewScreen(file),
    //             ));
    //           } catch (e) {
    //             defaultToast(context, "图片加载失败");
    //           }
    //           break;
    //         case '保存图片':
    //           try {
    //             var file = await load();
    //             saveImage(file, context);
    //           } catch (e) {
    //             defaultToast(context, "图片加载失败");
    //           }
    //           break;
    //       }
    //     }
    //   },
    // );
    gallery = Container(
      padding: EdgeInsets.only(
        top: widget.struct.fullScreen ? 0 : super._topBarHeight(),
        bottom: widget.struct.fullScreen ? 0 : super._bottomBarHeight(),
      ),
      child: gallery,
    );
    return Stack(
      children: [
        gallery,
        _buildNextEpController(),
      ],
    );
  }

  Widget _buildNextEpController() {
    if (super._fullscreenController() ||
        _current < widget.struct.readerInfoFiles.length - 1) return Container();
    return Align(
      alignment: Alignment.bottomRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            color: Color(0x88000000),
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              '结束阅读',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////
