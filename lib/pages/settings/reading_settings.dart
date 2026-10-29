part of pica_settings;

class ReadingSettings extends StatefulWidget {
  const ReadingSettings(this.popUp, {super.key});

  final bool popUp;

  @override
  State<ReadingSettings> createState() => _ReadingSettingsState();
}

class _ReadingSettingsState extends State<ReadingSettings> {
  bool keepScreenOn = appdata.settings[14] == "1";
  bool lowBrightness = appdata.settings[18] == "1";
  bool pageChangeValue = appdata.settings[0] == "1";
  bool showThreeButton = appdata.settings[4] == "1";
  bool useVolumeKeyChangePage = appdata.settings[7] == "1";

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiuixSmallTitle("翻页与控制".tl),
        MiuixSettingsCard(
          children: [
            SelectSetting(
              leading: _mi(MiuixIcons.os4.read),
              title: "阅读模式".tl,
              initialValue: int.parse(appdata.settings[9]) - 1,
              values: [
                "从左至右".tl,
                "从右至左".tl,
                "从上至下".tl,
                "从上至下(连续)".tl,
                "双页".tl,
                "双页(反向)".tl
              ],
              onChanged: (i) {
                appdata.settings[9] = (i + 1).toString();
                appdata.updateSettings();
              },
            ),
            SwitchSetting(
              title: "点按翻页".tl,
              settingsIndex: 0,
              icon: _mi(MiuixIcons.os4.ok),
            ),
            SwitchSetting(
              title: "反转点按翻页".tl,
              settingsIndex: 70,
              icon: _mi(MiuixIcons.os4.replace),
            ),
            if (App.isAndroid)
              SwitchSetting(
                title: "使用音量键翻页".tl,
                settingsIndex: 7,
                icon: _mi(MiuixIcons.os4.volumeUp),
              ),
            MiuixSliderPreference(
              startAction: _mi(MiuixIcons.os4.timer),
              title: "自动翻页时间间隔".tl,
              value: (int.tryParse(appdata.settings[33]) ?? 5).toDouble().clamp(1.0, 20.0),
              min: 1,
              max: 20,
              steps: 19,
              valueText: "${appdata.settings[33]}s",
              onValueChange: (v) {
                setState(() {
                  appdata.settings[33] = v.toInt().toString();
                });
                appdata.updateSettings();
              },
            ),
            SwitchSetting(
              title: "宽屏时显示控制按钮".tl,
              settingsIndex: 4,
              icon: _mi(MiuixIcons.os4.screenMirroring),
            ),
          ],
        ),
        MiuixSmallTitle("显示与屏幕".tl),
        MiuixSettingsCard(
          children: [
            if (App.isAndroid)
              SwitchSetting(
                title: "保持屏幕常亮".tl,
                settingsIndex: 14,
                icon: _mi(MiuixIcons.os4.screenCapture),
              ),
            SwitchSetting(
              title: "深色模式下降低图片亮度".tl,
              settingsIndex: 18,
              icon: _mi(MiuixIcons.os4.theme),
            ),
            SwitchSetting(
              title: "使用深色背景".tl,
              settingsIndex: 81,
              icon: _mi(MiuixIcons.os4.background),
            ),
            if (App.isAndroid)
              SelectSetting(
                leading: _mi(MiuixIcons.os4.rotateLeft),
                title: "固定屏幕方向".tl,
                initialValue: int.parse(appdata.settings[76]),
                values: [
                  "禁用".tl,
                  "横屏".tl,
                  "竖屏".tl,
                ],
                onChanged: (i) {
                  appdata.settings[76] = i.toString();
                  appdata.updateSettings();
                },
              ),
            SwitchSetting(
              title: "显示页面信息".tl,
              settingsIndex: 57,
              icon: _mi(MiuixIcons.os4.file),
            ),
          ],
        ),
        MiuixSmallTitle("缩放与加载".tl),
        MiuixSettingsCard(
          children: [
            SelectSetting(
              leading: _mi(MiuixIcons.os4.image),
              title: "图片预加载".tl,
              initialValue: ["0", "1", "2", "3", "4", "5", "10", "15"].indexOf(appdata.settings[28]),
              values: const ["0", "1", "2", "3", "4", "5", "10", "15"],
              onChanged: (i) {
                appdata.settings[28] = ["0", "1", "2", "3", "4", "5", "10", "15"][i];
                appdata.updateSettings();
              },
            ),
            SwitchSetting(
              title: "双击缩放".tl,
              settingsIndex: 49,
              icon: _mi(MiuixIcons.os4.trim),
            ),
            SwitchSetting(
              title: "长按缩放".tl,
              settingsIndex: 55,
              icon: _mi(MiuixIcons.os4.zoomOut),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16))
      ],
    );
  }
}
