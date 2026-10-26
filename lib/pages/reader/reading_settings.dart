part of pica_reader;

void showSettings(BuildContext context) {
  if (UiMode.m1(context)) {
    showMiuixBottomSheet<void>(
      context: context,
      builder: (context, close) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: const Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: ReadingSettings(),
          ),
        ),
      ),
    );
  } else {
    showSideBar(
      context,
      const SingleChildScrollView(
        child: ReadingSettings(),
      ),
      useSurfaceTintColor: true,
      width: 450,
    );
  }
}

class ReadingSettings extends StatefulWidget {
  const ReadingSettings({Key? key}) : super(key: key);

  @override
  State<ReadingSettings> createState() => _ReadingSettingsState();
}

class _ReadingSettingsState extends State<ReadingSettings> {
  bool pageChangeValue = appdata.settings[0] == "1";
  bool useVolumeKeyChangePage = appdata.settings[7] == "1";
  bool keepScreenOn = appdata.settings[14] == "1";
  bool lowBrightness = appdata.settings[18] == "1";
  var value = int.parse(appdata.settings[9]);
  int i = 0;

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: MiuixCard(
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 52, right: 16),
      child: MiuixHorizontalDivider(
        thickness: 0.6,
        color: isDark ? const Color(0x12FFFFFF) : const Color(0x0C000000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logic = StateController.find<ComicReadingPageLogic>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final readingModes = [
      "从左至右".tl,
      "从右至左".tl,
      "从上至下".tl,
      "从上至下(连续)".tl,
      "双页".tl,
      "双页(反向)".tl
    ];

    var pages = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            child: Row(
              children: [
                Text(
                  "阅读设置".tl,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                MiuixTooltipBox(tooltip: (context, scope) => MiuixPlainTooltip(scope: scope, child: Text("关闭".tl)), child: MiuixIconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: MiuixIcon(
                      vector: MiuixIcons.os4.close,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 1. 阅读模式
          _buildSectionHeader("阅读模式".tl),
          _buildCard(
            isDark: isDark,
            children: [
              MiuixArrowPreference(startAction: const Icon(Icons.chrome_reader_mode_outlined), title: "阅读模式".tl, endActions: [Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(),
                        color: primary.withOpacity(isDark ? 0.22 : 0.12),
                      ),
                      child: Text(
                        readingModes[int.parse(appdata.settings[9]) - 1],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    )], onClick: () => setState(() {
                  i = 1;
                }),),
              if (appdata.settings[9] == "5" || appdata.settings[9] == "6") ...[
                _buildDivider(isDark),
                MiuixSwitchPreference(startAction: const Icon(Icons.auto_awesome_motion_outlined), title: "首页显示单张图片".tl,
                    value: appdata.implicitData[1] == '1',
                    onChanged: (b) {
                      appdata.implicitData[1] = b ? '1' : '0';
                      appdata.writeData();
                      setState(() {});
                      logic.update();
                    },
                  ),
              ],
            ],
          ),

          // 2. 翻页与手势
          _buildSectionHeader("翻页与手势".tl),
          _buildCard(
            isDark: isDark,
            children: [
              MiuixSwitchPreference(startAction: const Icon(Icons.touch_app_outlined), title: "点按翻页".tl,
                  value: pageChangeValue,
                  onChanged: (b) {
                    b ? appdata.settings[0] = "1" : appdata.settings[0] = "0";
                    setState(() {
                      pageChangeValue = b;
                    });
                    appdata.writeData();
                  },
                ),
              if (appdata.settings[0] == "1") ...[
                _buildDivider(isDark),
                MiuixSliderPreference(
                  title: "点按翻页识别范围".tl,
                  value: (int.tryParse(appdata.settings[40]) ?? 10)
                      .toDouble()
                      .clamp(1.0, 40.0),
                  min: 1,
                  max: 40,
                  steps: 39,
                  valueText: "${appdata.settings[40]}%",
                  onValueChange: (v) {
                    setState(() {
                      appdata.settings[40] = v.toInt().toString();
                    });
                    appdata.updateSettings();
                  },
                ),
                _buildDivider(isDark),
                MiuixSwitchPreference(startAction: const Icon(Icons.swap_horiz), title: "反转点按翻页".tl,
                    value: appdata.settings[70] == "1",
                    onChanged: (b) => setState(() {
                      appdata.settings[70] = b ? "1" : "0";
                      appdata.updateSettings();
                    }),
                  ),
              ],
              _buildDivider(isDark),
              MiuixSwitchPreference(startAction: const Icon(Icons.volume_mute_outlined), title: "使用音量键翻页".tl,
                  value: useVolumeKeyChangePage,
                  onChanged: (b) {
                    b ? appdata.settings[7] = "1" : appdata.settings[7] = "0";
                    setState(() {
                      useVolumeKeyChangePage = b;
                    });
                    appdata.writeData();
                    logic.update();
                  },
                ),
              _buildDivider(isDark),
              MiuixSliderPreference(
                startAction: const Icon(Icons.timer_outlined),
                title: "自动翻页时间间隔".tl,
                value: (int.tryParse(appdata.settings[33]) ?? 5)
                    .toDouble()
                    .clamp(1.0, 20.0),
                min: 1,
                max: 20,
                steps: 19,
                valueText: "${appdata.settings[33]}s",
                onValueChange: (v) {
                  setState(() {
                    appdata.settings[33] = v.toInt().toString();
                  });
                  appdata.updateSettings();
                },
              ),
            ],
          ),

          // 3. 屏幕与显示
          _buildSectionHeader("屏幕与显示".tl),
          _buildCard(
            isDark: isDark,
            children: [
              if (App.isAndroid) ...[
                MiuixSwitchPreference(startAction: const Icon(Icons.screenshot_outlined), title: "保持屏幕常亮".tl,
                    value: keepScreenOn,
                    onChanged: (b) {
                      b ? setKeepScreenOn() : cancelKeepScreenOn();
                      b
                          ? appdata.settings[14] = "1"
                          : appdata.settings[14] = "0";
                      setState(() {
                        keepScreenOn = b;
                      });
                      appdata.writeData();
                    },
                  ),
                _buildDivider(isDark),
              ],
              MiuixSwitchPreference(startAction: const Icon(Icons.brightness_4_outlined), title: "深色模式下降低图片亮度".tl,
                  value: lowBrightness,
                  onChanged: (b) {
                    b ? appdata.settings[18] = "1" : appdata.settings[18] = "0";
                    setState(() {
                      lowBrightness = b;
                    });
                    appdata.writeData();
                    logic.update();
                  },
                ),
              if (App.isAndroid) ...[
                _buildDivider(isDark),
                MiuixWindowDropdownPreference(startAction: const Icon(Icons.screen_lock_rotation_outlined), title: "固定屏幕方向".tl, items: [
                      "禁用".tl,
                      "横屏".tl,
                      "竖屏".tl,
                    ], selectedIndex: int.parse(appdata.settings[76]), onSelectedIndexChange: (int i) {
                      appdata.settings[76] = i.toString();
                      logic.update();
                      appdata.updateSettings();
                      if (i == 1) {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight
                        ]);
                      } else if (i == 2) {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                          DeviceOrientation.portraitDown,
                        ]);
                      }
                      setState(() {});
                      setState(() {});
                  },
                ),
              ],
            ],
          ),

          // 4. 缩放与排版
          _buildSectionHeader("缩放与排版".tl),
          _buildCard(
            isDark: isDark,
            children: [
              if (logic.readingMethod !=
                  ReadingMethod.topToBottomContinuously) ...[
                MiuixWindowDropdownPreference(startAction: const Icon(Icons.fit_screen_outlined), title: "图片缩放".tl, items: ["容纳".tl, "适应宽度".tl, "适应高度".tl], selectedIndex: int.parse(appdata.settings[41]), onSelectedIndexChange: (int i) {
                      appdata.settings[41] = i.toString();
                      appdata.updateSettings();
                      logic.photoViewController.resetWithNewBoxFit(switch (i) {
                        0 => BoxFit.contain,
                        1 => BoxFit.fitWidth,
                        2 => BoxFit.fitHeight,
                        _ => BoxFit.contain,
                      });
                      setState(() {});
                  },
                ),
                _buildDivider(isDark),
              ],
              MiuixSwitchPreference(startAction: const Icon(Icons.zoom_out_map_outlined), title: "双击缩放".tl,
                  value: appdata.settings[49] == "1",
                  onChanged: (value) {
                    appdata.settings[49] = value ? "1" : "0";
                    logic.update();
                    appdata.updateSettings();
                    setState(() {});
                  },
                ),
              if (logic.readingMethod ==
                  ReadingMethod.topToBottomContinuously) ...[
                _buildDivider(isDark),
                MiuixSwitchPreference(startAction: const Icon(Icons.width_normal_sharp), title: "限制图片最大显示宽度".tl,
                    value: appdata.settings[43] == "1",
                    onChanged: (b) => setState(() {
                      appdata.settings[43] = b ? "1" : "0";
                      appdata.updateSettings();
                      Future.microtask(() => logic.update());
                    }),
                  ),
              ],
              _buildDivider(isDark),
              MiuixSwitchPreference(startAction: const Icon(Icons.zoom_in_outlined), title: "长按缩放".tl,
                  value: appdata.settings[55] == "1",
                  onChanged: (b) => setState(() {
                    appdata.settings[55] = b ? "1" : "0";
                    appdata.updateSettings();
                    Future.microtask(() => logic.update());
                  }),
                ),
              _buildDivider(isDark),
              MiuixSwitchPreference(startAction: const Icon(Icons.insert_drive_file_outlined), title: "显示页面信息".tl,
                  value: appdata.settings[57] == "1",
                  onChanged: (b) => setState(() {
                    appdata.settings[57] = b ? "1" : "0";
                    appdata.updateSettings();
                    Future.microtask(() => logic.update());
                  }),
                ),
            ],
          ),

          // 5. 分流与网络
          if (!logic.data.downloaded &&
              (logic.data.type == ReadingType.picacg ||
                  logic.data.type == ReadingType.jm)) ...[
            _buildSectionHeader("网络设置".tl),
            _buildCard(
              isDark: isDark,
              children: [
                MiuixArrowPreference(startAction: const Icon(Icons.alt_route_outlined), title: "设置分流".tl, onClick: () => setState(() {
                    i = 2;
                  }),),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),

      // Page 1: 阅读模式单选页面
      buildReadingMethodSetting(isDark),

      // Page 2: 分流设置页面
      buildShuntSetting(isDark, logic),
    ];

    return ClipRect(
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final isReturning = i == 0;
          final tween = Tween<Offset>(
            begin: Offset(isReturning ? -0.06 : 0.06, 0),
            end: Offset.zero,
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: tween.animate(animation),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          primary: false,
          key: Key(i.toString()),
          padding: EdgeInsets.only(
            bottom: (MediaQuery.of(context).padding.bottom + 12).clamp(16.0, 100.0),
          ),
          child: pages[i],
        ),
      ),
    );
  }

  void setValue(int i) {
    App.globalBack();
    value = i;
    appdata.settings[9] = value.toString();
    appdata.writeData();
    var logic = StateController.find<ComicReadingPageLogic>();
    logic.tools = false;
    logic.showSettings = false;
    logic.index = 1;
    logic.pageController = PageController(initialPage: 1);
    logic.clearPhotoViewControllers();
    logic.update();
  }

  Widget buildReadingMethodSetting(bool isDark) {
    final options = [
      "从左至右".tl,
      "从右至左".tl,
      "从上至下".tl,
      "从上至下(连续)".tl,
      "双页".tl,
      "双页(反向)".tl
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
          child: Row(
            children: [
              MiuixIconButton(
                onPressed: () => setState(() {
                  i = 0;
                }),
                child: MiuixIcon(
                  vector: MiuixIcons.extended.byName('chevronBackward') ??
                      MiuixIcons.os4.back,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "阅读模式".tl,
                style: const TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        _buildCard(
          isDark: isDark,
          children: List.generate(
            options.length,
            (index) {
              final isSelected = value == index + 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiuixRadioButtonPreference(title: options[index], selected: isSelected, radioButtonLocation: MiuixRadioButtonLocation.end, onClick: () => setValue(index + 1),),
                  if (index != options.length - 1) _buildDivider(isDark),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildShuntSetting(bool isDark, ComicReadingPageLogic logic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
          child: Row(
            children: [
              MiuixIconButton(
                onPressed: () => setState(() {
                  i = 0;
                }),
                child: MiuixIcon(
                  vector: MiuixIcons.extended.byName('chevronBackward') ??
                      MiuixIcons.os4.back,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "设置分流".tl,
                style: const TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        _buildCard(
          isDark: isDark,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "分流节点更改后，重启阅读器以应用新的连接设置。".tl,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MiuixButton(
                    colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                    cornerRadius: 14,
                    minHeight: 46,
                    minWidth: double.infinity,
                    onPressed: () {
                      App.globalBack();
                      logic.refresh_();
                    },
                    child: Text("重启阅读器".tl),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
