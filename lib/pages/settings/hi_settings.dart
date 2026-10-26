part of pica_settings;

class HitomiSettings extends StatefulWidget {
  const HitomiSettings(this.popUp, {super.key});

  final bool popUp;

  @override
  State<HitomiSettings> createState() => _HitomiSettingsState();
}

class _HitomiSettingsState extends State<HitomiSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MiuixSmallTitle("Hitomi".tl),
        MiuixSettingsCard(
          children: [
            MiuixArrowPreference(
              startAction: const Icon(Icons.dns),
              title: "CDN ${"域名".tl}",
              summary: appdata.settings[87],
              onClick: () => changeDomain(context),
            ),
          ],
        ),
      ],
    );
  }

  void changeDomain(BuildContext context){
    final FocusNode focusNode = FocusNode();
    var controller = TextEditingController(
      text : appdata.settings[87]
    );

    void onFinished() {
      var text = controller.text;
      App.globalBack();
      if(!text.isURL){
        showToast(message: "Invalid Domain");
      }else {
        appdata.settings[87] = text;
        appdata.updateSettings();
        setState(() {});
      }
    }

    showDialog(context: context, builder: (context){
      focusNode.requestFocus();
      return SimpleDialog(
        shape: const MiuixSquircleBorder(cornerRadius: 28),
        title: Text("更改域名".tl,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            width: 400,
            child: TextField(
              focusNode: focusNode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                label: Text("域名".tl),
              ),
              controller: controller,
              onEditingComplete: onFinished,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                onPressed: onFinished,
                child: Text("完成".tl,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 16,),
            ],
          )
        ],
      );
    });
  }
}