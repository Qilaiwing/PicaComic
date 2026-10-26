part of pica_reader;

void showSettings(BuildContext context) {
  if (UiMode.m1(context)) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // 遮罩几乎透明，否则面板底下的模糊采样到的是被压暗的画面，
      // 玻璃效果会被灰色糊掉，看起来就像没有模糊。
      barrierColor: Colors.black.withOpacity(0.06),
      builder: (context) => const _MiuixReadingSettingsModal(),
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

class _MiuixReadingSettingsModal extends StatelessWidget {
  const _MiuixReadingSettingsModal();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: MiuixGlassPanel(
        cornerRadius: 26,
        // 之前是不透明度 0xF0/0xF4，几乎是不透明实色，背后的模糊透不出来
        tint: isDark ? const Color(0xD01C1C1E) : const Color(0xDCF4F4F7),
        strokeColor: isDark ? const Color(0x24FFFFFF) : const Color(0x0E000000),
        strokeWidth: 0.8,
        blurRadius: 30,
        shadow: BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.5 : 0.16),
          blurRadius: 24,
          offset: const Offset(0, -6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x38FFFFFF)
                      : const Color(0x28000000),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const Flexible(
              child: ReadingSettings(),
            ),
          ],
        ),
      ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: ShapeDecoration(
        shape: MiuixSquircleBorder(
          cornerRadius: 16,
          side: BorderSide(
            color: isDark ? const Color(0x18FFFFFF) : const Color(0x0A000000),
            width: 0.6,
          ),
        ),
        color: isDark ? const Color(0xFF242428) : Colors.white,
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // 内外都用 squircle 裁剪；之前内层是普通圆角，边缘会错位出一圈亮边
      child: Material(
        color: Colors.transparent,
        shape: const MiuixSquircleBorder(cornerRadius: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 52,
      endIndent: 16,
      color: isDark ? const Color(0x12FFFFFF) : const Color(0x0C000000),
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
                Tooltip(
                  message: "关闭".tl,
                  child: MiuixIconButton(
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
              ListTile(
                leading: const Icon(Icons.chrome_reader_mode_outlined),
                title: Text("阅读模式".tl),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
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
                    ),
                    const SizedBox(width: 4),
                    MiuixIcon(
                      vector: MiuixIcons.extended.byName('chevronForward') ??
                          MiuixIcons.os4.more,
                      size: 16,
                    ),
                  ],
                ),
                onTap: () => setState(() {
                  i = 1;
                }),
              ),
              if (appdata.settings[9] == "5" || appdata.settings[9] == "6") ...[
                _buildDivider(isDark),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_motion_outlined),
                  title: Text("首页显示单张图片".tl),
                  trailing: MiuixSwitch(
                    value: appdata.implicitData[1] == '1',
                    onChanged: (b) {
                      appdata.implicitData[1] = b ? '1' : '0';
                      appdata.writeData();
                      setState(() {});
                      logic.update();
                    },
                  ),
                ),
              ],
            ],
          ),

          // 2. 翻页与手势
          _buildSectionHeader("翻页与手势".tl),
          _buildCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.touch_app_outlined),
                title: Text("点按翻页".tl),
                trailing: MiuixSwitch(
                  value: pageChangeValue,
                  onChanged: (b) {
                    b ? appdata.settings[0] = "1" : appdata.settings[0] = "0";
                    setState(() {
                      pageChangeValue = b;
                    });
                    appdata.writeData();
                  },
                ),
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
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text("反转点按翻页".tl),
                  trailing: MiuixSwitch(
                    value: appdata.settings[70] == "1",
                    onChanged: (b) => setState(() {
                      appdata.settings[70] = b ? "1" : "0";
                      appdata.updateSettings();
                    }),
                  ),
                ),
              ],
              _buildDivider(isDark),
              ListTile(
                leading: const Icon(Icons.volume_mute_outlined),
                title: Text("使用音量键翻页".tl),
                trailing: MiuixSwitch(
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
                ListTile(
                  leading: const Icon(Icons.screenshot_outlined),
                  title: Text("保持屏幕常亮".tl),
                  trailing: MiuixSwitch(
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
                ),
                _buildDivider(isDark),
              ],
              ListTile(
                leading: const Icon(Icons.brightness_4_outlined),
                title: Text("深色模式下降低图片亮度".tl),
                trailing: MiuixSwitch(
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
              ),
              if (App.isAndroid) ...[
                _buildDivider(isDark),
                ListTile(
                  leading: const Icon(Icons.screen_lock_rotation_outlined),
                  title: Text("固定屏幕方向".tl),
                  trailing: Select(
                    initialValue: int.parse(appdata.settings[76]),
                    values: [
                      "禁用".tl,
                      "横屏".tl,
                      "竖屏".tl,
                    ],
                    onChange: (int i) {
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
                    },
                  ),
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
                ListTile(
                  leading: const Icon(Icons.fit_screen_outlined),
                  title: Text("图片缩放".tl),
                  trailing: Select(
                    initialValue: int.parse(appdata.settings[41]),
                    values: ["容纳".tl, "适应宽度".tl, "适应高度".tl],
                    onChange: (int i) {
                      appdata.settings[41] = i.toString();
                      appdata.updateSettings();
                      logic.photoViewController.resetWithNewBoxFit(switch (i) {
                        0 => BoxFit.contain,
                        1 => BoxFit.fitWidth,
                        2 => BoxFit.fitHeight,
                        _ => BoxFit.contain,
                      });
                    },
                  ),
                ),
                _buildDivider(isDark),
              ],
              ListTile(
                leading: const Icon(Icons.zoom_out_map_outlined),
                title: Text("双击缩放".tl),
                trailing: MiuixSwitch(
                  value: appdata.settings[49] == "1",
                  onChanged: (value) {
                    appdata.settings[49] = value ? "1" : "0";
                    logic.update();
                    appdata.updateSettings();
                    setState(() {});
                  },
                ),
              ),
              if (logic.readingMethod ==
                  ReadingMethod.topToBottomContinuously) ...[
                _buildDivider(isDark),
                ListTile(
                  leading: const Icon(Icons.width_normal_sharp),
                  title: Text("限制图片最大显示宽度".tl),
                  trailing: MiuixSwitch(
                    value: appdata.settings[43] == "1",
                    onChanged: (b) => setState(() {
                      appdata.settings[43] = b ? "1" : "0";
                      appdata.updateSettings();
                      Future.microtask(() => logic.update());
                    }),
                  ),
                ),
              ],
              _buildDivider(isDark),
              ListTile(
                leading: const Icon(Icons.zoom_in_outlined),
                title: Text("长按缩放".tl),
                trailing: MiuixSwitch(
                  value: appdata.settings[55] == "1",
                  onChanged: (b) => setState(() {
                    appdata.settings[55] = b ? "1" : "0";
                    appdata.updateSettings();
                    Future.microtask(() => logic.update());
                  }),
                ),
              ),
              _buildDivider(isDark),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text("显示页面信息".tl),
                trailing: MiuixSwitch(
                  value: appdata.settings[57] == "1",
                  onChanged: (b) => setState(() {
                    appdata.settings[57] = b ? "1" : "0";
                    appdata.updateSettings();
                    Future.microtask(() => logic.update());
                  }),
                ),
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
                ListTile(
                  leading: const Icon(Icons.alt_route_outlined),
                  title: Text("设置分流".tl),
                  trailing: MiuixIcon(
                    vector: MiuixIcons.extended.byName('chevronForward') ??
                        MiuixIcons.os4.more,
                    size: 16,
                  ),
                  onTap: () => setState(() {
                    i = 2;
                  }),
                ),
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
                  ListTile(
                    title: Text(
                      options[index],
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: MiuixRadioButton(
                      selected: isSelected,
                      onChanged: (b) => setValue(index + 1),
                    ),
                    onTap: () => setValue(index + 1),
                  ),
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
                  FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size.fromHeight(46),
                    ),
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
