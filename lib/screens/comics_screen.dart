import 'package:flutter/material.dart';
import 'package:html/ffi.dart';
import 'package:html/screens/components/badge.dart';
import 'package:html/screens/components/comic_pager.dart';
import 'package:html/screens/settings_screen.dart';

class ComicsScreen extends StatefulWidget {
  const ComicsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicsScreenState();
}

class _ComicsScreenState extends State<ComicsScreen> {
  Future<ComicIdPage> _fetchPage(int offset, int limit) async {
    return native.comics(
      sortType: 'index',
      lang: 'all',
      offset: offset,
      limit: limit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (BuildContext context) {
                  return const SettingsScreen();
                }),
              );
            },
            icon: const VersionBadged(
              child: Icon(Icons.settings),
            ),
          ),
        ],
      ),
      body: ComicPager(fetchPage: _fetchPage),
    );
  }
}
