import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app_page_route.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/tools/background_service.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'category_page.dart';
import 'explore_page.dart';
import 'favorites/main_favorites_page.dart';
import 'pre_search_page.dart';
import 'settings/settings_page.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/update.dart';
import 'me_page.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

bool _haveClipboardDialog = false;

void checkClipboard() async {
  if (appdata.settings[61] == "0") {
    return;
  }
  var data = await Clipboard.getData(Clipboard.kTextPlain);
  if (data?.text != null && canHandle(data!.text!)) {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_haveClipboardDialog) {
      return;
    }
    _haveClipboardDialog = true;
    final open = await showMiuixDialog<bool>(
      context: App.globalContext!,
      title: "发现剪切板中的链接".tl,
      summary: data.text!,
      actionsBuilder: (dialogContext, close) => [
        MiuixTextButton("打开".tl, onPressed: () {
          close(true);
        }),
      ],
    );
    if (open == true) {
      handleAppLinks(Uri.parse(data.text!));
    }
    _haveClipboardDialog = false;
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  static MainPageState of(BuildContext context) {
    return context.findAncestorStateOfType<MainPageState>()!;
  }

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  GlobalKey<NavigatorState>? _navigatorKey;

  late final NaviObserver _observer;
  DateTime? _lastBackTime;

  void _handleRootBack(int index) {
    // 1. 如果内部 Navigator 还能 pop，优先 pop 内部子页面
    if (_navigatorKey?.currentState?.canPop() ?? false) {
      _navigatorKey!.currentState!.pop();
      return;
    }
    // 2. 如果是收藏页（index == 1）：
    if (index == 1) {
      final favController =
          StateController.findOrNull<FavoritesPageController>();
      if (favController != null) {
        if (favController.selectedComics.isNotEmpty) {
          favController.selectedComics.clear();
          favController.update();
          return;
        }
        if (!favController.selectingFolder) {
          favController.selectingFolder = true;
          favController.update();
          appdata.implicitData[0] = "1;;";
          appdata.writeImplicitData();
          return;
        }
      }
    }
    // 3. 已经在根 Tab 且无任何可回退内容：双击退出保护
    final now = DateTime.now();
    if (_lastBackTime == null ||
        now.difference(_lastBackTime!) > const Duration(seconds: 2)) {
      _lastBackTime = now;
      showToast(message: "再按一次退出应用".tl);
      return;
    }
    SystemNavigator.pop();
  }

  void to(Widget Function() widget, {bool preventDuplicate = false}) async {
    if (preventDuplicate) {
      var page = widget();
      if ("/${page.runtimeType}" == _observer.routes.last.toString()) return;
    }
    App.to(_navigatorKey!.currentContext!, widget);
  }

  void back() {
    _navigatorKey!.currentContext!.pop();
  }

  List<Widget> get _pages => [
        const MePage(),
        FavoritesPage(),
        ExplorePage(
          key: Key(appdata.appSettings.explorePages.length.toString()),
        ),
        const AllCategoryPage(),
      ];

  void _login() {
    network.updateProfile().then((res) {
      if (res.error) {
        showToast(message: res.errorMessageWithoutNull);
      } else {
        //检查是否打卡
        if (network.user?.isPunched == false && appdata.settings[6] == "1") {
          if (App.isMobile) {
            runBackgroundService();
          } else {
            network.user?.isPunched = true;
            network.punchIn().then((b) {
              if (b) {
                showToast(message: "打卡成功".tl);
                network.user?.exp += 10;
              }
            });
          }
        }
      }
    });
  }

  void _checkUpdates() async {
    var s = await SharedPreferences.getInstance();
    var lastCheck = s.getInt("lastCheckUpdate");
    if (lastCheck != null) {
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastCheck)).inDays < 1) {
        return;
      }
    }
    if (appdata.settings[2] != "1") {
      return;
    }
    var res = await checkUpdate();
    s.setInt("lastCheckUpdate", DateTime.now().millisecondsSinceEpoch);
    if (res != true) return;
    var info = await getUpdatesInfo();
    if (info == null) return;
    showMiuixDialog(context: App.globalContext!, title: "有可用更新".tl, summary: info, actionsBuilder: (dialogContext, close) => [
              MiuixTextButton("关闭更新检查", onPressed: () {
                    close();
                    appdata.settings[2] = "0";
                    appdata.writeData();
                  }),
              MiuixTextButton("取消".tl, onPressed: () => close()),
              MiuixTextButton("下载".tl, onPressed: () {
                    getDownloadUrl().then((s) {
                      launchUrlString(s, mode: LaunchMode.externalApplication);
                    });
                  })
            ]);

    // if (appdata.settings[80] == "1") {
    //   ComicSourceSettings.checkCustomComicSourceUpdate();
    // }
  }

  void _checkDownload() {
    if (downloadManager.downloading.isNotEmpty) {
      Future.delayed(const Duration(microseconds: 500), () {
        if (mounted) {
          showMiuixDialog(context: context, title: "下载管理器".tl, summary: "继续未完成的下载?".tl, actionsBuilder: (dialogContext, close) => [
                  MiuixTextButton("否".tl, onPressed: () => close()),
                  MiuixTextButton("是".tl, onPressed: () {
                        downloadManager.start();
                        close();
                      })
                ]);
        }
      });
    }
  }

  @override
  void initState() {
    _navigatorKey = GlobalKey();
    App.mainNavigatorKey = _navigatorKey;
    _login();
    notifications.requestPermission();
    notifications.cancelAll();
    _checkUpdates();
    _checkDownload();

    if (appdata.firstUse[3] == "0") {
      appdata.firstUse[3] = "1";
      appdata.writeData();
    }

    Future.delayed(const Duration(milliseconds: 300), () => Webdav.syncData())
        .then((v) => checkClipboard());
    _observer = NaviObserver();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NaviPane(
      initialPage: int.parse(appdata.settings[23]),
      observer: _observer,
      paneItems: [
        PaneItemEntry(
            label: '我'.tl,
            title: 'Pica Comic',
            icon: Icons.person_outline,
            activeIcon: Icons.person),
        PaneItemEntry(
            label: '收藏'.tl,
            icon: Icons.local_activity_outlined,
            activeIcon: Icons.local_activity),
        PaneItemEntry(
            label: '探索'.tl,
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore),
        PaneItemEntry(
            label: '分类'.tl,
            icon: Icons.account_tree_outlined,
            activeIcon: Icons.account_tree),
      ],
      paneActions: [
        PaneActionEntry(
            icon: Icons.search,
            label: "搜索".tl,
            onTap: () => to(() => PreSearchPage(), preventDuplicate: true)),
        PaneActionEntry(
            icon: Icons.settings,
            label: "设置".tl,
            onTap: () => SettingsPage.open()),
      ],
      pageBuilder: (index) {
        return Navigator(
          observers: [_observer],
          key: _navigatorKey,
          onGenerateRoute: (settings) => AppPageRoute(
            preventRebuild: false,
            isRootRoute: true,
            builder: (context) {
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  _handleRootBack(index);
                },
                child: NaviPaddingWidget(child: _pages[index]),
              );
            },
          ),
        );
      },
      onPageChange: (index) {
        _navigatorKey!.currentState?.pushAndRemoveUntil(
            AppPageRoute(
                preventRebuild: false,
                isRootRoute: true,
                builder: (context) {
                  return PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) {
                      if (didPop) return;
                      _handleRootBack(index);
                    },
                    child: NaviPaddingWidget(child: _pages[index]),
                  );
                }),
            (route) => false);
      },
    );
  }
}
