library pica_settings;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/built_in/picacg.dart';
import 'package:pica_comic/comic_source/built_in/jm.dart';
import 'package:pica_comic/foundation/cache_manager.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/main.dart';
import 'package:pica_comic/network/app_dio.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/pages/logs_page.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../comic_source/comic_source.dart';
import '../../foundation/app.dart';
import '../../foundation/local_favorites.dart';
import '../../network/cookie_jar.dart';
import '../../network/download.dart';
import '../../network/eh_network/eh_main_network.dart';
import '../../network/http_client.dart';
import '../../network/http_proxy.dart';
import '../../network/jm_network/jm_network.dart';
import '../../network/nhentai_network/nhentai_main_network.dart';
import '../../network/update.dart';
import '../../network/webdav.dart';
import '../../tools/background_service.dart';
import '../../tools/debug.dart';
import '../welcome_page.dart';
import 'package:pica_comic/tools/translations.dart';

part "reading_settings.dart";
part "picacg_settings.dart";
part "network_setting.dart";
part "multi_pages_filter.dart";
part "local_favorite_settings.dart";
part "jm_settings.dart";
part "hi_settings.dart";
part "ht_settings.dart";
part "explore_settings.dart";
part "eh_settings.dart";
part "nh_settings.dart";
part "comic_source_settings.dart";
part "blocking_keyword_page.dart";
part "app_settings.dart";
part 'components.dart';

class SettingsPage extends StatefulWidget {
  static void open([int initialPage = -1]) {
    App.globalTo(() => SettingsPage(initialPage: initialPage));
  }

  const SettingsPage({this.initialPage = -1, super.key});

  final int initialPage;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> implements PopEntry{
  int currentPage = -1;

  ColorScheme get colors => Theme.of(context).colorScheme;

  bool get enableTwoViews => !UiMode.m1(context);

  final categories = <String>["浏览", "漫画源", "阅读", "外观", "本地收藏", "APP", "网络", "关于"];

  final icons = <IconData>[
    Icons.explore,
    Icons.source,
    Icons.book,
    Icons.color_lens,
    Icons.collections_bookmark_rounded,
    Icons.apps,
    Icons.public,
    Icons.info
  ];

  double offset = 0;

  late final MiuixExitUntilCollapsedScrollBehavior _leftBehavior;
  late final MiuixExitUntilCollapsedScrollBehavior _rightBehavior;

  late final HorizontalDragGestureRecognizer gestureRecognizer;

  ModalRoute? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? nextRoute = ModalRoute.of(context);
    if (nextRoute != _route) {
      _route?.unregisterPopEntry(this);
      _route = nextRoute;
      _route?.registerPopEntry(this);
    }
  }

