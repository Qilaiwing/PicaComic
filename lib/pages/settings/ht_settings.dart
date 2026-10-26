part of pica_settings;

class HtSettings extends StatefulWidget {
  const HtSettings(this.popUp, {super.key});

  final bool popUp;

  @override
  State<HtSettings> createState() => _HtSettingsState();
}

class _HtSettingsState extends State<HtSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MiuixSmallTitle("绅士漫画".tl),
        MiuixSettingsCard(
          children: [
            MiuixArrowPreference(
              startAction: const Icon(Icons.dns),
              title: "域名".tl,
              summary: appdata.settings[31].replaceFirst("https://", ""),
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
      text : appdata.settings[31].replaceFirst("https://", "")
    );

    void onFinished() {
      var text = controller.text;
      if(!text.contains("https://")){
        text = "https://$text";
      }
      App.globalBack();
      if(!text.isURL){
        showToast(message: "Invalid URL");
      }else {
        appdata.settings[31] = text;
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