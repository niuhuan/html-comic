import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../configs/version.dart';
import '../cross.dart';
import 'components/badge.dart';

const _releasesUrl = "https://github.com/niuhuan/html-comic/releases";

// 关于
class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    versionEvent.subscribe(_onVersion);
    super.initState();
  }

  @override
  void dispose() {
    versionEvent.unsubscribe(_onVersion);
    super.dispose();
  }

  void _onVersion(dynamic a) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var _currentVersion = currentVersion();
    var _latestVersion = latestVersion();
    var _latestVersionInfo = latestVersionInfo();
    var _dirty = dirtyVersion();
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        children: [
          SizedBox(
            width: min / 2,
            height: min / 2,
            child: Center(
              child: SvgPicture.asset(
                'lib/assets/github.svg',
                width: min / 3,
                height: min / 3,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Container(height: 20),
          const Divider(),
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '软件版本 : $_currentVersion',
                  style: const TextStyle(
                    height: 1.3,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      "检查更新 : ",
                      style: TextStyle(
                        height: 1.3,
                      ),
                    ),
                    _dirty ? _buildDirty() : _buildNewVersion(_latestVersion),
                    Expanded(child: Container()),
                  ],
                ),
                _buildNewVersionInfo(_latestVersionInfo),
              ],
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(20),
            child: const SelectableText(
              "提示 : \n"
              "1. 详情页的作者/上传者/分类/标签都可以点击\n"
              "2. 详情页的作者/上传者/标题长按可以复制\n"
              "3. 使用分页而不是瀑布流点击页码可以快速翻页\n"
              "4. 下载指的是缓存到本地, 需要导出才可以分享\n"
              "5. 下载长按可以删除\n",
              style: TextStyle(
                height: 1.3,
              ),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  _buildNewVersion(String? latestVersion) {
    if (latestVersion != null) {
      return Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              child: Badged(
                child: Container(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    latestVersion,
                    style: const TextStyle(height: 1.3),
                  ),
                ),
                badge: "1",
              ),
            ),
            const TextSpan(text: "  "),
            TextSpan(
              text: "去下载",
              style: TextStyle(
                height: 1.3,
                color: Theme.of(context).colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => openUrl(_releasesUrl),
            ),
          ],
        ),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: "未检测到新版本", style: TextStyle(height: 1.3)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(left: 3, right: 3),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
          TextSpan(
            text: "检查更新",
            style: TextStyle(
              height: 1.3,
              color: Theme.of(context).colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => manualCheckNewVersion(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDirty() {
    return Badged(
      child: Text.rich(
        TextSpan(
          text: "下载RELEASE版     ",
          style: TextStyle(
            height: 1.3,
            color: Theme.of(context).colorScheme.primary,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => openUrl(_releasesUrl),
        ),
      ),
      badge: "1",
    );
  }

  Widget _buildNewVersionInfo(String? latestVersionInfo) {
    if (latestVersionInfo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text("更新内容:"),
          Container(
            padding: const EdgeInsets.all(15),
            child: Text(
              latestVersionInfo,
              style: const TextStyle(),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Container(
          padding: const EdgeInsets.all(15),
          child: Text.rich(
            TextSpan(
              text: "去RELEASE仓库",
              style: TextStyle(
                height: 1.3,
                color: Theme.of(context).colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => openUrl(_releasesUrl),
            ),
          ),
        ),
      ],
    );
  }
}
