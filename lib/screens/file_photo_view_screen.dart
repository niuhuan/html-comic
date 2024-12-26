import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html/cross.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../commons.dart';

// 预览图片
class FilePhotoViewScreen extends StatelessWidget {
  final String filePath;

  const FilePhotoViewScreen(this.filePath, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            GestureDetector(
              onLongPress: () async {
                int? choose = await chooseMapDialog(
                  context,
                  title: AppLocalizations.of(context)!.choose,
                  values: {
                    AppLocalizations.of(context)!.saveImage: 1
                  },
                );
                switch (choose) {
                  case 1:
                    cross.saveImageFileToGallery(filePath, context);
                    break;
                }
              },
              child: PhotoView(
                imageProvider: FileImage(File(filePath)),
              ),
            ),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.only(top: 30),
                padding: const EdgeInsets.only(left: 4, right: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.75),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child:
                    const Icon(Icons.keyboard_backspace, color: Colors.white),
              ),
            ),
          ],
        ),
      );
}
