part of pica_settings;

void findUpdate(BuildContext context) {
  context.showMessage(message: "正在检查更新".tl);
  checkUpdate().then((b) {
    if (!context.mounted) return;
    if (b == null) {
      context.showMessage(message: "网络错误".tl);
    } else if (b) {
      getUpdatesInfo().then((s) {
        if (!context.mounted) return;
        if (s != null) {
          showMiuixDialog(
              context: context,
              title: "有可用更新".tl,
              summary: s,
              actionsBuilder: (context, close) => [
                    MiuixTextButton(onPressed: () => close(), "取消".tl),
                    MiuixTextButton(
                        onPressed: () {
                          getDownloadUrl().then((s) {
                            launchUrlString(s,
                                mode: LaunchMode.externalApplication);
                          });
                        },
                        "下载".tl)
                  ]);
        } else {
          context.showMessage(message: "网络错误".tl);
        }
      });
    } else {
      context.showMessage(message: "已是最新版本".tl);
    }
  });
}

class ProxyController extends StateController {
  bool value = appdata.settings[8] == "0";
  late var controller =
      TextEditingController(text: value ? "" : appdata.settings[8]);
}

void setProxy(BuildContext context) {
  showMiuixDialog(
      context: context,
      title: "设置代理".tl,
      contentBuilder: (dialogContext, close) {
        return StateBuilder(
            init: ProxyController(),
            builder: (controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MiuixSwitchPreference(
                    title: "使用系统代理".tl,
                    value: controller.value,
                    onChanged: (value) {
                      if (value == true) {
                        controller.controller.text = "";
                      }
                      controller.value = !controller.value;
                      controller.update();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                    child: MiuixTextField(
                      readOnly: controller.value,
                      controller: controller.controller,
                      singleLine: true,
                      useLabelAsPlaceholder: true,
                      label: controller.value
                          ? "使用系统代理时无法手动设置".tl
                          : "设置代理, 例如127.0.0.1:7890".tl,
                    ),
                  ),
                  if (!controller.value)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 0, 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                          ),
                          Text("  ${"留空表示禁用网络代理".tl}",
                              style: const TextStyle(fontSize: 13))
                        ],
                      ),
                    ),
                  MiuixButton(
                      colors: MiuixButtonDefaults.buttonColorsPrimary(dialogContext),
                      onPressed: () {
                        if (controller.value) {
                          appdata.settings[8] = "0";
                          appdata.writeData();
                          setNetworkProxy();
                          close();
                        } else {
                          appdata.settings[8] = controller.controller.text;
                          appdata.writeData();
                          setNetworkProxy();
                          close();
                        }
                      },
                      child: Text("确认".tl,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              );
            });
      });
}

void setDownloadFolder() async {
  if (DownloadManager().downloading.isNotEmpty) {
    showToast(message: "请在下载任务完成后进行操作".tl);
    return;
  }

  if (App.isAndroid) {
    var directories = await getExternalStorageDirectories();
    var paths = List<String>.generate(
        directories?.length ?? 0, (index) => directories?[index].path ?? "");
    var havePermission = await const MethodChannel("pica_comic/settings")
        .invokeMethod("files_check");
    showMiuixDialog(
        context: App.globalContext!,
        title: "设置下载目录".tl,
        contentBuilder: (context, close) => SetDownloadFolderDialog(
              paths: paths,
              haveManageFilesPermission: havePermission,
            ));
  } else {
    showMiuixDialog(
        context: App.globalContext!,
        title: "设置下载目录".tl,
        contentBuilder: (context, close) => const SetDownloadFolderDialog());
  }
}

class SetDownloadFolderDialog extends StatefulWidget {
  const SetDownloadFolderDialog(
      {this.paths, this.haveManageFilesPermission = false, Key? key})
      : super(key: key);
  final List<String>? paths;
  final bool haveManageFilesPermission;

  @override
  State<SetDownloadFolderDialog> createState() =>
      _SetDownloadFolderDialogState();
}

