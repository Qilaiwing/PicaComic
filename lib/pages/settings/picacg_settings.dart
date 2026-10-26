part of pica_settings;

class PicacgSettings extends StatefulWidget {
  const PicacgSettings(this.popUp, {Key? key}) : super(key: key);
  final bool popUp;

  @override
  State<PicacgSettings> createState() => _PicacgSettingsState();
}

class _PicacgSettingsState extends State<PicacgSettings> {
  bool showFrame = appdata.settings[5] == "1";
  bool punchIn = appdata.settings[6] == "1";
  bool useMyServer = appdata.settings[3] == "1";

  static const _imageQualityValues = ["low", "middle", "high", "original"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MiuixSmallTitle("哔咔漫画".tl),
        MiuixSettingsCard(
          children: [
            SelectSetting(
              leading: const Icon(Icons.dns),
              title: "设置分流".tl,
              initialValue: int.parse(picacg.data['appChannel']) - 1,
              values: ["分流1".tl, "分流2".tl, "分流3".tl],
              onChanged: (i) {
                picacg.data['appChannel'] = (i + 1).toString();
                picacg.saveData();
              },
            ),
            SelectSetting(
              leading: const Icon(Icons.image),
              title: "设置图片质量".tl,
              initialValue:
                  _imageQualityValues.indexOf(picacg.data['imageQuality']),
              values: ["低".tl, "中".tl, "高".tl, "原图".tl],
              onChanged: (i) {
                picacg.data['imageQuality'] = _imageQualityValues[i];
                picacg.saveData();
              },
            ),
            SelectSetting(
              leading: const Icon(Icons.manage_search_outlined),
              initialValue: appdata.getSearchMode(),
              values: ["新到旧".tl, "旧到新".tl, "最多喜欢".tl, "最多指名".tl],
              onChanged: (i) {
                appdata.setSearchMode(i);
              },
              title: "搜索及分类排序模式".tl,
            ),
            SelectSetting(
              leading: const Icon(Icons.collections_bookmark_outlined),
              initialValue: int.parse(appdata.settings[30]),
              values: ["旧到新".tl, "新到旧".tl],
              onChanged: (i) {
                appdata.settings[30] = i.toString();
                appdata.updateSettings();
              },
              title: "收藏夹漫画排序模式".tl,
            ),
            MiuixSwitchPreference(
              startAction: const Icon(Icons.circle_outlined),
              title: "显示头像框".tl,
              value: showFrame,
              onChanged: (b) {
                b ? appdata.settings[5] = "1" : appdata.settings[5] = "0";
                setState(() {
                  showFrame = b;
                });
                appdata.writeData();
              },
            ),
            MiuixSwitchPreference(
              startAction: const Icon(Icons.today),
              title: "自动打卡".tl,
              summary: App.isMobile
                  ? "APP启动或是距离上次打卡间隔一天时执行".tl
                  : "启动时执行".tl,
              value: punchIn,
              onChanged: (b) {
                b ? appdata.settings[6] = "1" : appdata.settings[6] = "0";
                if (App.isMobile) {
                  b ? runBackgroundService() : cancelBackgroundService();
                }
                setState(() {
                  punchIn = b;
                });
                appdata.writeData();
              },
            ),
          ],
        ),
      ],
    );
  }
}
