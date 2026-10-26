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
            icon: const Icon(Icons.home_outlined),
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
            icon: const Icon(Icons.local_activity_outlined),
          ),
          NewPageSetting(
            title: "探索页面".tl,
            onTap: () => setExplorePages(context),
            icon: const Icon(Icons.explore_outlined),
          ),
          NewPageSetting(
            title: "分类页面".tl,
            onTap: () => showPopUpWidget(
              context,
              MultiPagesFilter("分类页面".tl, 67, categoryPages()),
            ),
            icon: const Icon(Icons.account_tree_outlined),
          ),
          SelectSettingWithAppdata(
            icon: const Icon(Icons.list),
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
            icon: const Icon(Icons.block),
          ),
          SwitchSetting(
            title: "完全隐藏屏蔽的作品".tl,
            settingsIndex: 83,
            icon: const Icon(Icons.visibility_off),
          ),
        ],
      ),
      MiuixSmallTitle("工具".tl),
      MiuixSettingsCard(
        children: [
          SwitchSetting(
            title: "检查剪切板中的链接".tl,
            settingsIndex: 61,
            icon: const Icon(Icons.image),
          ),
          SelectSetting(
            leading: const Icon(Icons.search),
            title: "默认搜索源".tl,
            values: searchSource,
            initialValue: searchSource.indexOf(appdata.appSettings.initialSearchTarget),
            onChanged: (i) {
              appdata.appSettings.initialSearchTarget = searchSource[i];
              appdata.updateSettings();
            },
          ),
          SwitchSetting(
            title: "启用侧边翻页栏".tl,
            icon: const Icon(Icons.border_right),
            settingsIndex: 64,
          ),
          SelectSettingWithAppdata(
            title: "自动添加语言筛选".tl,
            settingsIndex: 69,
            options: ["无".tl, "chinese", "english", "japanese"],
            icon: const Icon(Icons.translate),
          ),
        ],
      ),
      MiuixSmallTitle("漫画块".tl),
      MiuixSettingsCard(
        children: [
          SelectSetting(
            leading: const Icon(Icons.web),
            title: "漫画块显示模式".tl,
            initialValue: int.parse(appdata.settings[44].split(',').first),
            onChanged: (i) {
              var settings = appdata.settings[44].split(',');
              settings[0] = i.toString();
              if (settings.length == 1) {
                settings.add("1.0");
              }
              appdata.settings[44] = settings.join(',');
              appdata.updateSettings();
              MyApp.updater?.call();
            },
            values: ["详细".tl, "简略".tl],
          ),
          StatefulBuilder(builder: (context, setState) {
            final currentVal = double.parse(
                appdata.settings[44].split(',').elementAtOrNull(1) ?? "1.00");
            return MiuixSliderPreference(
              startAction: const Icon(Icons.crop_free),
              title: "漫画块大小".tl,
              value: currentVal,
              min: 0.75,
              max: 1.25,
              steps: 10,
              valueText: currentVal.toStringAsFixed(2),
              onValueChange: (v) {
                var settings = appdata.settings[44].split(',');
                if (settings.length == 1) {
                  settings.add(v.toStringAsFixed(2));
                } else {
                  settings[1] = v.toStringAsFixed(2);
                }
                setState(() {
                  appdata.settings[44] = settings.join(',');
                });
              },
              onValueChangeFinished: () {
                appdata.updateSettings();
              },
            );
          }),
          SelectSettingWithAppdata(
            title: "漫画块缩略图布局".tl,
            settingsIndex: 66,
            options: ["覆盖".tl, "容纳".tl],
            icon: const Icon(Icons.image),
          ),
          SwitchSetting(
            title: "显示收藏状态".tl,
            settingsIndex: 72,
            icon: const Icon(Icons.bookmark),
          ),
          SwitchSetting(
            title: "显示阅读位置".tl,
            settingsIndex: 73,
            icon: const Icon(Icons.history_toggle_off),
          ),
          StatefulBuilder(builder: (context, setState) {
            final currentVal = double.parse(appdata.settings[74]);
            return MiuixSliderPreference(
              startAction: const Icon(Icons.crop_free),
              title: "图片收藏大小".tl,
              value: currentVal,
              min: 0.75,
              max: 1.25,
              steps: 10,
              valueText: currentVal.toStringAsFixed(2),
              onValueChange: (v) {
                setState(() {
                  appdata.settings[74] = v.toStringAsFixed(2);
                });
              },
              onValueChangeFinished: () {
                appdata.updateSettings();
              },
            );
          }),
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