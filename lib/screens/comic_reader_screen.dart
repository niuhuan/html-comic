import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/ffi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../configs/auto_full_screen.dart';
import 'components/content_error.dart';
import 'components/content_loading.dart';
import 'components/image_reader.dart';

// 在线阅读漫画
class ComicReaderScreen extends StatefulWidget {
  final int comicId;
  final ComicIntroduction comicIntroduction;
  late final bool autoFullScreen;
  late final int initRank;

  ComicReaderScreen({
    required this.comicId,
    required this.comicIntroduction,
    bool? autoFullScreen,
    this.initRank = 0,
    Key? key,
  }) : super(key: key) {
    this.autoFullScreen = autoFullScreen ?? currentAutoFullScreen();
  }

  @override
  State<StatefulWidget> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late ComicReaderInfo readerInfo;
  late List<ReaderInfoFile> readerInfoFiles;
  late bool _fullScreen = widget.autoFullScreen;
  late Future _future;
  late Key _key;
  bool _replacement = false;

  Future _load() async {
    readerInfo = await native.comicReaderInfo(id: widget.comicId);
    readerInfoFiles = await native.comicReaderInfoFiles(
        comicId: widget.comicId, files: readerInfo.files);
    if (_fullScreen) {
      setState(() {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [],
        );
      });
    }
  }

  Future _onPositionChange(int position) async {
    return native.comicViewPage(comicId: widget.comicId, pageRank: position);
  }

  FutureOr<dynamic> _onReload() {
    _replacement = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => ComicReaderScreen(
        comicId: widget.comicId,
        comicIntroduction: widget.comicIntroduction,
        autoFullScreen: _fullScreen,
        // todo initRank: ,
      ),
    ));
  }

  FutureOr<dynamic> _onDownload() {
    // todo
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) =>
    //         DownloadConfirmScreen(
    //           comicInfo: widget.comicInfo,
    //           epList: widget.epList.reversed.toList(),
    //         ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      key: _key,
      future: _future,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: _fullScreen
                ? null
                : AppBar(
                    title: Text(widget.comicIntroduction.title),
                  ),
            body: ContentError(
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
              onRefresh: () async {
                setState(() {
                  _future = _load();
                  _key = UniqueKey();
                });
              },
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: _fullScreen
                ? null
                : AppBar(
                    title: Text(widget.comicIntroduction.title),
                  ),
            body: ContentLoading(label: AppLocalizations.of(context)!.loading),
          );
        }
        return Scaffold(
          body: ImageReader(
            ImageReaderStruct(
              comicId: widget.comicId,
              comicIntroduction: widget.comicIntroduction,
              fullScreen: _fullScreen,
              onFullScreenChange: _onFullScreenChange,
              onPositionChange: _onPositionChange,
              initPosition: widget.initRank,
              onReload: _onReload,
              onDownload: _onReload,
              readerInfo: readerInfo,
              readerInfoFiles: readerInfoFiles,
            ),
          ),
        );
      },
    );
  }

  Future _onFullScreenChange(bool fullScreen) async {
    setState(() {
      if (fullScreen) {
        if (Platform.isAndroid || Platform.isIOS) {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [],
          );
        }
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
      _fullScreen = fullScreen;
    });
  }

  @override
  void initState() {
    _future = _load();
    _key = UniqueKey();
    super.initState();
  }

  @override
  void dispose() {
    if (!_replacement) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
    super.dispose();
  }
}