class _SetDownloadFolderDialogState extends State<SetDownloadFolderDialog> {
  final controller = TextEditingController();
  String current = appdata.settings[22];
  bool transform = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (App.isDesktop || widget.haveManageFilesPermission)
          SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: MiuixTextField(
                    controller: controller,
                    label: "路径".tl,
                    singleLine: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: MiuixCheckboxPreference(
                    value: transform,
                    onChanged: (b) => setState(() {
                      transform = b;
                    }),
                    title: "转移数据".tl,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: SizedBox(
                          child: Text("如需还原之前的下载, 将路径填写为下载数据的位置, 并取消勾选转移数据".tl),
                        ),
                      )
                    ],
                  ),
                ),
                Center(
                  child: MiuixButton(colors: MiuixButtonDefaults.buttonColorsPrimary(context), 
                    onPressed: () async {
                      if (controller.text == appdata.settings[22]) return;
                      var directory = Directory(controller.text);
                      if (directory.existsSync() || controller.text == "") {
                        var oldPath = appdata.settings[22];
                        appdata.settings[22] = controller.text;
                        if (transform) {
                          showToast(message: "正在复制文件".tl);
                          await Future.delayed(
                              const Duration(milliseconds: 200));
                        }
                        var res = await downloadManager
                            .updatePath(controller.text, transform: transform);
                        if (res == "ok") {
                          hideAllMessages();
                          if (context.mounted) {
                            context.pop();
                          }
                          showToast(message: "更新成功".tl);
                          appdata.updateSettings();
                        } else {
                          appdata.settings[22] = oldPath;
                          showToast(message: res);
                        }
                      } else {
                        showToast(message: "目录不存在".tl);
                      }
                    },
                    child: Text("提交".tl),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text("${"现在的路径为".tl}: ${DownloadManager().path}"),
                )
              ],
            ),
          )
        else
          SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MiuixRadioButtonPreference(
                    title: "App数据目录".tl,
                    selected: current == "",
                    onClick: () => setState(() {
                          current = "";
                        })),
                for (int i = 0; i < widget.paths!.length; i++)
                  MiuixRadioButtonPreference(
                      title: widget.paths![i],
                      selected: current == widget.paths![i],
                      onClick: () => setState(() {
                            current = widget.paths![i];
                          })),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: MiuixBasicComponent(
                    title: "允许储存权限".tl,
                    summary: "需要储存权限以选取任意目录".tl,
                    onClick: () {
                      const MethodChannel("pica_comic/settings")
                          .invokeMethod("files");
                      App.globalBack();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: MiuixCheckboxPreference(
                    value: transform,
                    onChanged: (b) => setState(() {
                      transform = b;
                    }),
                    title: "转移数据".tl,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Expanded(
                        child: SizedBox(
                          child: Text("如需还原之前的下载, 将路径填写为下载数据的位置, 并取消勾选转移数据".tl),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: Center(
                    child: MiuixButton(colors: MiuixButtonDefaults.buttonColorsPrimary(context), 
                      child: Text("确认".tl),
                      onPressed: () async {
                        if (appdata.settings[22] != current) {
                          var oldPath = appdata.settings[22];
                          appdata.settings[22] = current;
                          if (transform) {
                            showToast(message: "正在复制文件".tl);
                            await Future.delayed(
                                const Duration(milliseconds: 200));
                          }
                          var res = await downloadManager.updatePath(current,
                              transform: transform);
                          if (res == "ok") {
                            App.globalBack();
                            showToast(message: "更新成功".tl);
                            appdata.updateSettings();
                          } else {
                            appdata.settings[22] = oldPath;
                            showToast(message: res);
                          }
                        } else {
                          App.globalBack();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
}

void setExplorePages(BuildContext context) {
  showPopUpWidget(context, const SetExplorePages());
}

class SetExplorePages extends StatefulWidget {
  const SetExplorePages({Key? key}) : super(key: key);

  @override
  State<SetExplorePages> createState() => _SetExplorePagesState();
}

class _SetExplorePagesState extends State<SetExplorePages> {
  @override
  void dispose() {
    appdata.updateSettings();
    Future.microtask(() {
      MyApp.updater?.call();
    });
    super.dispose();
  }

  Widget buildItem(String i) {
    Widget removeButton = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: MiuixIconButton(onPressed: () {
            setState(() {
              var config = appdata.appSettings.explorePages;
              config.remove(i);
              appdata.appSettings.explorePages = config;
            });
          }, child: const Icon(Icons.delete)),
    );

    return Padding(
      key: ValueKey<String>(i),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: ShapeDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          shape: const MiuixSquircleBorder(cornerRadius: 14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                i.tl,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            removeButton,
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }

  Widget buildNotShowPageSelector(String i, BuildContext context) {
    return MiuixBasicComponent(
      key: Key(i),
      title: i.tl,
      onClick: () {
        App.back(context);
        setState(() {
          appdata.appSettings.explorePages = appdata.appSettings.explorePages
            ..add(i);
        });
      },
    );
  }

  var reorderWidgetKey = UniqueKey();
  var scrollController = ScrollController();
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var notShowPages = <String>[];
    var allPages = <String>[];
    for (var source in ComicSource.sources) {
      for (var page in source.explorePages) {
        allPages.add(page.title);
      }
    }
    for (var i in allPages) {
      if (!appdata.appSettings.explorePages.contains(i)) {
        notShowPages.add(i);
      }
    }

    var tiles =
        appdata.appSettings.explorePages.map((e) => buildItem(e)).toList();

    var view = ReorderableBuilder(
      key: reorderWidgetKey,
      scrollController: scrollController,
      longPressDelay: App.isDesktop
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 500),
      dragChildBoxDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainer,
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
              spreadRadius: 2)
        ],
      ),
      onReorder: (reorderFunc) {
        setState(() {
          appdata.appSettings.explorePages =
              List.from(reorderFunc(appdata.appSettings.explorePages));
        });
      },
      children: tiles,
      builder: (children) {
        return GridView(
          key: _key,
          controller: scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisExtent: 48,
          ),
          children: children,
        );
      },
    );
    return PopUpWidgetScaffold(
      title: "探索页面".tl,
      tailing: [
        if (notShowPages.isNotEmpty)
          MiuixIconButton(onPressed: () {
              showMiuixDialog(
                context: context,
                title: "添加".tl,
                contentBuilder: (context, close) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: notShowPages
                      .map((e) => buildNotShowPageSelector(e, context))
                      .toList(),
                ),
              );
            }, child: const Icon(Icons.add))
      ],
      body: view,
    );
  }
}

void clearUserData(BuildContext context) {
  showConfirmDialog(
    context,
    "警告".tl,
    "此操作无法撤销, 是否继续?".tl,
    () async {
      await clearAppdata();
      App.offAll(() => const WelcomePage());
      MyApp.updater?.call();
    },
  );
}

void exportDataSetting(BuildContext context) {
  void export(bool includeDownloads) async {
    var dialog = showLoadingDialog(context, allowCancel: false);
    var res = await runExportData(includeDownloads);
    if (context.mounted) {
      if (res) {
        dialog.close();
        showToast(message: "成功导出".tl);
      } else {
        dialog.close();
        showToast(message: "导出失败".tl);
      }
    }
  }

  showMiuixDialog(
      context: context,
      title: "导出用户数据".tl,
      summary: "将导出设置, 账号, 历史记录, 下载内容, 本地收藏等数据".tl,
      contentBuilder: (context, close) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MiuixButton(
                  colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                  onPressed: () {
                    close();
                    export(true);
                  },
                  child: Text("导出所有数据".tl)),
              const SizedBox(height: 12),
              MiuixTextButton(
                  onPressed: () {
                    close();
                    export(false);
                  },
                  "导出不含下载的数据".tl),
              const SizedBox(height: 12),
              MiuixTextButton(onPressed: () => close(), "取消".tl),
            ],
          ));
}

