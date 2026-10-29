part of pica_settings;

/// HyperOS 风格分组卡片，包裹一组设置项
class MiuixSettingsCard extends StatelessWidget {
  const MiuixSettingsCard({
    required this.children,
    super.key,
    this.margin,
    this.cornerRadius = MiuixCardDefaults.cornerRadius,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  /// 卡片圆角。按压遮罩会跟着这个圆角一起被裁剪，
  /// 否则按住设置项时会出现一块方形的深色遮罩。
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: MiuixSquircleBorder(
            cornerRadius: cornerRadius,
            enabled: cornerRadius > 0,
          ),
        ),
        // antiAliasWithSaveLayer 保证圆角边缘平滑，不会留下淡淡的直角残影
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: MiuixCard(
          cornerRadius: cornerRadius,
          insideMargin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// HyperOS 风格设置项开关
class SwitchSetting extends StatefulWidget {
  const SwitchSetting({
    required this.title,
    this.subTitle,
    required this.icon,
    required this.settingsIndex,
    this.onChanged,
    super.key,
  });

  final String title;
  final String? subTitle;
  final Widget icon;
  final int settingsIndex;
  final VoidCallback? onChanged;

  @override
  State<SwitchSetting> createState() => _SwitchSettingState();
}

class _SwitchSettingState extends State<SwitchSetting> {
  @override
  Widget build(BuildContext context) {
    return MiuixSwitchPreference(
      title: widget.title,
      summary: widget.subTitle,
      startAction: widget.icon,
      value: appdata.settings[widget.settingsIndex] == '1',
      onChanged: (value) {
        setState(() {
          appdata.settings[widget.settingsIndex] = value ? '1' : '0';
          appdata.updateSettings();
        });
        widget.onChanged?.call();
      },
    );
  }
}

/// HyperOS 风格设置小分组标题
class SettingsTitle extends StatelessWidget {
  const SettingsTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: MiuixSmallTitle(text),
    );
  }
}

/// HyperOS 风格带箭头的页面跳转设置项
class NewPageSetting extends StatelessWidget {
  const NewPageSetting({
    required this.title,
    required this.onTap,
    required this.icon,
    super.key,
  });

  final String title;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return MiuixArrowPreference(
      title: title,
      startAction: icon,
      onClick: onTap,
    );
  }
}

/// HyperOS 风格带 AppData 绑定的下拉选择设置项。
///
/// 使用 [showMiuixMenu] 而不是嵌入式 WindowDropdownPreference：
/// 后者在设置页滚动宿主里 OverlayEntry 点选回调经常丢，导致分流/站点等无法切换。
class SelectSettingWithAppdata extends StatefulWidget {
  const SelectSettingWithAppdata({
    super.key,
    required this.icon,
    required this.title,
    required this.settingsIndex,
    required this.options,
    this.onChanged,
  });

  final Widget icon;
  final String title;
  final int settingsIndex;
  final List<String> options;
  final void Function()? onChanged;

  @override
  State<SelectSettingWithAppdata> createState() =>
      _SelectSettingWithAppdataState();
}

class _SelectSettingWithAppdataState extends State<SelectSettingWithAppdata> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _clamp(int.tryParse(appdata.settings[widget.settingsIndex]) ?? 0);
  }

  @override
  void didUpdateWidget(covariant SelectSettingWithAppdata oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settingsIndex != widget.settingsIndex ||
        oldWidget.options.length != widget.options.length) {
      _index = _clamp(int.tryParse(appdata.settings[widget.settingsIndex]) ?? 0);
    }
  }

  int _clamp(int v) {
    if (widget.options.isEmpty) return 0;
    if (v < 0 || v >= widget.options.length) return 0;
    return v;
  }

  Future<void> _open() async {
    final picked = await showMiuixMenu(
      context: context,
      anchorBounds: miuixAnchorRectOf(context),
      items: widget.options,
      selectedIndex: _index,
      alignment: MiuixPopupAlign.end,
      minWidth: 168,
    );
    if (!mounted || picked == null) return;
    setState(() => _index = picked);
    appdata.settings[widget.settingsIndex] = picked.toString();
    appdata.updateSettings();
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _SelectPreferenceRow(
      title: widget.title,
      startAction: widget.icon,
      valueText: widget.options.isEmpty ? '' : widget.options[_index],
      onClick: _open,
    );
  }
}

/// 通用 HyperOS 下拉选择项（[showMiuixMenu]）。
class SelectSetting extends StatefulWidget {
  const SelectSetting({
    super.key,
    required this.leading,
    required this.title,
    required this.values,
    required this.onChanged,
    required this.initialValue,
  });

  final Widget leading;
  final String title;
  final List<String> values;
  final void Function(int i) onChanged;
  final int initialValue;

  @override
  State<SelectSetting> createState() => _SelectSettingState();
}

class _SelectSettingState extends State<SelectSetting> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _clamp(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant SelectSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue ||
        oldWidget.values.length != widget.values.length) {
      _index = _clamp(widget.initialValue);
    }
  }

  int _clamp(int v) {
    if (widget.values.isEmpty) return 0;
    if (v < 0 || v >= widget.values.length) return 0;
    return v;
  }

  Future<void> _open() async {
    final picked = await showMiuixMenu(
      context: context,
      anchorBounds: miuixAnchorRectOf(context),
      items: widget.values,
      selectedIndex: _index,
      alignment: MiuixPopupAlign.end,
      minWidth: 168,
    );
    if (!mounted || picked == null) return;
    setState(() => _index = picked);
    widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return _SelectPreferenceRow(
      title: widget.title,
      startAction: widget.leading,
      valueText: widget.values.isEmpty ? '' : widget.values[_index],
      onClick: _open,
    );
  }
}

class _SelectPreferenceRow extends StatelessWidget {
  const _SelectPreferenceRow({
    required this.title,
    required this.startAction,
    required this.valueText,
    required this.onClick,
  });

  final String title;
  final Widget startAction;
  final String valueText;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final actionColor = theme.colors.onSurfaceVariantActions;
    return MiuixBasicComponent(
      title: title,
      startAction: startAction,
      endActions: [
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Text(
              valueText,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textStyles.body2.copyWith(color: actionColor),
            ),
          ),
        ),
        MiuixIcon(vector: MiuixIcons.os4.expandMore, size: 22, tint: actionColor),
      ],
      onClick: onClick,
    );
  }
}
