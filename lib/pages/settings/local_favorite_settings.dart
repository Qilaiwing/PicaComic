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
            if (LocalFavoritesManager().folderNames.isEmpty)
              MiuixArrowPreference(
                startAction: _mi(MiuixIcons.os4.book),
                title: "快速收藏".tl,
                summary: "暂无收藏夹".tl,
                onClick: () =>
                    showToast(message: "请先创建本地收藏夹".tl),
              )
            else
            SelectSetting(
              leading: _mi(MiuixIcons.os4.book),
              title: "快速收藏".tl,
              initialValue: (() {
                final names = LocalFavoritesManager().folderNames;
                if (names.isEmpty) return 0;
                final i = names.indexOf(appdata.settings[51]);
                return i < 0 ? 0 : i;
              })(),
              onChanged: (i) {
                appdata.settings[51] =
                    LocalFavoritesManager().folderNames[i];
                appdata.updateSettings();
              },
              values: LocalFavoritesManager().folderNames,
            ),
            SelectSettingWithAppdata(
              icon: _mi(MiuixIcons.os4.addBookmark),
              title: "新收藏添加至".tl,
              options: ["最后".tl, "最前".tl],
              settingsIndex: 53,
            ),
            SelectSettingWithAppdata(
              icon: _mi(MiuixIcons.os4.moveFile),
              title: "阅读后移动本地收藏至".tl,
              options: ["无操作".tl, "最后".tl, "最前".tl],
              settingsIndex: 54,
            ),
            SelectSettingWithAppdata(
              icon: _mi(MiuixIcons.os4.ok),
              title: "点击漫画时".tl,
              options: ["查看信息".tl, "阅读".tl],
              settingsIndex: 60,
            ),
            SelectSetting(
              leading: _mi(MiuixIcons.os4.refresh),
              title: "下拉更新拉取页数".tl,
              initialValue: ["1", "2", "3", "4", "5", "10", "99"]
                  .indexOf(appdata.settings[71])
                  .clamp(0, 6),
              values: const ["1", "2", "3", "4", "5", "10", "99"],
              onChanged: (i) {
                appdata.settings[71] =
                    ["1", "2", "3", "4", "5", "10", "99"][i];
                appdata.updateSettings();
              },
            ),
          ],
        ),
        MiuixSmallTitle("图片收藏".tl),
        MiuixSettingsCard(
          children: [
            ScaleSliderSetting(
              icon: _mi(MiuixIcons.os4.photos),
              title: "图片收藏大小".tl,
              settingsIndex: 74,
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
