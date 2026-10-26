part of pica_settings;

class LocalFavoritesSettings extends StatefulWidget {
  const LocalFavoritesSettings({super.key});

  @override
  State<LocalFavoritesSettings> createState() => _LocalFavoritesSettingsState();
}

class _LocalFavoritesSettingsState extends State<LocalFavoritesSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MiuixSmallTitle("本地收藏管理".tl),
        MiuixSettingsCard(
          children: [
            SelectSetting(
              leading: const Icon(Icons.book),
              title: "快速收藏".tl,
              initialValue: LocalFavoritesManager()
                  .folderNames
                  .indexOf(appdata.settings[51]),
              onChanged: (i) {
                appdata.settings[51] =
                    LocalFavoritesManager().folderNames[i];
                appdata.updateSettings();
              },
              values: LocalFavoritesManager().folderNames,
            ),
            SelectSettingWithAppdata(
              icon: const Icon(Icons.bookmark_add),
              title: "新收藏添加至".tl,
              options: ["最后".tl, "最前".tl],
              settingsIndex: 53,
            ),
            SelectSettingWithAppdata(
              icon: const Icon(Icons.move_up),
              title: "阅读后移动本地收藏至".tl,
              options: ["无操作".tl, "最后".tl, "最前".tl],
              settingsIndex: 54,
            ),
            SelectSettingWithAppdata(
              icon: const Icon(Icons.touch_app),
              title: "点击漫画时".tl,
              options: ["查看信息".tl, "阅读".tl],
              settingsIndex: 60,
            ),
            SelectSetting(
              leading: const Icon(Icons.sync),
              title: "下拉更新拉取页数".tl,
              initialValue: ["1", "2", "3", "4", "5", "10", "99"]
                  .indexOf(appdata.settings[71]),
              values: const ["1", "2", "3", "4", "5", "10", "99"],
              onChanged: (i) {
                appdata.settings[71] =
                    ["1", "2", "3", "4", "5", "10", "99"][i];
                appdata.updateSettings();
              },
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
        )
      ],
    );
  }
}
