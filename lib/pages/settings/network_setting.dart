part of pica_settings;

class NetworkSettings extends StatefulWidget {
  const NetworkSettings({super.key});

  @override
  State<NetworkSettings> createState() => _NetworkSettingsState();
}

class _NetworkSettingsState extends State<NetworkSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiuixSmallTitle("HTTP 代理".tl),
        MiuixSettingsCard(
          children: [
            MiuixArrowPreference(
              startAction: const Icon(Icons.network_ping),
              title: "设置代理".tl,
              onClick: () => setProxy(context),
            ),
          ],
        ),
        MiuixSmallTitle("Hosts 代理".tl),
        MiuixSettingsCard(
          children: [
            MiuixSwitchPreference(
              startAction: const Icon(Icons.dns),
              title: "启用".tl,
              value: appdata.settings[58] == "1",
              onChanged: (value) {
                setState(() {
                  appdata.settings[58] = value ? "1" : "0";
                });
                appdata.updateSettings();
                if (value) {
                  HttpProxyServer.reload();
                }
              },
            ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.rule),
              title: "规则".tl,
              onClick: () {
                App.globalTo(() => const EditRuleView());
              },
            ),
          ],
        ),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16))
      ],
    );
  }
}

class EditRuleView extends StatefulWidget {
  const EditRuleView({super.key});

  @override
  State<EditRuleView> createState() => _EditRuleViewState();
}

class _EditRuleViewState extends State<EditRuleView> {
  final file = File("${App.dataPath}/rule.json");

  late TextEditingController controller;

  @override
  void initState() {
    HttpProxyServer.createConfigFile();
    controller = TextEditingController(text: file.readAsStringSync());
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    file.writeAsStringSync(controller.text, mode: FileMode.writeOnly);
  }

  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(
 topBar: MiuixSmallTopAppBar(
 title: "rule.json",
 navigationIcon: Navigator.of(context).canPop() ? MiuixIconButton(onPressed: () => Navigator.of(context).maybePop(), child: const Icon(Icons.arrow_back)) : null,
),
 content: (padding) => Padding(
 padding: padding,
 child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.of(context).padding.bottom),
          child: MiuixTextField(
            keyboardType: TextInputType.multiline,
            maxLines: null,
            singleLine: false,
            controller: controller,
          ),
        )
      ),
 ),
);
  }
}

