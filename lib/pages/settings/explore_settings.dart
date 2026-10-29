part of pica_settings;

Widget buildExploreSettings(BuildContext context, bool popUp) {
  var searchSource = <String>[];
  for (var source in ComicSource.sources) {
    searchSource.add(source.key);
  }

  return Column(
    children: [
      MiuixSmallTitle("显示".tl),
      MiuixSettingsCard(
        children: [
          SelectSettingWithAppdata(
            icon: _mi(MiuixIcons.os4.gridView),
            title: "初始页面".tl,
            options: ["我".tl, "收藏".tl, "探索".tl, "分类".tl],
            settingsIndex: 23,
          ),
          NewPageSetting(
            title: "网络收藏页面".tl,
            onTap: () => showPopUpWidget(
              context,
              MultiPagesFilter("网络收藏页面".tl, 68, networkFavorites()),
            ),
            icon: _mi(MiuixIcons.os4.favorites),
          ),
          NewPageSetting(
            title: "探索页面".tl,
            onTap: () => setExplorePages(context),
            icon: _mi(MiuixIcons.os4.layers),
          ),
          NewPageSetting(
            title: "分类页面".tl,
            onTap: () => showPopUpWidget(
              context,
              MultiPagesFilter("分类页面".tl, 67, categoryPages()),
            ),
            icon: _mi(MiuixIcons.os4.listView),
          ),
          SelectSettingWithAppdata(
            icon: _mi(MiuixIcons.os4.sort),
            title: "漫画列表显示方式".tl,
            options: ["连续模式".tl, "分页模式".tl],
            settingsIndex: 25,
          ),
          NewPageSetting(
            title: "关键词屏蔽".tl,
            onTap: () => showPopUpWidget(
              context,
              BlockingKeywordPage(popUp: MediaQuery.of(context).size.width > 600),
            ),
            icon: _mi(MiuixIcons.os4.blocklist),
          ),
          SwitchSetting(
            title: "完全隐藏屏蔽的作品".tl,
            settingsIndex: 83,
            icon: _mi(MiuixIcons.os4.hide),
          ),
        ],
      ),
      MiuixSmallTitle("工具".tl),
      MiuixSettingsCard(
        children: [
          SwitchSetting(
            title: "检查剪切板中的链接".tl,
            settingsIndex: 61,
            icon: _mi(MiuixIcons.os4.image),
          ),
          SelectSetting(
            leading: _mi(MiuixIcons.os4.search),
            title: "默认搜索源".tl,
            values: searchSource,
            initialValue: (() { final i = searchSource.indexOf(appdata.appSettings.initialSearchTarget); return i < 0 ? 0 : i; })(),
            onChanged: (i) {
              appdata.appSettings.initialSearchTarget = searchSource[i];
              appdata.updateSettings();
            },
          ),
          SwitchSetting(
            title: "启用侧边翻页栏".tl,
            icon: _mi(MiuixIcons.os4.sidebar),
            settingsIndex: 64,
          ),
          SelectSettingWithAppdata(
            title: "自动添加语言筛选".tl,
            settingsIndex: 69,
            options: ["无".tl, "chinese", "english", "japanese"],
            icon: _mi(MiuixIcons.os4.translate),
          ),
        ],
      ),
      MiuixSmallTitle("漫画块 · 外观".tl),
      MiuixSettingsCard(
        children: [
          const ComicTileDisplayModeSetting(),
          ScaleSliderSetting(
            icon: _mi(MiuixIcons.os4.zoomOut),
            title: "漫画块大小".tl,
            settingsIndex: 91,
            onFinished: () => MyApp.updater?.call(),
          ),
          SelectSettingWithAppdata(
            title: "缩略图填充方式".tl,
            settingsIndex: 66,
            options: ["覆盖".tl, "容纳".tl],
            icon: _mi(MiuixIcons.os4.image),
            onChanged: () => MyApp.updater?.call(),
          ),
        ],
      ),
      MiuixSmallTitle("漫画块 · 标记".tl),
      MiuixSettingsCard(
        children: [
          SwitchSetting(
            title: "显示收藏状态".tl,
            settingsIndex: 72,
            icon: _mi(MiuixIcons.os4.favorites),
            onChanged: () => MyApp.updater?.call(),
          ),
          SwitchSetting(
            title: "显示阅读位置".tl,
            settingsIndex: 73,
            icon: _mi(MiuixIcons.os4.recent),
            onChanged: () => MyApp.updater?.call(),
          ),
        ],
      ),
      Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16))
    ],
  );
}

Map<String, String> categoryPages(){
  return {
    for(var source in ComicSource.sources)
      if(source.categoryData != null)
        source.categoryData!.key: source.categoryData!.title.tl
  };
}

Map<String, String> networkFavorites(){
  return {
    for(var source in ComicSource.sources)
      if(source.favoriteData != null)
        source.key: source.favoriteData!.title.tl
  };
}

/// 漫画块显示模式（详细 / 简略）。设置页与欢迎页共用。
class ComicTileDisplayModeSetting extends StatelessWidget {
  const ComicTileDisplayModeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectSetting(
      leading: _mi(MiuixIcons.os4.gridView),
      title: "漫画块显示模式".tl,
      values: ["详细".tl, "简略".tl],
      initialValue: appdata.appSettings.comicTileDisplayType,
      onChanged: (i) {
        appdata.appSettings.comicTileDisplayType = i;
        appdata.updateSettings();
        MyApp.updater?.call();
      },
    );
  }
}

/// 0.75–1.25 的缩放滑块：显示百分比，带「恢复默认」，松手后保存并回调。
class ScaleSliderSetting extends StatefulWidget {
  const ScaleSliderSetting({
    super.key,
    required this.icon,
    required this.title,
    required this.settingsIndex,
    this.onFinished,
  });

  final Widget icon;
  final String title;
  final int settingsIndex;
  final VoidCallback? onFinished;

  @override
  State<ScaleSliderSetting> createState() => _ScaleSliderSettingState();
}

class _ScaleSliderSettingState extends State<ScaleSliderSetting> {
  late double _value = _read();

  double _read() =>
      ((double.tryParse(appdata.settings[widget.settingsIndex]) ?? 1.0)
                  .clamp(0.6, 1.4) *
              100)
          .roundToDouble() /
      100;

  /// 拖动中只改本地值；松手（或恢复默认）才写设置、保存并刷新列表。
  void _commit() {
    appdata.settings[widget.settingsIndex] = _value.toStringAsFixed(2);
    appdata.updateSettings();
    widget.onFinished?.call();
  }

  Widget _resetCapsule(BuildContext context, bool visible) {
    final colors = MiuixTheme.of(context).colors;
    // 始终占位，只切换可见性，避免按钮出现/消失时整行跳动。
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _value = 1.0);
            _commit();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "恢复默认".tl,
              style: TextStyle(fontSize: 11, color: colors.primary, height: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _value;
    return MiuixSliderPreference(
      startAction: widget.icon,
      title: widget.title,
      value: v,
      min: 0.6,
      max: 1.4,
      steps: 79, // 81 个刻度：每格 1%
      valueText: "${(v * 100).round()}%",
      endActions: [_resetCapsule(context, (v - 1.0).abs() > 0.001)],
      onValueChange: (nv) {
        final r = (nv * 100).roundToDouble() / 100;
        if (r != _value) setState(() => _value = r);
      },
      onValueChangeFinished: _commit,
    );
  }
}
