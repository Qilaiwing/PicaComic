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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
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
    super.key,
  });

  final String title;
  final String? subTitle;
  final Widget icon;
  final int settingsIndex;

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

/// HyperOS 风格带 AppData 绑定的下拉选择设置项
class SelectSettingWithAppdata extends StatelessWidget {
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
  Widget build(BuildContext context) {
    int index = int.tryParse(appdata.settings[settingsIndex]) ?? 0;
    if (index < 0 || index >= options.length) {
      index = 0;
    }
    return MiuixWindowDropdownPreference(
      title: title,
      startAction: icon,
      items: options,
      selectedIndex: index,
      onSelectedIndexChange: (i) {
        appdata.settings[settingsIndex] = i.toString();
        appdata.updateSettings();
        onChanged?.call();
      },
    );
  }
}

/// 通用 HyperOS 下拉选择项
class SelectSetting extends StatelessWidget {
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
  Widget build(BuildContext context) {
    int index = initialValue;
    if (index < 0 || index >= values.length) {
      index = 0;
    }
    return MiuixWindowDropdownPreference(
      title: title,
      startAction: leading,
      items: values,
      selectedIndex: index,
      onSelectedIndexChange: onChanged,
    );
  }
}
