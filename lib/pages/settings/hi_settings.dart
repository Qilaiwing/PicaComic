part of pica_settings;

class HitomiSettings extends StatefulWidget {
  const HitomiSettings(this.popUp, {this.embedded = false, super.key});

  final bool popUp;
  final bool embedded;

  @override
  State<HitomiSettings> createState() => _HitomiSettingsState();
}

class _HitomiSettingsState extends State<HitomiSettings> {
  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
            MiuixArrowPreference(
              startAction: _mi(MiuixIcons.os4.link),
              title: "CDN ${"域名".tl}",
              summary: appdata.settings[87],
              onClick: () => changeDomain(context),
            ),
];
    if (widget.embedded) {
      return Column(mainAxisSize: MainAxisSize.min, children: tiles);
    }
    return Column(
      children: [
        MiuixSmallTitle("Hitomi".tl),
        MiuixSettingsCard(children: tiles),
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

    showMiuixDialog(
      context: context,
      title: "更改域名".tl,
      contentBuilder: (context, close) {
        focusNode.requestFocus();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MiuixTextField(
              focusNode: focusNode,
              label: "域名".tl,
              singleLine: true,
              controller: controller,
              onSubmitted: (_) => onFinished(),
            ),
            const SizedBox(height: 16),
            MiuixButton(
              colors: MiuixButtonDefaults.buttonColorsPrimary(context),
              onPressed: onFinished,
              child: Text("完成".tl,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      });
  }
}