import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html/ffi.dart';

import '../../commons.dart';
import 'images.dart';

// todo
double coverWidth = 210 / 3.15;
double coverHeight = 315 / 3.15;

class ComicItem {
  int comicId;
  ComicIntroduction comicIntroduction;

  ComicItem(this.comicId, this.comicIntroduction);
}

// 漫画卡片
class ComicInfoCard extends StatelessWidget {
  final bool linkItem;
  final ComicItem comicItem;

  const ComicInfoCard(
    this.comicItem, {
    this.linkItem = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var info = comicItem.comicIntroduction;
    var theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(right: 10),
            child: ComicIntroductionImg(
              comicId: comicItem.comicId,
              scope: "img1",
              url: info.img1,
              width: coverWidth,
              height: coverHeight,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      linkItem
                          ? GestureDetector(
                              onLongPress: () {
                                confirmCopy(context, info.title);
                              },
                              child: Text(info.title, style: titleStyle),
                            )
                          : Text(info.title, style: titleStyle),
                      Container(height: 5),
                      linkItem
                          ? InkWell(
                              onTap: () {
                                // todo 跳转，并且像tag一样支持多个
                                // navPushOrReplace(
                                //     context,
                                //     (context) =>
                                //         SearchScreen(keyword: info.author));
                              },
                              onLongPress: () {
                                confirmCopy(
                                    context, info.artistList.join(" / "));
                              },
                              child: Text(info.artistList.join(" / "),
                                  style: authorStyle),
                            )
                          : Text(info.artistList.join(" / "),
                              style: authorStyle),
                      Container(height: 5),
                      Text.rich(
                        linkItem
                            ? TextSpan(
                                children: [
                                  TextSpan(
                                      text: AppLocalizations.of(context)!.tags +
                                          ' :'),
                                  ...info.tags.map(
                                    (e) => TextSpan(
                                      children: [
                                        const TextSpan(text: ' '),
                                        TextSpan(
                                          text: e,
                                          // todo 跳转
                                          // recognizer: TapGestureRecognizer()
                                          //   ..onTap = () => navPushOrReplace(
                                          //         context,
                                          //         (context) => ComicsScreen(
                                          //           category: e,
                                          //         ),
                                          //       ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : TextSpan(
                                text: AppLocalizations.of(context)!.tags +
                                    " : ${info.tags.join(' ')}"),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .color!
                              .withAlpha(0xCC),
                        ),
                      ),
                      Container(height: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const double _iconSize = 15;

const titleStyle = TextStyle(fontWeight: FontWeight.bold);
final authorStyle = TextStyle(
  fontSize: 13,
  color: Colors.pink.shade300,
);
