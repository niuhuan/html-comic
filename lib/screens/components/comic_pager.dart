import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html/ffi.dart';
import 'package:html/screens/components/comic_info_card.dart';
import 'package:html/screens/components/content_builder.dart';

import '../../configs/pager_action.dart';
import 'comic_list.dart';
import 'fit_button.dart';

// 漫画列页
class ComicPager extends StatefulWidget {
  final Future<ComicIdPage> Function(int offset, int limit) fetchPage;

  const ComicPager({required this.fetchPage, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicPagerState();
}

class _ComicPagerState extends State<ComicPager> {
  @override
  Widget build(BuildContext context) {
    switch (currentPagerAction()) {
      case PagerAction.controller:
        return ControllerComicPager(fetchPage: widget.fetchPage);
      case PagerAction.stream:
        return StreamComicPager(fetchPage: widget.fetchPage);
      default:
        return Container();
    }
  }
}

class ControllerComicPager extends StatefulWidget {
  final Future<ComicIdPage> Function(int offset, int limit) fetchPage;

  const ControllerComicPager({
    Key? key,
    required this.fetchPage,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ControllerComicPagerState();
}

class _ControllerComicPagerState extends State<ControllerComicPager> {
  final TextEditingController _textEditController =
      TextEditingController(text: '');

  late Future _loadFuture;
  late Key _loadKey;
  static const _pageSize = 15;
  int _currentPage = 1;
  int _maxPage = 0;
  int _total = 0;
  final List<ComicItem> _list = [];

  Future _load() async {
    var idPage =
        await widget.fetchPage((_currentPage - 1) * _pageSize, _pageSize);
    _currentPage = idPage.offset ~/ _pageSize + 1;
    _maxPage = (idPage.total / _pageSize).ceil();
    _total = idPage.total;
    Map<int, Future<ComicIntroduction>> fsMap = {};
    for (var e in idPage.records) {
      fsMap[e] = native.comicIntroduction(id: e);
    }
    _list.clear();
    for (var value in idPage.records) {
      _list.add(ComicItem(value, await fsMap[value]!));
    }
    setState(() {});
  }

  @override
  void initState() {
    _loadFuture = _load();
    _loadKey = UniqueKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: ContentBuilder(
        key: _loadKey,
        future: _loadFuture,
        onRefresh: () async {
          setState(() {
            _loadFuture = _load();
            _loadKey = UniqueKey();
          });
        },
        successBuilder: (
          BuildContext context,
          AsyncSnapshot snapshot,
        ) {
          return ComicList(
            _list,
            appendWidget: _buildNextButton(),
          );
        },
      ),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: .5,
              style: BorderStyle.solid,
              color: Colors.grey[200]!,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                _textEditController.clear();
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Card(
                        child: TextField(
                          controller: _textEditController,
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.inputPageNumber,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'\d+')),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        MaterialButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        MaterialButton(
                          onPressed: () {
                            Navigator.pop(context);
                            var text = _textEditController.text;
                            if (text.isEmpty || text.length > 5) {
                              return;
                            }
                            var num = int.parse(text);
                            if (num == 0 || num > _maxPage) {
                              return;
                            }
                            _currentPage = num;
                            setState(() {
                              _loadFuture = _load();
                              _loadKey = UniqueKey();
                            });
                          },
                          child: Text(AppLocalizations.of(context)!.ok),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Row(
                children: [
                  Text(
                      " ${AppLocalizations.of(context)!.pages} $_currentPage / $_maxPage "),
                ],
              ),
            ),
            Row(
              children: [
                MaterialButton(
                  minWidth: 0,
                  onPressed: () {
                    if (_currentPage > 1) {
                      _currentPage = _currentPage - 1;
                      setState(() {
                        _loadFuture = _load();
                        _loadKey = UniqueKey();
                      });
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.prePage),
                ),
                MaterialButton(
                  minWidth: 0,
                  onPressed: () {
                    if (_currentPage < _maxPage) {
                      _currentPage = _currentPage + 1;
                      setState(() {
                        _loadFuture = _load();
                        _loadKey = UniqueKey();
                      });
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.nextPage),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildNextButton() {
    if (_currentPage < _maxPage) {
      return FitButton(
        onPressed: () {
          _currentPage = _currentPage + 1;
          setState(() {
            _loadFuture = _load();
            _loadKey = UniqueKey();
          });
        },
        text: AppLocalizations.of(context)!.nextPage,
      );
    }
    return null;
  }
}

class StreamComicPager extends StatefulWidget {
  final Future<ComicIdPage> Function(int offset, int limit) fetchPage;

  const StreamComicPager({
    Key? key,
    required this.fetchPage,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _StreamComicPagerState();
}

class _StreamComicPagerState extends State<StreamComicPager> {
  final _scrollController = ScrollController();

  static const _pageSize = 15;
  int _nextPage = 1;
  int _currentPage = 0;
  int _maxPage = 0;
  int _total = 0;
  final List<ComicItem> _list = [];
  late bool _loading = false;
  late bool _error = false;

  void _onScroll() {
    if (_nextPage > _maxPage || _error || _loading) {
      return;
    }
    if (_scrollController.offset + MediaQuery.of(context).size.height / 2 <
        _scrollController.position.maxScrollExtent) {
      return;
    }
    _load();
  }

  Future<dynamic> _load() async {
    setState(() {
      //_pageFuture =
      _fetch();
    });
  }

  Future<dynamic> _fetch() async {
    _error = false;
    setState(() {
      _loading = true;
    });
    try {
      ////////////////////

      var idPage =
          await widget.fetchPage((_nextPage - 1) * _pageSize, _pageSize);
      int _currentPage = idPage.offset ~/ _pageSize + 1;
      int _maxPage = (idPage.total / _pageSize).ceil();
      int _total = idPage.total;
      Map<int, Future<ComicIntroduction>> fsMap = {};
      idPage.records.map((e) => fsMap[e] = native.comicIntroduction(id: e));
      List<ComicItem> _list = [];
      for (var value in idPage.records) {
        _list.add(ComicItem(value, await fsMap[value]!));
      }
      ///////////////////
      setState(() {
        _nextPage = _currentPage + 1;
        this._currentPage = _currentPage;
        this._maxPage = _maxPage;
        this._total = _total;
        this._list.addAll(_list);
      });
    } catch (e, s) {
      _error = true;
      print("$e\n$s");
      rethrow;
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    _load();
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: ComicList(
        _list,
        controller: _scrollController,
        appendWidget: _buildLoadingCell(),
      ),
    );
  }

  PreferredSize _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: .5,
              style: BorderStyle.solid,
              color: Colors.grey[200]!,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                    " ${AppLocalizations.of(context)!.pages} ${_currentPage - 1} / $_maxPage "),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildLoadingCell() {
    if (_error) {
      return FitButton(
        onPressed: () {
          setState(() {
            _error = false;
          });
          _load();
        },
        text: AppLocalizations.of(context)!.errorTapToRefresh,
      );
    }
    if (_loading) {
      return FitButton(
        onPressed: () {},
        text: AppLocalizations.of(context)!.loading,
      );
    }
    return null;
  }
}
