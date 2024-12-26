import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html/ffi.dart';

import '../../commons.dart';
import '../../cross.dart';
import '../file_photo_view_screen.dart';

// 远端图片
class ComicIntroductionImg extends StatefulWidget {
  final int comicId;
  final String scope;
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ComicIntroductionImg({
    Key? key,
    required this.comicId,
    required this.scope,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicIntroductionImgState();
}

class _ComicIntroductionImgState extends State<ComicIntroductionImg> {
  late Future<String> _future;

  @override
  void initState() {
    _future = native.loadComicIntroductionImg(
      comicId: widget.comicId,
      scope: widget.scope,
      url: widget.url,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return pathFutureImage(
      _future,
      widget.width,
      widget.height,
      fit: widget.fit,
    );
  }
}

// 远端图片
class ReaderInfoFileImg extends StatefulWidget {
  final ReaderInfoFile file;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ReaderInfoFileImg({
    Key? key,
    required this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ReaderInfoFileImgState();
}

class _ReaderInfoFileImgState extends State<ReaderInfoFileImg> {
  late Future<String> _future;

  @override
  void initState() {
    _future = native.loadComicImage(file: widget.file);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return pathFutureImage(
      _future,
      widget.width,
      widget.height,
      fit: widget.fit,
    );
  }
}

Widget pathFutureImage(
  Future<String> future,
  double? width,
  double? height, {
  BoxFit fit = BoxFit.cover,
}) {
  return FutureBuilder(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          print("${snapshot.error}");
          print("${snapshot.stackTrace}");
          return buildError(width, height);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return buildLoading(width, height);
        }
        return buildFile(
          snapshot.data!,
          width,
          height,
          fit: fit,
          context: context,
        );
      });
}

// 通用方法

Widget buildSvg(String source, double? width, double? height,
    {Color? color, double? margin}) {
  var widget = Container(
    width: width,
    height: height,
    padding: margin != null ? const EdgeInsets.all(10) : null,
    child: Center(
      child: SvgPicture.asset(
        source,
        width: width,
        height: height,
        color: color,
      ),
    ),
  );
  return GestureDetector(onLongPress: () {}, child: widget);
}

Widget buildMock(double? width, double? height) {
  var widget = Container(
    width: width,
    height: height,
    padding: const EdgeInsets.all(10),
    child: Center(
      child: SvgPicture.asset(
        'lib/assets/unknown.svg',
        width: width,
        height: height,
        color: Colors.grey.shade600,
      ),
    ),
  );
  return GestureDetector(onLongPress: () {}, child: widget);
}

Widget buildError(double? width, double? height) {
  return Image(
    image: const AssetImage('lib/assets/error.png'),
    width: width,
    height: height,
  );
}

Widget buildLoading(double? width, double? height) {
  double? size;
  if (width != null && height != null) {
    size = width < height ? width : height;
  }
  return SizedBox(
    width: width,
    height: height,
    child: Center(
      child: Icon(
        Icons.downloading,
        size: size,
        color: Colors.black12,
      ),
    ),
  );
}

Widget buildFile(String file, double? width, double? height,
    {BoxFit fit = BoxFit.cover, required BuildContext context}) {
  var image = Image(
    image: FileImage(File(file)),
    width: width,
    height: height,
    errorBuilder: (a, b, c) {
      print("$b");
      print("$c");
      return buildError(width, height);
    },
    fit: fit,
  );
  return GestureDetector(
    onLongPress: () async {
      int? choose = await chooseMapDialog(
        context,
        title: AppLocalizations.of(context)!.choose,
        values: {
          AppLocalizations.of(context)!.previewImage: 2,
          AppLocalizations.of(context)!.saveImage: 1,
        },
      );
      switch (choose) {
        case 2:
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FilePhotoViewScreen(file),
          ));
          break;
        case 1:
          cross.saveImageFileToGallery(file, context);
          break;
      }
    },
    child: image,
  );
}
