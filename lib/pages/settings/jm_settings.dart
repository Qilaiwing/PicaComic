part of pica_settings;

class SetJmComicsOrderController extends StateController{
  int settingsOrder;
  SetJmComicsOrderController(this.settingsOrder);
  late String value = appdata.settings[settingsOrder];

  void set(String v){
    value = v;
    appdata.settings[settingsOrder] = v;
    appdata.writeData();
    App.globalBack();
  }
}


class JmSettings extends StatefulWidget {
  const JmSettings(this.popUp, {this.embedded = false, Key? key}) : super(key: key);
  final bool popUp;
  final bool embedded;

  @override
  State<JmSettings> createState() => _JmSettingsState();

  static const builtInApiDomains = <String>[
    "www.cdntwice.org",
    "www.cdnsha.org",
    "www.cdnaspa.cc",
    "www.cdnntr.cc"
  ];

  static void updateApiDomains([bool showLoading = false]) async {
    var title = "";
    var msg = "";
    List<String> domains = builtInApiDomains;
    var controller = showLoading ? showLoadingDialog(App.globalContext!) : null;
    var res = await JmNetwork().getApiDomains();
    if (res.error) {
      title += "更新失败".tl;
      msg += "${"使用内置域名:".tl}\n";
    } else {
      title += "更新成功".tl;
      domains = res.data;
    }
    controller?.close();
    for (String domain in domains) {
        msg += "${"域名".tl}${domains.indexOf(domain) + 1}: $domain\n";
    }
    msg = msg.trim();
    showConfirmDialog(App.globalContext!, title, msg, () async {
      appdata.appSettings.jmApiDomains = domains;
      await updateAppVersionCode();
      JmNetwork().loginFromAppdata();
    });
  }

  static void daily([bool showLoading = false]) async {
    if (!jm.isLogin && showLoading) {
      showToast(message: "未登录".tl);
      return;
    }
    var controller = showLoading ? showLoadingDialog(App.globalContext!) : null;
    var res = await JmNetwork().dailyChk();
    controller?.close();
    var title = res.success ? "签到成功".tl : "签到失败".tl;
    var msg = res.success ? "${res.subData}".tl : res.errorMessage;
    if (showLoading) showDialogMessage(App.globalContext!, title, msg!);
  }

  static Future<void> updateAppVersionCode() async {
    var res = await JmNetwork().getAppVersionCode();
    if (!res.error) {
      appdata.settings[89] = res.data;
      appdata.updateSettings();
    }
  }
}

class _JmSettingsState extends State<JmSettings> {
  bool autoSelectStream = appdata.settings[15] == "1";
  bool autoCheckIn = appdata.settings[88] == "1";

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
            MiuixSwitchPreference(
              startAction: _mi(MiuixIcons.os4.refresh),
              title: "自动选择域名".tl,
              summary: "登录时自动选择API域名".tl,
              value: autoSelectStream,
              onChanged: (b) {
                b ? appdata.settings[15] = "1" : appdata.settings[15] = "0";
                setState(() {
                  autoSelectStream = b;
                });
                appdata.updateSettings();
                if (autoSelectStream) JmNetwork().loginFromAppdata();
              },
            ),
            SelectSetting(
              leading: _mi(MiuixIcons.os4.link),
              title: "API域名".tl,
              initialValue: int.parse(appdata.settings[17]),
              values: [
                "分流1".tl, "分流2".tl, "分流3".tl, "分流4".tl,
              ],
              onChanged: (i) {
                appdata.settings[17] = i.toString();
                appdata.updateSettings();
                JmNetwork().loginFromAppdata();
              },
            ),
            SelectSetting(
              leading: _mi(MiuixIcons.os4.photos),
              title: "图片分流".tl,
              initialValue: int.parse(appdata.appSettings.jmImgUrlIndex),
              values: [
                "分流1".tl, "分流2".tl, "分流3".tl, "分流4".tl
              ],
              onChanged: (i) {
                appdata.settings[37] = i.toString();
                appdata.updateSettings();
                if (jm.isLogin) JmNetwork().updateImgUrl(i + 1);
              },
            ),
            SelectSetting(
              leading: _mi(MiuixIcons.os4.favorites),
              title: "收藏夹漫画排序模式".tl,
              initialValue: int.parse(appdata.settings[42]),
              values: [
                "最新收藏".tl, "最新更新".tl
              ],
              onChanged: (i) {
                appdata.settings[42] = i.toString();
                appdata.updateSettings();
              },
            ),
            MiuixArrowPreference(
              startAction: _mi(MiuixIcons.os4.update),
              title: "更新API域名".tl,
              onClick: () => JmSettings.updateApiDomains(true),
            ),
            MiuixBasicComponent(
              startAction: _mi(MiuixIcons.os4.months),
              title: "自动签到".tl,
              summary: "开关启用；点击整行可测试签到".tl,
              onClick: () => JmSettings.daily(true),
              endActions: [
                MiuixSwitch(
                  value: autoCheckIn,
                  onChanged: (b) {
                    appdata.settings[88] = b ? "1" : "0";
                    setState(() => autoCheckIn = b);
                    appdata.updateSettings();
                    if (b && jm.isLogin) JmSettings.daily(false);
                  },
                ),
              ],
            ),
];
    if (widget.embedded) {
      return Column(mainAxisSize: MainAxisSize.min, children: tiles);
    }
    return Column(
      children: [
        MiuixSmallTitle("禁漫天堂设置".tl),
        MiuixSettingsCard(children: tiles),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16)),
      ],
    );
  }
}