void importDataSetting(BuildContext context) {
  showMiuixDialog(
      context: context,
      title: "导入用户数据".tl,
      summary: "${"将导入设置, 账号, 历史记录, 下载内容, 本地收藏等数据, 现在的所有数据将会被覆盖".tl}"
          "\n${"如果导入的数据中包含下载数据, 则当前的下载数据也将被覆盖".tl}",
      actionsBuilder: (context, close) => [
            MiuixTextButton(onPressed: () => close(), "取消".tl),
            MiuixButton(
                colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                onPressed: () {
                  close();
                  var dialog = showLoadingDialog(App.globalContext!, allowCancel: false);
                  importData().then((v) {
                    dialog.close();
                    if (v) {
                      showToast(message: "成功导入".tl);
                    } else {
                      showToast(message: "导入失败".tl);
                    }
                  });
                },
                child: Text("继续".tl)),
          ]);
}

void syncDataSettings(BuildContext context) {
  var configs = ["", "", "", ""];
  if (appdata.settings[45] != "") {
    configs = appdata.settings[45].split(';');
  }
  String url = configs[0];
  String username = configs[1];
  String pwd = configs[2];
  String path = configs[3];
  int value = 0;
  showMiuixDialog(
    context: context,
    title: "Webdav",
    contentBuilder: (context, close) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MiuixTextField(
              onChanged: (s) => url = s,
              controller: TextEditingController(text: url),
              label: "URL",
              singleLine: true),
          const SizedBox(
            height: 8,
          ),
          MiuixTextField(
              onChanged: (s) => username = s,
              controller: TextEditingController(text: username),
              label: "用户名".tl,
              singleLine: true),
          const SizedBox(
            height: 8,
          ),
          MiuixTextField(
              onChanged: (s) => pwd = s,
              controller: TextEditingController(text: pwd),
              obscureText: true,
              label: "密码".tl,
              singleLine: true),
          const SizedBox(
            height: 8,
          ),
          MiuixTextField(
              onChanged: (s) => path = s,
              controller: TextEditingController(text: path),
              label: "储存路径".tl,
              singleLine: true),
          const SizedBox(
            height: 8,
          ),
          StatefulBuilder(builder: (context, stateSetter) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MiuixSmallTitle("立即执行:".tl),
                MiuixRadioButtonPreference(
                    title: "上传数据".tl,
                    selected: value == 0,
                    onClick: () => stateSetter(() => value = 0)),
                MiuixRadioButtonPreference(
                    title: "下载数据".tl,
                    selected: value == 1,
                    onClick: () => stateSetter(() => value = 1)),
              ],
            );
          }),
          const SizedBox(
            height: 8,
          ),
          MiuixButton(
              colors: MiuixButtonDefaults.buttonColorsPrimary(context),
              child: Text("提交".tl),
              onPressed: () async {
                if (url.isEmpty) {
                  appdata.settings[45] = "$url;$username;$pwd;$path";
                  appdata.updateSettings();
                  close();
                  return;
                }
                var dialog = showLoadingDialog(context,
                    allowCancel: false, barrierDismissible: false);
                var res = value == 0
                    ? await Webdav.uploadData("$url;$username;$pwd;$path")
                    : await Webdav.downloadData("$url;$username;$pwd;$path");
                if (!res) {
                  dialog.close();
                  showToast(message: "Failed to sync data");
                } else {
                  appdata.settings[45] = "$url;$username;$pwd;$path";
                  appdata.updateSettings();
                  dialog.close();
                  close();
                }
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                ),
                const SizedBox(
                  width: 4,
                ),
                if (configs.length == 4)
                  Text("将URL留空以禁用同步".tl)
                else
                  Text("已禁用".tl)
              ],
            ),
          )
        ],
      ),
  );
}

