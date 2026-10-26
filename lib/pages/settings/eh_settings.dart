part of pica_settings;

class EhSettings extends StatefulWidget {
  const EhSettings(this.popUp, {Key? key}) : super(key: key);
  final bool popUp;

  @override
  State<EhSettings> createState() => _EhSettingsState();
}

class _EhSettingsState extends State<EhSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MiuixSmallTitle("E-Hentai".tl),
        MiuixSettingsCard(
          children: [
            SelectSetting(
              leading: const Icon(Icons.dns),
              title: "画廊站点".tl,
              initialValue: int.parse(appdata.settings[20]),
              values: const [
                "e-hentai.org",
                "exhentai.org",
              ],
              onChanged: (i) {
                appdata.settings[20] = i.toString();
                appdata.updateSettings();
              },
            ),
            MiuixSwitchPreference(
              startAction: const Icon(Icons.image),
              title: "优先加载原图".tl,
              summary: "可能导致加载失败".tl,
              value: appdata.settings[29] == "1",
              onChanged: (b) {
                setState(() {
                  appdata.settings[29] = b ? "1" : "0";
                });
                appdata.updateSettings();
              },
            ),
            MiuixSwitchPreference(
              startAction: const Icon(Icons.notifications_off_outlined),
              title: "忽略警告".tl,
              value: appdata.settings[47] == "1",
              onChanged: (b) {
                setState(() {
                  appdata.settings[47] = b ? "1" : "0";
                });
                appdata.updateSettings();
              },
            ),
            MiuixSwitchPreference(
              startAction: const Icon(Icons.notes),
              title: "优先显示副标题".tl,
              summary: "适用于已下载的画廊".tl,
              value: appdata.settings[78] == "1",
              onChanged: (b) {
                setState(() {
                  appdata.settings[78] = b ? "1" : "0";
                });
                appdata.updateSettings();
              },
            ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.request_page_rounded),
              title: "配置文件".tl,
              onClick: () => App.to(context, () => const EhProfileSelectPage()),
            ),
          ],
        ),
      ],
    );
  }
}

class EhProfileSelectPage extends StatefulWidget {
  const EhProfileSelectPage({super.key});

  @override
  State<EhProfileSelectPage> createState() => _EhProfileSelectPageState();
}

class _EhProfileSelectPageState extends State<EhProfileSelectPage> {
  bool loading = true;

  Map<String, String>? profiles;

  String? error;

  void loadData() async {
    var res = await EhNetwork().getProfiles();
    loading = false;
    if (res.error) {
      setState(() {
        error = res.errorMessageWithoutNull;
      });
    } else {
      setState(() {
        profiles = res.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      loadData();
    }
    return Scaffold(
      appBar: Appbar(
        title: const Text("Profile"),
      ),
      body: loading
          ? const Center(
              child: MiuixCircularProgressIndicator(),
            )
          : error != null
              ? Center(child: Text(error!))
              : profiles == null
                  ? const Center(child: Text("Unknown Error"))
                  : buildBody(),
    );
  }

  Widget buildBody(){
    profiles?[""] = "Do not modify";
    var keys = profiles?.keys.toList();
    if(keys != null){
      keys.sort();
    }
    return ListView.builder(
      itemCount: profiles!.length,
      itemBuilder: (context, index) {
        var key = keys!.elementAt(index);
        var value = profiles![key]!;
        return RadioListTile<String>(
          title: Text(value),
          value: key,
          groupValue: appdata.settings[75],
          onChanged: (value) async {
            setState(() {
              appdata.settings[75] = key;
            });
            appdata.updateSettings();
          },
        );
      },
    );
  }
}
