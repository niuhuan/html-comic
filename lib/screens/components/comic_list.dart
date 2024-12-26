import 'dart:math';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:html/screens/comic_reader_screen.dart';

import '../../configs/list_layout.dart';
import 'images.dart';
import 'comic_info_card.dart';

// 漫画列表页
class ComicList extends StatefulWidget {
  final Widget? appendWidget;
  final List<ComicItem> comicList;
  final ScrollController? controller;

  const ComicList(
    this.comicList, {
    this.appendWidget,
    this.controller,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicListState();
}

class _ComicListState extends State<ComicList> {
  @override
  void initState() {
    listLayoutEvent.subscribe(_onLayoutChange);
    super.initState();
  }

  @override
  void dispose() {
    listLayoutEvent.unsubscribe(_onLayoutChange);
    super.dispose();
  }

  void _onLayoutChange(EventArgs? args) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    switch (currentLayout) {
      case ListLayout.infoCard:
        return _buildInfoCardList();
      case ListLayout.onlyImage:
        return _buildGridImageWarp();
      case ListLayout.coverAndTitle:
        return _buildGridImageTitleWarp();
      default:
        return Container();
    }
  }

  Widget _buildInfoCardList() {
    return ListView(
      controller: widget.controller,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ...widget.comicList
            .map((e) => GestureDetector(
                  onTap: () {
                    toComicInfo(e);
                  },
                  child: ComicInfoCard(e),
                ))
            .toList(),
        ...widget.appendWidget != null ? [
          SizedBox(
            height: coverHeight,
            child: widget.appendWidget!,
          ),
        ] : [],
      ],
    );
  }

  Widget _buildGridImageWarp() {
    var gap = 3.0;
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var widthAndGap = min / 4;
    int rowCap = size.width ~/ widthAndGap;
    var width = widthAndGap - gap * 2;
    var height = width * coverHeight / coverWidth;
    List<Widget> wraps = [];
    List<Widget> tmp = [];
    for (var e in widget.comicList) {
      tmp.add(GestureDetector(
        onTap: () {
          toComicInfo(e);
        },
        child: Container(
          padding: EdgeInsets.all(gap),
          child: ComicIntroductionImg(
            comicId: e.comicId,
            scope: "img1",
            url: e.comicIntroduction.img1,
            width: width,
            height: height,
          ),
        ),
      ));
      if (tmp.length == rowCap) {
        wraps.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tmp,
        ));
        tmp = [];
      }
    }
    // 追加特殊按钮
    if (widget.appendWidget != null) {
      tmp.add(Container(
        color:
            (Theme.of(context).textTheme.bodyText1?.color ?? Colors.transparent)
                .withOpacity(.1),
        margin: EdgeInsets.only(
          left: (rowCap - tmp.length) * gap,
          right: (rowCap - tmp.length) * gap,
          top: gap,
          bottom: gap,
        ),
        width: (rowCap - tmp.length) * width,
        height: height,
        child: widget.appendWidget,
      ));
    }
    // 最后一页没有下一页所有有可能为空
    if (tmp.isNotEmpty) {
      wraps.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tmp,
      ));
      tmp = [];
    }
    // 返回
    return ListView(
      controller: widget.controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: gap, bottom: gap),
      children: wraps,
    );
  }

  Widget _buildGridImageTitleWarp() {
    var gap = 3.0;
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var widthAndGap = min / 3;
    int rowCap = size.width ~/ widthAndGap;
    var width = widthAndGap - gap * 2;
    var height = width * coverHeight / coverWidth;
    double titleFontSize = max(width / 11, 10);
    double shadowFontSize = max(width / 9, 12);
    List<Widget> wraps = [];
    List<Widget> tmp = [];
    for (var e in widget.comicList) {
      tmp.add(GestureDetector(
          onTap: () {
            toComicInfo(e);
          },
          child: Container(
            margin: EdgeInsets.all(gap),
            width: width,
            height: height,
            child: Stack(
              children: [
                ComicIntroductionImg(
                  comicId: e.comicId,
                  scope: "img1",
                  url: e.comicIntroduction.img1,
                  width: width,
                  height: height,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.black.withOpacity(.3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.comicIntroduction.title + '\n',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              height: 1.2,
                            ),
                            strutStyle: const StrutStyle(height: 1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )));
      if (tmp.length == rowCap) {
        wraps.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tmp,
        ));
        tmp = [];
      }
    }
    // 追加特殊按钮
    if (widget.appendWidget != null) {
      tmp.add(Container(
        color:
            (Theme.of(context).textTheme.bodyText1?.color ?? Colors.transparent)
                .withOpacity(.1),
        margin: EdgeInsets.only(
          left: (rowCap - tmp.length) * gap,
          right: (rowCap - tmp.length) * gap,
          top: gap,
          bottom: gap,
        ),
        width: (rowCap - tmp.length) * width,
        height: height,
        child: widget.appendWidget,
      ));
    }
    // 最后一页没有下一页所有有可能为空
    if (tmp.isNotEmpty) {
      wraps.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tmp,
      ));
      tmp = [];
    }
    // 返回
    return ListView(
      controller: widget.controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: gap, bottom: gap),
      children: wraps,
    );
  }

  void toComicInfo(ComicItem e) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => ComicReaderScreen(
          comicId: e.comicId, comicIntroduction: e.comicIntroduction),
    ));
  }
}
