part of pica_settings;

class NhSettings extends StatefulWidget {
  const NhSettings(this.popUp, {this.embedded = false, super.key});

  final bool popUp;
  final bool embedded;

  @override
  State<NhSettings> createState() => _NhSettingsState();
}

class _NhSettingsState extends State<NhSettings> {

  String baseUrl = "https://nhentai.net";

  void deleteAllCookie() async {
    final cookieJar = SingleInstanceCookieJar.instance!;
    var cookies = cookieJar.loadForRequest(Uri.parse(baseUrl));
    if (cookies.isEmpty) {
      showToast(message: "cookie 为空".tl);
      return;
    } else {
      var title = "${"确认删除".tl}?";
      var msg = "${"删除全部".tl}(${cookies.length}) nhentai cookie\n${"删除后需重新登录".tl}\n";
      showConfirmDialog(App.globalContext!, title, msg, () {
        NhentaiNetwork().logged = false;
        cookieJar.deleteUri(Uri.parse(baseUrl));
        var source = ComicSource.find('nhentai')!;
        source.data["account"] = null;
        source.saveData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
            MiuixArrowPreference(
              startAction: _mi(MiuixIcons.os4.delete),
              title: "${"删除".tl} cookie",
              onClick: () => deleteAllCookie(),
            ),
];
    if (widget.embedded) {
      return Column(mainAxisSize: MainAxisSize.min, children: tiles);
    }
    return Column(
      children: [
        MiuixSmallTitle("nhentai".tl),
        MiuixSettingsCard(children: tiles),
      ],
    );
  }
}