part of pica_settings;

class ComicSourceSettings extends StatefulWidget {
  const ComicSourceSettings({super.key});

  @override
  State<ComicSourceSettings> createState() => _ComicSourceSettingsState();

  // static void checkCustomComicSourceUpdate([bool showLoading = false]) async {
  //   if (ComicSource.sources.isEmpty) {
  //     return;
  //   }
  //   var controller = showLoading ? showLoadingDialog(App.globalContext!) : null;
  //   var dio = logDio();
  //   var res = await dio.get<String>(
  //       "https://raw.githubusercontent.com/user/repo/master/index.json");
  //   if (res.statusCode != 200) {
  //     showToast(message: "网络错误".tl);
  //     return;
  //   }
  //   var list = jsonDecode(res.data!) as List;
  //   var versions = <String, String>{};
  //   for (var source in list) {
  //     versions[source['key']] = source['version'];
  //   }
  //   var shouldUpdate = <String>[];
  //   for (var source in ComicSource.sources) {
  //     if (versions.containsKey(source.key) &&
  //         versions[source.key] != source.version) {
  //       shouldUpdate.add(source.key);
  //     }
  //   }
  //   controller?.close();
  //   if (shouldUpdate.isEmpty) {
  //     return;
  //   }
  //   var msg = "";
  //   for (var key in shouldUpdate) {
  //     msg += "${ComicSource.find(key)?.name}: v${versions[key]}\n";
  //   }
  //   msg = msg.trim();
  //   showConfirmDialog(App.globalContext!, "有可用更新".tl, msg, () {
  //     for (var key in shouldUpdate) {
  //       var source = ComicSource.find(key);
  //       _ComicSourceSettingsState.update(source!);
  //     }
  //   });
  // }
}

extension _WidgetExt on Widget {
  Widget withDivider() {
    return Column(
      children: [
        this,
        const MiuixHorizontalDivider(),
      ],
    );
  }
}

