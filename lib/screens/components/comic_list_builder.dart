import 'package:flutter/material.dart';
import 'package:html/screens/components/comic_info_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'comic_list.dart';
import 'content_builder.dart';
import 'fit_button.dart';

class ComicListBuilder extends StatefulWidget {
  final Future<List<ComicItem>> future;
  final Future Function() reload;

  const ComicListBuilder(this.future, this.reload, {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicListBuilderState();
}

class _ComicListBuilderState extends State<ComicListBuilder> {
  @override
  Widget build(BuildContext context) {
    return ContentBuilder(
      future: widget.future,
      onRefresh: widget.reload,
      successBuilder:
          (BuildContext context, AsyncSnapshot<List<ComicItem>> snapshot) {
        return RefreshIndicator(
          onRefresh: widget.reload,
          child: ComicList(
            snapshot.data!,
            appendWidget: FitButton(
              onPressed: widget.reload,
              text: AppLocalizations.of(context)!.refresh,
            ),
          ),
        );
      },
    );
  }
}
