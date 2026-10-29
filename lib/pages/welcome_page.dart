import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/pages/main_page.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'settings/settings_page.dart';

import '../main.dart';
import 'accounts_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  var controller = PageController();

  int page = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
        color: isDark ? const Color(0xFF141416) : const Color(0xFFF3F3F6),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: MiuixSurface(
                      color: isDark ? const Color(0xFF1C1C1F) : Colors.white,
                      cornerRadius: 28,
                      child: SizedBox.expand(
                        child: PageView(
                          controller: controller,
                          onPageChanged: (i) {
                            setState(() {
                              page = i;
                            });
                          },
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            _AppIcon(),
                            _AppInfo(),
                            _AppAppearance(),
                            _ComicsDisplaySettings(),
                            _ReadingSettings(),
                            _ComicSource(),
                            _More(),
                          ],
                        ),
                      ))),
            ).toCenter(),
          ),
        ));
  }

  void next() {
    controller.animateToPage((controller.page! + 1).round(),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic);
  }

  void back() {
    controller.animateToPage((controller.page! - 1).round(),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic);
  }
}

mixin class _WelcomePageComponents {
  Widget buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget buildBottom(BuildContext context, int page, [bool canNext = true]) {
    var state = context.findAncestorStateOfType<_WelcomePageState>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (page != 0)
            MiuixPressable(
                shape: const StadiumBorder(),
                onPressed: state.back,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: isDark
                        ? const Color(0x22FFFFFF)
                        : const Color(0x12000000),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MiuixIcon(
                        vector: MiuixIcons.extended.byName('chevronBackward') ??
                            MiuixIcons.os4.back,
                        size: 16,
                        tint: isDark ? Colors.white : const Color(0xFF222222),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "返回".tl,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ))
          else
            const SizedBox(width: 50),
          const Spacer(),
          // 步骤指示条
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 7; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: i == page ? 16 : 5.5,
                  height: 5.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == page
                        ? primary
                        : (isDark
                            ? const Color(0x33FFFFFF)
                            : const Color(0x22000000)),
                  ),
                ),
            ],
          ),
          const Spacer(),
          MiuixPressable(
              shape: const StadiumBorder(),
              onPressed: canNext
                  ? (page != 6
                      ? state.next
                      : () async {
                          appdata.firstUse[3] = "1";
                          appdata.writeData();
                          await ComicSource.reload();
                          App.offAll(() => const MainPage());
                        })
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 7.5),
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: canNext
                      ? primary
                      : (isDark
                          ? const Color(0x22FFFFFF)
                          : const Color(0x18000000)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      page != 6 ? "继续".tl : "完成".tl,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: canNext
                            ? Colors.white
                            : (isDark
                                ? const Color(0x66FFFFFF)
                                : const Color(0x55000000)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (page != 6)
                      MiuixIcon(
                        vector: MiuixIcons.extended.byName('chevronForward') ??
                            MiuixIcons.os4.chevronForward,
                        size: 15,
                        tint: canNext
                            ? Colors.white
                            : (isDark
                                ? const Color(0x66FFFFFF)
                                : const Color(0x55000000)),
                      )
                    else
                      const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget buildView({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _AppIcon extends StatelessWidget with _WelcomePageComponents {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return buildView(
      children: [
        buildTitle("欢迎".tl),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: ShapeDecoration(
                    shape: const MiuixSquircleBorder(cornerRadius: 32),
                    color: primary.withOpacity(0.08),
                    shadows: [
                      BoxShadow(
                        color: primary.withOpacity(0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    "images/app_icon_no_bg.png",
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Pica Comic",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "轻巧 · 聚合 · HyperOS 质感".tl,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        buildBottom(context, 0),
      ],
    );
  }
}

class _AppInfo extends StatefulWidget {
  const _AppInfo();

  @override
  State<_AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<_AppInfo> with _WelcomePageComponents {
  bool agree = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return buildView(
      children: [
        buildTitle("使用须知".tl),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: ShapeDecoration(
              shape: MiuixSquircleBorder(
                cornerRadius: 16,
                side: BorderSide(
                  color: isDark
                      ? const Color(0x18FFFFFF)
                      : const Color(0x14000000),
                  width: 0.6,
                ),
              ),
              color: isDark ? const Color(0xFF242428) : const Color(0xFFF7F7F9),
            ),
            child: SingleChildScrollView(
              child: Text(
                buildInfo(),
                style: const TextStyle(fontSize: 13.5, height: 1.6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        MiuixPressable(
            borderRadius: BorderRadius.circular(8),
            onPressed: () => setState(() => agree = !agree),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "我已阅读并知晓".tl,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MiuixCheckbox(
                    value: agree,
                    onChanged: (b) {
                      setState(() {
                        agree = b ?? false;
                      });
                    },
                  ),
                ],
              ),
            )),
        buildBottom(context, 1, agree),
      ],
    );
  }

  String buildInfo() {
    var content = '';
    content += "感谢使用本软件, 请注意:".tl;
    content += '\n\n';
    content += "本App的开发目的仅为学习交流与个人兴趣, 显示的任何内容均来自网络, 与开发者无关".tl;
    content += '\n\n';
    content += "如果在使用中发现问题, 请先确认是否为自己的设备问题, 然后再进行反馈".tl;
    content += '\n\n';
    content += "开发者不对能否解决问题负责".tl;
    return content;
  }
}

class _AppAppearance extends StatefulWidget {
  const _AppAppearance();

  @override
  State<_AppAppearance> createState() => _AppAppearanceState();
}

class _AppAppearanceState extends State<_AppAppearance>
    with _WelcomePageComponents {
  @override
  Widget build(BuildContext context) {
    return buildView(
      children: [
        buildTitle("设置App外观".tl),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SelectSettingWithAppdata(
                  icon: const Icon(Icons.color_lens_rounded),
                  title: "主题选择".tl,
                  options: const [
                    "dynamic",
                    "red",
                    "pink",
                    "purple",
                    "indigo",
                    "blue",
                    "cyan",
                    "teal",
                    "green",
                    "lime",
                    "yellow",
                    "amber",
                    "orange",
                  ],
                  settingsIndex: 27,
                  onChanged: () {
                    MyApp.updater?.call();
                  },
                ),
                SelectSettingWithAppdata(
                  icon: const Icon(Icons.dark_mode_rounded),
                  title: "深色模式".tl,
                  options: ["跟随系统".tl, "禁用".tl, "启用".tl],
                  settingsIndex: 32,
                  onChanged: () {
                    MyApp.updater?.call();
                  },
                ),
                if (appdata.settings[32] == "0" || appdata.settings[32] == "2")
                  SelectSettingWithAppdata(
                    icon: const Icon(Icons.remove_red_eye_rounded),
                    title: "纯黑色模式".tl,
                    options: ["禁用".tl, "启用".tl],
                    settingsIndex: 84,
                    onChanged: () {
                      MyApp.updater?.call();
                    },
                  ),
                const ComicTileDisplayModeSetting(),
              ],
            ),
          ),
        ),
        buildBottom(context, 2),
      ],
    );
  }
}

class _ComicsDisplaySettings extends StatefulWidget {
  const _ComicsDisplaySettings();

  @override
  State<_ComicsDisplaySettings> createState() => _ComicsDisplaySettingsState();
}

class _ComicsDisplaySettingsState extends State<_ComicsDisplaySettings>
    with _WelcomePageComponents {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final selectedType = appdata.appSettings.comicsListDisplayType;

    Widget buildOptionTile(
        int value, String title, String subtitle, IconData icon) {
      final isSelected = selectedType == value;
      return MiuixPressable(
          shape: const MiuixSquircleBorder(cornerRadius: 16),
          onPressed: () {
            setState(() {
              appdata.appSettings.comicsListDisplayType = value;
            });
            appdata.updateSettings();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: ShapeDecoration(
              shape: MiuixSquircleBorder(
                cornerRadius: 16,
                side: BorderSide(
                  color: isSelected
                      ? primary.withOpacity(isDark ? 0.55 : 0.42)
                      : (isDark
                          ? const Color(0x1AFFFFFF)
                          : const Color(0x14000000)),
                  width: isSelected ? 1.0 : 0.8,
                ),
              ),
              color: isSelected
                  ? primary.withOpacity(isDark ? 0.14 : 0.07)
                  : (isDark
                      ? const Color(0xFF222226)
                      : const Color(0xFFF7F7F9)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                MiuixRadioButton(
                  selected: isSelected,
                  onChanged: (val) {
                    if (val) {
                      setState(() {
                        appdata.appSettings.comicsListDisplayType = value;
                      });
                      appdata.updateSettings();
                    }
                  },
                ),
              ],
            ),
          ));
    }

    return buildView(
      children: [
        buildTitle("漫画列表显示方式".tl),
        Expanded(
          child: Column(
            children: [
              buildOptionTile(
                0,
                "连续模式".tl,
                "滑动到底部时自动加载下一页并追加到末尾".tl,
                Icons.view_stream_rounded,
              ),
              buildOptionTile(
                1,
                "分页模式".tl,
                "需要手动点击或翻页切换页面".tl,
                Icons.pages_rounded,
              ),
            ],
          ),
        ),
        buildBottom(context, 3),
      ],
    );
  }
}

class _ReadingSettings extends StatelessWidget with _WelcomePageComponents {
  const _ReadingSettings();

  @override
  Widget build(BuildContext context) {
    return buildView(
      children: [
        buildTitle("阅读设置".tl),
        const Expanded(
          child: SingleChildScrollView(
            child: ReadingSettings(false),
          ),
        ),
        buildBottom(context, 4),
      ],
    );
  }
}

class _ComicSource extends StatefulWidget {
  const _ComicSource();

  @override
  State<_ComicSource> createState() => _ComicSourceState();
}

class _ComicSourceState extends State<_ComicSource>
    with _WelcomePageComponents {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return buildView(
      children: [
        buildTitle("漫画源".tl),
        Expanded(
          child: ListView.builder(
            itemCount: builtInSources.length,
            itemBuilder: (context, index) {
              var key = builtInSources[index];
              final isEnabled = appdata.appSettings.isComicSourceEnabled(key);
              final sourceName =
                  ComicSource.builtIn.firstWhere((e) => e.key == key).name;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: ShapeDecoration(
                  shape: MiuixSquircleBorder(
                    cornerRadius: 14,
                    side: BorderSide(
                      color: isDark
                          ? const Color(0x18FFFFFF)
                          : const Color(0x14000000),
                      width: 0.6,
                    ),
                  ),
                  color: isDark
                      ? const Color(0xFF242428)
                      : const Color(0xFFF7F7F9),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        sourceName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    MiuixSwitch(
                      value: isEnabled,
                      onChanged: (v) {
                        appdata.appSettings.setComicSourceEnabled(key, v);
                        appdata.updateSettings();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        buildBottom(context, 5),
      ],
    );
  }
}

class _More extends StatelessWidget with _WelcomePageComponents {
  const _More();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    Widget buildTile(String title, IconData icon, VoidCallback onTap) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: ShapeDecoration(
          shape: MiuixSquircleBorder(
            cornerRadius: 16,
            side: BorderSide(
              color: isDark ? const Color(0x18FFFFFF) : const Color(0x14000000),
              width: 0.6,
            ),
          ),
          color: isDark ? const Color(0xFF242428) : const Color(0xFFF7F7F9),
        ),
        child: MiuixPressable(
            shape: const MiuixSquircleBorder(cornerRadius: 16),
            onPressed: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  MiuixIcon(
                    vector: MiuixIcons.extended.byName('chevronForward') ??
                        MiuixIcons.os4.chevronForward,
                    size: 16,
                    tint: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            )),
      );
    }

    return buildView(
      children: [
        buildTitle("更多".tl),
        Expanded(
          child: Column(
            children: [
              buildTile("登录账号".tl, Icons.account_circle_rounded, () {
                context.to(() => const AccountsPage());
              }),
              buildTile("更多设置".tl, Icons.settings_rounded, () {
                SettingsPage.open();
              }),
            ],
          ),
        ),
        buildBottom(context, 6),
      ],
    );
  }
}
