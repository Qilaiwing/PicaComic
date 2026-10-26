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
  const JmSettings(this.popUp, {Key? key}) : super(key: key);
  final bool popUp;

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
    return Column(
      children: [
        MiuixSmallTitle("禁漫天堂设置".tl),
        MiuixSettingsCard(
          children: [
            MiuixSwitchPreference(
              startAction: const Icon(Icons.track_changes),
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
              leading: const Icon(Icons.dns),
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
              leading: const Icon(Icons.dns_outlined),
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
              leading: const Icon(Icons.favorite_border),
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
              startAction: const Icon(Icons.update_outlined),
              title: "更新API域名".tl,
              onClick: () => JmSettings.updateApiDomains(true),
            ),
            MiuixSwitchPreference(
              startAction: const Icon(Icons.today),
              title: "自动签到".tl,
              summary: "勾选启用, 点击测试".tl,
              value: autoCheckIn,
              onChanged: (b) {
                b ? appdata.settings[88] = "1" : appdata.settings[88] = "0";
                setState(() {
                  autoCheckIn = b;
                });
                appdata.updateSettings();
                if (autoCheckIn && jm.isLogin) JmSettings.daily(false);
              },
            ),
          ],
        ),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16))
      ],
    );
  }
}