void setCacheLimit() {
  int size = appdata.appSettings.cacheLimit;
  const minSize = 16;
  bool isValid = true;
  final FocusNode focusNode = FocusNode();
  final TextEditingController controller = TextEditingController(text: size.toString());
  showMiuixDialog(
    context: App.globalContext!,
    title: "设置缓存限制".tl,
    contentBuilder: (context, close) => StatefulBuilder(
      builder: (context, setState) {
        focusNode.requestFocus();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MiuixTextField(
              focusNode: focusNode,
              controller: controller,
              keyboardType: TextInputType.number,
              label: "MB",
              trailingIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text("MB"),
              ),
              onChanged: (s) {
                size = int.tryParse(s) ?? 500;
                setState(() {
                  isValid = size < minSize ? false : true;
                });
              },
            ),
            if (!isValid)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  "${"不能小于".tl} $minSize MB",
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),
            MiuixButton(
              colors: MiuixButtonDefaults.buttonColorsPrimary(context),
              child: Text("确认".tl),
              onPressed: () {
                if (size < minSize) {
                  setState(() {
                    isValid = false;
                  });
                  return;
                } else {
                  appdata.appSettings.cacheLimit = size;
                  appdata.writeData();
                  CacheManager().setLimitSize(size);
                  close();
                }
              },
            ),
          ],
        );
      },
    ),
  );
}