class _ComicSourceSettingsState extends State<ComicSourceSettings> {
  var url = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildCard(context),
        const _BuiltInSources(),
        if (appdata.appSettings.isComicSourceEnabled("picacg"))
          const PicacgSettings(false),
        if (appdata.appSettings.isComicSourceEnabled("ehentai"))
          const EhSettings(false),
        if (appdata.appSettings.isComicSourceEnabled("nhentai"))
          const NhSettings(false),
        if (appdata.appSettings.isComicSourceEnabled("jm"))
          const JmSettings(false),
        if (appdata.appSettings.isComicSourceEnabled("hitomi"))
          const HitomiSettings(false),
        if (appdata.appSettings.isComicSourceEnabled("htmanga"))
          const HtSettings(false),
        for (var source in ComicSource.sources.where((e) => !e.isBuiltIn))
          buildCustom(context, source),
        Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16))
      ],
    );
  }

  // Widget buildCustomSettings() {
  //   return Column(
  //     children: [
  //       ListTile(
  //         title: Text("自定义漫画源".tl),
  //       ),
  //       ListTile(
  //         leading: const Icon(Icons.update_outlined),
  //         title: Text("检查更新".tl),
  //         onTap: () => ComicSourceSettings.checkCustomComicSourceUpdate(true),
  //         trailing: const Icon(Icons.arrow_right),
  //       ),
  //       SwitchSetting(
  //         title: "启动时检查更新".tl,
  //         icon: const Icon(Icons.security_update),
  //         settingsIndex: 80,
  //       )
  //     ],
  //   );
  // }

  Widget buildCustom(BuildContext context, ComicSource source) {
    return Column(
      children: [
        MiuixSmallTitle(source.name),
        MiuixSettingsCard(
          children: [
            MiuixArrowPreference(
              startAction: const Icon(Icons.info_outline),
              title: "版本".tl,
              summary: source.version,
              onClick: () {},
            ),
            if (App.isDesktop)
              MiuixArrowPreference(
                startAction: const Icon(Icons.edit_note),
                title: "编辑代码".tl,
                onClick: () => edit(source),
              ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.update),
              title: "更新漫画源".tl,
              onClick: () => update(source),
            ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.delete, color: Colors.red),
              title: "删除漫画源".tl,
              onClick: () => delete(source),
            ),
          ],
        ),
      ],
    );
  }

  void delete(ComicSource source) {
    showConfirmDialog(App.globalContext!, "删除".tl, "要删除此漫画源吗?".tl, () {
      var file = File(source.filePath);
      file.delete();
      ComicSource.sources.remove(source);
      _validatePages();
      MyApp.updater?.call();
    });
  }

  void edit(ComicSource source) async {
    try {
      await Process.run("code", [source.filePath], runInShell: true);
      showConfirmDialog(
        App.globalContext!,
        "Reload Configs",
        "Reload configurations?",
        () async {
          await ComicSource.reload();
          MyApp.updater?.call();
        },
      );
    } catch (e) {
      showToast(message: "Failed to launch vscode");
    }
  }

  static void update(ComicSource source) async {
    ComicSource.sources.remove(source);
    if (!source.url.isURL) {
      showToast(message: "Invalid url config");
    }
    bool cancel = false;
    var controller = showLoadingDialog(App.globalContext!,
        onCancel: () => cancel = true, barrierDismissible: false);
    try {
      var res = await logDio().get<String>(source.url,
          options: Options(responseType: ResponseType.plain));
      if (cancel) return;
      controller.close();
      await ComicSourceParser().parse(res.data!, source.filePath);
      await File(source.filePath).writeAsString(res.data!);
    } catch (e) {
      if (cancel) return;
      showToast(message: e.toString());
    }
    await ComicSource.reload();
    MyApp.updater?.call();
  }

  Widget buildCard(BuildContext context) {
    return MiuixSettingsCard(
      children: [
        MiuixBasicComponent(
          content: [
            Row(
            children: [
              Text("添加漫画源".tl),
              const SizedBox(
                width: 2,
              ),
              MiuixPressable(
 onPressed: () => showDialogMessage(
                    context,
                    "警告".tl,
                    "${"此功能已不再受支持".tl}\n${"请勿反馈相关问题".tl}"
                ),
 feedbackType: MiuixPressFeedbackType.sink, borderRadius: const BorderRadius.all(Radius.circular(18)),
 child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 18,
                ),
)
            ]
          ),
          ],
          startAction: const Icon(Icons.dashboard_customize),
        ),
        MiuixTextField(
                label: "URL",
                useLabelAsPlaceholder: true,
                singleLine: true,
                trailingIcon: MiuixIconButton(onPressed: () => handleAddSource(url), child: const Icon(Icons.check)),
                onChanged: (value) {
                  url = value;
                },
                onSubmitted: handleAddSource)
            .paddingHorizontal(16)
            .paddingBottom(16),
        Row(
          children: [
            const Spacer(),
            MiuixTextButton(onPressed: chooseFile, "选择文件".tl)
                .paddingLeft(8),
            const Spacer(),
            MiuixTextButton(
                onPressed: () {
                  showPopUpWidget(
                      context, _ComicSourceList(handleAddSource));
                },
                "浏览列表".tl),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void chooseFile() async {
    const XTypeGroup typeGroup = XTypeGroup(
      extensions: <String>['js'],
    );
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return;
    try {
      var fileName = file.name;
      // file.readAsString 会导致中文乱码
      var bytes = await file.readAsBytes();
      var content = utf8.decode(bytes);
      await addSource(content, fileName);
    } catch (e) {
      showToast(message: e.toString());
    }
  }

  // void help() {
  //   launchUrlString(
  //       "https://github.com/user/repo/blob/master/help.md");
  // }

  Future<void> handleAddSource(String url) async {
    if (url.isEmpty) {
      return;
    }
    var splits = url.split("/");
    splits.removeWhere((element) => element == "");
    var fileName = splits.last;
    bool cancel = false;
    var controller = showLoadingDialog(App.globalContext!,
        onCancel: () => cancel = true, barrierDismissible: false);
    try {
      var res = await logDio()
          .get<String>(url, options: Options(responseType: ResponseType.plain));
      if (cancel) return;
      controller.close();
      await addSource(res.data!, fileName);
    } catch (e) {
      if (cancel) return;
      showToast(message: e.toString());
    }
  }

  Future<void> addSource(String js, String fileName) async {
    var comicSource = await ComicSourceParser().createAndParse(js, fileName);
    ComicSource.sources.add(comicSource);
    _addAllPagesWithComicSource(comicSource);
    appdata.updateSettings();
    MyApp.updater?.call();
  }
}

class _ComicSourceList extends StatefulWidget {
  const _ComicSourceList(this.onAdd);

  final Future<void> Function(String) onAdd;

  @override
  State<_ComicSourceList> createState() => _ComicSourceListState();
}

class _ComicSourceListState extends State<_ComicSourceList> {
  bool loading = true;
  List? json;

  void load() async {
    var dio = logDio();
    var res = await dio.get<String>(
        "https://raw.githubusercontent.com/wgh136/pica_configs/master/index.json");
    if (res.statusCode != 200) {
      showToast(message: "网络错误".tl);
      return;
    }
    setState(() {
      json = jsonDecode(res.data!);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(
 topBar: MiuixSmallTopAppBar(
 title: "漫画源".tl,
 navigationIcon: Navigator.of(context).canPop() ? MiuixIconButton(onPressed: () => Navigator.of(context).maybePop(), child: const Icon(Icons.arrow_back)) : null,
 actions: const [
          MiuixIconButton(onPressed: App.globalBack, child: Icon(Icons.close)),
        ],
),
 content: (padding) => Padding(
 padding: padding,
 child: buildBody(),
 ),
);
  }

  Widget buildBody() {
    if (loading) {
      load();
      return const Center(child: MiuixCircularProgressIndicator());
    } else {
      var currentKey = ComicSource.sources.map((e) => e.key).toList();
      return ListView.builder(
        itemCount: json!.length,
        itemBuilder: (context, index) {
          var key = json![index]["key"];
          var action = currentKey.contains(key)
              ? const Icon(Icons.check)
              : MiuixTooltipBox(
 tooltip: (_, scope) => MiuixPlainTooltip(scope: scope, child: Text("Add")),
 child: MiuixIconButton(onPressed: () async {
                      await widget.onAdd(
                          "https://raw.githubusercontent.com/wgh136/pica_configs/master/${json![index]["fileName"]}");
                      setState(() {});
                    }, child: const Icon(Icons.add)),
);

          return MiuixBasicComponent(
                   title: json![index]["name"],
                   summary: json![index]["version"],
                   endActions: [action],
                 );
        },
      );
    }
  }
}

class _BuiltInSources extends StatefulWidget {
  const _BuiltInSources();

  @override
  State<_BuiltInSources> createState() => _BuiltInSourcesState();
}

class _BuiltInSourcesState extends State<_BuiltInSources> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MiuixSmallTitle("内置漫画源".tl),
        MiuixSettingsCard(
          children: [
            for (int index = 0; index < builtInSources.length; index++)
              buildTile(index),
          ],
        ),
      ],
    );
  }

  bool isLoading = false;

  Widget buildTile(int index) {
    var key = builtInSources[index];
    return MiuixSwitchPreference(
      title: ComicSource.builtIn.firstWhere((e) => e.key == key).name.tl,
      value: appdata.appSettings.isComicSourceEnabled(key),
      onChanged: (v) async {
        if (isLoading) return;
        isLoading = true;
        appdata.appSettings.setComicSourceEnabled(key, v);
        await appdata.updateSettings();
        if (!v) {
          ComicSource.sources.removeWhere((e) => e.key == key);
          _validatePages();
        } else {
          var source = ComicSource.builtIn.firstWhere((e) => e.key == key);
          ComicSource.sources.add(source);
          source.loadData();
          _addAllPagesWithComicSource(source);
        }
        isLoading = false;
        if (mounted) {
          setState(() {});
          context
              .findAncestorStateOfType<_ComicSourceSettingsState>()
              ?.setState(() {});
        }
      },
    );
  }
}

void _validatePages() {
  var explorePages = appdata.appSettings.explorePages;
  var categoryPages = appdata.appSettings.categoryPages;
  var networkFavorites = appdata.appSettings.networkFavorites;

  var totalExplorePages = ComicSource.sources
      .map((e) => e.explorePages.map((e) => e.title))
      .expand((element) => element)
      .toList();
  var totalCategoryPages = ComicSource.sources
      .map((e) => e.categoryData?.key)
      .where((element) => element != null)
      .map((e) => e!)
      .toList();
  var totalNetworkFavorites = ComicSource.sources
      .map((e) => e.favoriteData?.key)
      .where((element) => element != null)
      .map((e) => e!)
      .toList();

  for (var page in List.from(explorePages)) {
    if (!totalExplorePages.contains(page)) {
      explorePages.remove(page);
    }
  }
  for (var page in List.from(categoryPages)) {
    if (!totalCategoryPages.contains(page)) {
      categoryPages.remove(page);
    }
  }
  for (var page in List.from(networkFavorites)) {
    if (!totalNetworkFavorites.contains(page)) {
      networkFavorites.remove(page);
    }
  }

  appdata.appSettings.explorePages = explorePages;
  appdata.appSettings.categoryPages = categoryPages;
  appdata.appSettings.networkFavorites = networkFavorites;

  appdata.updateSettings();
}

void _addAllPagesWithComicSource(ComicSource source) {
  var explorePages = appdata.appSettings.explorePages;
  var categoryPages = appdata.appSettings.categoryPages;
  var networkFavorites = appdata.appSettings.networkFavorites;

  if (source.explorePages.isNotEmpty) {
    for (var page in source.explorePages) {
      if (!explorePages.contains(page.title)) {
        explorePages.add(page.title);
      }
    }
  }
  if (source.categoryData != null &&
      !categoryPages.contains(source.categoryData!.key)) {
    categoryPages.add(source.categoryData!.key);
  }
  if (source.favoriteData != null &&
      !networkFavorites.contains(source.favoriteData!.key)) {
    networkFavorites.add(source.favoriteData!.key);
  }

  appdata.appSettings.explorePages = explorePages.toSet().toList();
  appdata.appSettings.categoryPages = categoryPages.toSet().toList();
  appdata.appSettings.networkFavorites = networkFavorites.toSet().toList();

  appdata.updateSettings();
}