  @override
  void initState() {
    _leftBehavior = MiuixExitUntilCollapsedScrollBehavior();
    _rightBehavior = MiuixExitUntilCollapsedScrollBehavior();
    currentPage = widget.initialPage;
    gestureRecognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onUpdate = ((details) => setState(() => offset += details.delta.dx))
      ..onEnd = (details) async {
        if (details.velocity.pixelsPerSecond.dx.abs() > 1 &&
            details.velocity.pixelsPerSecond.dx >= 0) {
          setState(() {
            Future.delayed(const Duration(milliseconds: 300), () => offset = 0);
            currentPage = -1;
          });
        } else if (offset > MediaQuery.of(context).size.width / 2) {
          setState(() {
            Future.delayed(const Duration(milliseconds: 300), () => offset = 0);
            currentPage = -1;
          });
        } else {
          int i = 10;
          while (offset != 0) {
            setState(() {
              offset -= i;
              i *= 10;
              if (offset < 0) {
                offset = 0;
              }
            });
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      }
      ..onCancel = () async {
        int i = 10;
        while (offset != 0) {
          setState(() {
            offset -= i;
            i *= 10;
            if (offset < 0) {
              offset = 0;
            }
          });
          await Future.delayed(const Duration(milliseconds: 10));
        }
      };
    super.initState();
  }

  @override
  dispose() {
    _leftBehavior.state.dispose();
    _rightBehavior.state.dispose();
    super.dispose();
    gestureRecognizer.dispose();
    App.temporaryDisablePopGesture = false;
    _route?.unregisterPopEntry(this);
  }

  @override
  Widget build(BuildContext context) {
    if (currentPage != -1 && !enableTwoViews) {
      canPop.value = false;
      App.temporaryDisablePopGesture = true;
    } else {
      canPop.value = true;
      App.temporaryDisablePopGesture = false;
    }
    return MiuixScaffold(
      content: (_) => buildBody(),
    );
  }

  Widget buildBody() {
    if (enableTwoViews) {
      return Row(
        children: [
          SizedBox(
            width: 320,
            height: double.infinity,
            child: buildLeft(),
          ),
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: context.colorScheme.outlineVariant,
                  width: 0.6,
                ),
              ),
            ),
          ),
          Expanded(child: buildRight())
        ],
      );
    } else {
      return Stack(
        children: [
          Positioned.fill(child: buildLeft()),
          if (currentPage != -1)
            Positioned(
              left: offset,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Listener(
                onPointerDown: handlePointerDown,
                child: MiuixScaffold(
                  content: (_) => buildRight(),
                ),
              ),
            )
        ],
      );
    }
  }

  void handlePointerDown(PointerDownEvent event) {
    if (event.position.dx < 20) {
      gestureRecognizer.addPointer(event);
    }
  }

  Widget buildLeft() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MiuixScaffold(
      topBar: MiuixTopAppBar(color: MiuixTheme.of(context).colors.background, 
        title: "设置".tl,
        scrollBehavior: _leftBehavior,
        blurred: true,
        blurRadius: 50,
        blurTintAlpha: isDark ? 0.42 : 0.48,
        navigationIcon: Navigator.of(context).canPop()
            ? MiuixTooltipBox(
 tooltip: (_, scope) => MiuixPlainTooltip(scope: scope, child: Text("返回".tl)),
 child: MiuixIconButton(
                  child: MiuixIcon(
                    vector: MiuixIcons.extended.byName('chevronBackward') ??
                        MiuixIcons.os4.back,
                    size: 20,
                  ),
                  onPressed: () => App.globalBack(),
                ),
)
            : null,
      ),
      content: (padding) => MiuixScrollBehaviorListener(
        behavior: _leftBehavior,
        child: buildCategories(padding),
      ),
    );
  }

  Widget buildCategories([EdgeInsets padding = EdgeInsets.zero]) {
    Widget buildItem(String name, int id) {
      final bool selected = id == currentPage;

      Widget content = Container(
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShapeDecoration(
          color: selected
              ? colors.primary.withOpacity(0.15)
              : colors.surface,
          shape: const MiuixSquircleBorder(cornerRadius: 16),
        ),
        child: Row(children: [
          Icon(
            icons[id],
            color: selected ? colors.primary : colors.onSurface,
            size: 22,
          ),
          const SizedBox(
            width: 16,
          ),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? colors.primary : colors.onSurface,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: colors.onSurfaceVariant.withOpacity(0.5),
          ),
        ]),
      );

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: MiuixPressable(
 onPressed: () => setState(() {
              _rightBehavior.state.heightOffset = 0;
              _rightBehavior.state.contentOffset = 0;
              currentPage = id;
            }),
 feedbackType: MiuixPressFeedbackType.sink,
 child: content,
),
      );
    }

    return ListView.builder(
      padding: padding,
      itemCount: categories.length,
      itemBuilder: (context, index) => buildItem(categories[index].tl, index),
    );
  }

  Widget buildReadingSettings() {
    return const Placeholder();
  }

  Widget buildAppearanceSettings() => Column(
        children: [
          MiuixSmallTitle("主题与色彩".tl),
          MiuixSettingsCard(
            children: [
              MiuixWindowDropdownPreference(
                title: "主题选择".tl,
                startAction: const Icon(Icons.color_lens),
                items: [
                  "动态色彩".tl,
                  "小米蓝".tl,
                  "玫瑰粉".tl,
                  "薰衣草紫".tl,
                  "靛青".tl,
                  "天蓝".tl,
                  "青色".tl,
                  "蓝绿".tl,
                  "抹茶绿".tl,
                  "青柠".tl,
                  "金黄".tl,
                  "琥珀".tl,
                  "珊瑚橙".tl,
                ],
                selectedIndex:
                    (int.tryParse(appdata.settings[27]) ?? 0).clamp(0, 12),
                onSelectedIndexChange: (i) {
                  setState(() {
                    appdata.settings[27] = i.toString();
                  });
                  appdata.updateSettings();
                  MyApp.updater?.call();
                },
              ),
              MiuixWindowDropdownPreference(
                title: "深色模式".tl,
                startAction: const Icon(Icons.dark_mode),
                items: ["跟随系统".tl, "禁用".tl, "启用".tl],
                selectedIndex: (int.tryParse(appdata.settings[32]) ?? 0).clamp(0, 2),
                onSelectedIndexChange: (i) {
                  setState(() {
                    appdata.settings[32] = i.toString();
                  });
                  appdata.updateSettings();
                  MyApp.updater?.call();
                },
              ),
              if (appdata.settings[32] == "0" || appdata.settings[32] == "2")
                MiuixSwitchPreference(
                  title: "纯黑色模式".tl,
                  startAction: const Icon(Icons.remove_red_eye),
                  value: appdata.settings[84] == "1",
                  onChanged: (i) {
                    setState(() {
                      appdata.settings[84] = i ? "1" : "0";
                    });
                    appdata.updateSettings();
                    MyApp.updater?.call();
                  },
                ),
            ],
          ),
          if (App.isAndroid) ...[
            MiuixSmallTitle("显示与刷新率".tl),
            MiuixSettingsCard(
              children: [
                MiuixSwitchPreference(
                  title: "高刷新率模式".tl,
                  summary: "尝试强制设置高刷新率, 可能对部分机型不起作用".tl,
                  startAction: const Icon(Icons.smart_screen_outlined),
                  value: appdata.settings[38] == "1",
                  onChanged: (b) {
                    setState(() {
                      appdata.settings[38] = b ? "1" : "0";
                    });
                    appdata.updateSettings();
                    if (b) {
                      try {
                        FlutterDisplayMode.setHighRefreshRate();
                      } catch (e) {
                        // ignore
                      }
                    } else {
                      try {
                        FlutterDisplayMode.setLowRefreshRate();
                      } catch (e) {
                        // ignore
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      );

  Widget buildAppSettings() {
    return Column(
      children: [
        MiuixSmallTitle("日志与调试".tl),
        MiuixSettingsCard(
          children: [
            MiuixArrowPreference(
              startAction: const Icon(Icons.bug_report),
              title: "Logs",
              summary: "查看运行与调试日志".tl,
              onClick: () => context.to(() => const LogsPage()),
            ),
          ],
        ),
        MiuixSmallTitle("版本与更新".tl),
        MiuixSettingsCard(
          children: [
            MiuixArrowPreference(
              startAction: const Icon(Icons.update),
              title: "检查更新".tl,
              summary: "${"当前:".tl} $appVersion",
              onClick: () => findUpdate(context),
            ),
            SwitchSetting(
              title: "启动时检查更新".tl,
              settingsIndex: 2,
              icon: const Icon(Icons.security_update),
            ),
          ],
        ),
        MiuixSmallTitle("存储与数据".tl),
        MiuixSettingsCard(
          children: [
            if (App.isDesktop || App.isAndroid)
              MiuixArrowPreference(
                startAction: const Icon(Icons.folder),
                title: "设置下载目录".tl,
                onClick: () => setDownloadFolder(),
              ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.sd_storage_outlined),
              title: "缓存大小限制".tl,
              summary: '${bytesLengthToReadableSize(CacheManager().currentSize)}'
                  ' / '
                  '${bytesLengthToReadableSize(CacheManager().limitSize)}',
              onClick: setCacheLimit,
            ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.delete_outline),
              title: "清除缓存".tl,
              onClick: () {
                CacheManager().clear().then((value) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              },
            ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.delete_forever),
              title: "删除所有数据".tl,
              onClick: () => clearUserData(context),
            ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.sim_card_download),
              title: "导出用户数据".tl,
              onClick: () => exportDataSetting(context),
            ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.data_object),
              title: "导入用户数据".tl,
              onClick: () => importDataSetting(context),
            ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.sync),
              title: "数据同步".tl,
              onClick: () => syncDataSettings(context),
            ),
          ],
        ),
        MiuixSmallTitle("安全与隐私".tl),
        MiuixSettingsCard(
          children: [
            if (App.isAndroid)
              MiuixSwitchPreference(
                startAction: const Icon(Icons.screenshot),
                title: "阻止屏幕截图".tl,
                summary: "需要重启App以应用更改".tl,
                value: appdata.settings[12] == "1",
                onChanged: (b) {
                  b ? appdata.settings[12] = "1" : appdata.settings[12] = "0";
                  setState(() {});
                  appdata.writeData();
                },
              ),
            SwitchSetting(
              title: "需要身份验证".tl,
              subTitle: "如果系统中未设置任何认证方法请勿开启".tl,
              settingsIndex: 13,
              icon: const Icon(Icons.security),
            ),
          ],
        ),
        MiuixSmallTitle("其它偏好".tl),
        MiuixSettingsCard(
          children: [
            MiuixWindowDropdownPreference(
              title: "语言".tl,
              startAction: const Icon(Icons.language),
              selectedIndex: ["", "cn", "tw", "en"].indexOf(appdata.settings[50]).clamp(0, 3),
              items: const ["System", "中文(简体)", "中文(繁體)", "English"],
              onSelectedIndexChange: (value) {
                appdata.settings[50] = ["", "cn", "tw", "en"][value];
                appdata.updateSettings();
                MyApp.updater?.call();
              },
            ),
            MiuixWindowDropdownPreference(
              title: "下载并行".tl,
              startAction: const Icon(Icons.download),
              selectedIndex: ["1", "2", "4", "6", "8", "16"].indexOf(appdata.settings[79]).clamp(0, 5),
              items: const ["1", "2", "4", "6", "8", "16"],
              onSelectedIndexChange: (value) {
                appdata.settings[79] = ["1", "2", "4", "6", "8", "16"][value];
                appdata.updateSettings();
              },
            ),
            if (App.isAndroid)
              MiuixArrowPreference(
                title: "应用链接".tl,
                summary: "在系统设置中管理APP支持的链接".tl,
                startAction: const Icon(Icons.link),
                onClick: () {
                  const MethodChannel("pica_comic/settings").invokeMethod("link");
                },
              ),
            if (kDebugMode)
              MiuixArrowPreference(
                title: "Debug",
                onClick: debug,
              ),
          ],
        ),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16))
      ],
    );
  }

  Widget buildAbout() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 96,
          height: 96,
          decoration: const ShapeDecoration(
            shape: MiuixSquircleBorder(cornerRadius: 24),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Image(
            image: AssetImage("images/app_icon_no_bg.png"),
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Pica Comic",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "V$appVersion (HyperOS Edition)",
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "一个完全免费的漫画阅读APP · 仅用于学习交流".tl,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        MiuixSmallTitle("开源与社区".tl),
        MiuixSettingsCard(
          children: [
            MiuixArrowPreference(
              startAction: const Icon(Icons.code),
              title: "项目地址 (GitHub)".tl,
              summary: "https://github.com/Pacalini/PicaComic",
              onClick: () => launchUrlString(
                "https://github.com/Pacalini/PicaComic",
                mode: LaunchMode.externalApplication,
              ),
            ),
            MiuixArrowPreference(
              startAction: const Icon(Icons.bug_report_outlined),
              title: "问题反馈 (GitHub Issues)".tl,
              summary: "提交缺陷与功能建议".tl,
              onClick: () => launchUrlString(
                "https://github.com/Pacalini/PicaComic/issues",
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24))
      ],
    );
  }

  Widget buildRight() {
    final Widget body = switch (currentPage) {
      -1 => const SizedBox(),
      0 => buildExploreSettings(context, false),
      1 => const ComicSourceSettings(),
      2 => const ReadingSettings(false),
      3 => buildAppearanceSettings(),
      4 => const LocalFavoritesSettings(),
      5 => buildAppSettings(),
      6 => const NetworkSettings(),
      7 => buildAbout(),
      _ => throw UnimplementedError()
    };

    if (currentPage != -1) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return MiuixScaffold(
        containerColor: Theme.of(context).scaffoldBackgroundColor,
        topBar: MiuixTopAppBar(color: MiuixTheme.of(context).colors.background, 
          title: categories[currentPage].tl,
          scrollBehavior: _rightBehavior,
          blurred: true,
          blurRadius: 50,
          blurTintAlpha: isDark ? 0.42 : 0.48,
          navigationIcon: enableTwoViews
              ? null
              : MiuixIconButton(
                  child: MiuixIcon(
                    vector: MiuixIcons.extended.byName('chevronBackward') ??
                        MiuixIcons.os4.back,
                    size: 20,
                  ),
                  onPressed: () => setState(() {
                    _leftBehavior.state.heightOffset = 0;
                    currentPage = -1;
                  }),
                ),
        ),
        content: (padding) => MiuixScrollBehaviorListener(
          behavior: _rightBehavior,
          child: SingleChildScrollView(
            // 不能给 key 加 currentPage：换页时整棵子树会被重建，
            // 滚动位置与布局都会重置，进页面第一帧会「抖」一下。
            // 用 PageStorageKey 反而能记住每页各自的滚动位置。
            key: PageStorageKey<int>(currentPage),
            padding: padding,
            child: body,
          ),
        ),
      );
    }

    return body;
  }

  var canPop = ValueNotifier(true);

  @override
  ValueListenable<bool> get canPopNotifier => canPop;

  @override
  void onPopInvokedWithResult(bool didPop, result) {
    if (currentPage != -1) {
      setState(() {
        _leftBehavior.state.heightOffset = 0;
        currentPage = -1;
      });
    }
  }

  @override
  void onPopInvoked(bool didPop) {
    if (currentPage != -1) {
      setState(() {
        _leftBehavior.state.heightOffset = 0;
        currentPage = -1;
      });
    }
  }
}
