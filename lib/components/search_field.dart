part of 'components.dart';

/// 搜索输入框：直接使用外部 controller（唯一数据源），构建期间不做任何文本同步。
/// 取代此前「外部 controller -> MiuixInputField 内部 controller」的同步写法：
/// 那种写法在父级 build 时于 didUpdateWidget 中改写内部 controller，
/// 进而让 EditableText 的选区 Overlay 在构建期间 markNeedsBuild 而崩溃。
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    this.focusNode,
    this.onChanged,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final void Function(String)? onChanged;
  final void Function(String) onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final style = theme.textStyles.main
        .copyWith(fontWeight: FontWeight.w500, color: theme.colors.onSurface);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: theme.colors.surfaceContainerHigh,
        shape: const StadiumBorder(),
      ),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: MiuixIcon(vector: MiuixIcons.os4.search, size: 18),
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 45),
            child: Center(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: autofocus,
                maxLines: 1,
                textInputAction: TextInputAction.search,
                style: style,
                cursorColor: theme.colors.primary,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle:
                      style.copyWith(color: theme.colors.onSurfaceContainerHigh),
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        // 只监听 controller 来切换清除按钮，构建期间不修改任何状态。
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? const SizedBox(width: 12)
              : MiuixIconButton(
                  minWidth: 32,
                  minHeight: 32,
                  onPressed: () {
                    controller.clear();
                    onChanged?.call("");
                  },
                  child: MiuixIcon(vector: MiuixIcons.os4.close, size: 14),
                ),
        ),
      ]),
    );
  }
}
