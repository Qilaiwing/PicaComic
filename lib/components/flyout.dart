part of "components.dart";

const minFlyoutWidth = 256.0;
const minFlyoutHeight = 128.0;

class FlyoutController {
  Function? _show;

  void show() {
    if (_show == null) {
      throw "FlyoutController is not attached to a Flyout";
    }
    _show!();
  }
}

class Flyout extends StatefulWidget {
  const Flyout(
      {super.key,
      required this.flyoutBuilder,
      required this.child,
      this.enableTap = false,
      this.enableDoubleTap = false,
      this.enableLongPress = false,
      this.enableSecondaryTap = false,
      this.withInkWell = false,
      this.borderRadius = 0,
      this.controller,
      this.navigator});

  final WidgetBuilder flyoutBuilder;

  final Widget child;

  final bool enableTap;

  final bool enableDoubleTap;

  final bool enableLongPress;

  final bool enableSecondaryTap;

  final bool withInkWell;

  final double borderRadius;

  final NavigatorState? navigator;

  final FlyoutController? controller;

  @override
  State<Flyout> createState() => _FlyoutState();
}

class _FlyoutState extends State<Flyout> {
  @override
  void initState() {
    if (widget.controller != null) {
      widget.controller?._show = show;
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (widget.controller != null) {
      widget.controller?._show = show;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.withInkWell) {
      // Miuix 按压反馈替代 InkWell 水波纹；双击 / 右键仍由外层 GestureDetector 处理。
      return GestureDetector(
        onDoubleTap: widget.enableDoubleTap ? show : null,
        onSecondaryTap: widget.enableSecondaryTap ? show : null,
        child: MiuixPressable(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          feedbackType: MiuixPressFeedbackType.sink,
          onPressed: widget.enableTap ? show : null,
          onLongPress: widget.enableLongPress ? show : null,
          child: widget.child,
        ),
      );
    }
    return GestureDetector(
      onTap: widget.enableTap ? show : null,
      onDoubleTap: widget.enableDoubleTap ? show : null,
      onLongPress: widget.enableLongPress ? show : null,
      onSecondaryTap: widget.enableSecondaryTap ? show : null,
      child: widget.child,
    );
  }

  /// 以 Miuix 弹窗（[MiuixOverlayListPopup]）在控件处弹出 flyout 内容。
  /// flyout 里的按钮直接 `Navigator.pop` 也能正常关闭。
  void show() {
    var renderBox = context.findRenderObject() as RenderBox;
    var rect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final navigator = widget.navigator;
    _pushMiuixOverlayRoute<void>(navigator?.context ?? context,
        (context, show, close, finished) {
      return MiuixOverlayListPopup(
        show: show,
        anchorBounds: rect,
        minWidth: minFlyoutWidth,
        onDismissRequest: () => close(),
        onDismissFinished: finished,
        content: widget.flyoutBuilder(context),
      );
    }, useRootNavigator: navigator == null);
  }
}

/// flyout 的内容：标题、可选说明和右下角操作按钮。外层表面由 Miuix 弹窗提供。
class FlyoutContent extends StatelessWidget {
  const FlyoutContent(
      {super.key, required this.title, required this.actions, this.content});

  final String title;

  final String? content;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: minFlyoutWidth,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            if (content != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(content!, style: const TextStyle(fontSize: 12)),
              ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [const Spacer(), ...actions],
            ),
          ],
        ),
      ),
    );
  }
}

class FlyoutTextButton extends StatefulWidget {
  const FlyoutTextButton(
      {super.key,
      required this.child,
      required this.flyoutBuilder,
      this.navigator});

  final Widget child;

  final WidgetBuilder flyoutBuilder;

  final NavigatorState? navigator;

  @override
  State<FlyoutTextButton> createState() => _FlyoutTextButtonState();
}

class _FlyoutTextButtonState extends State<FlyoutTextButton> {
  final FlyoutController _controller = FlyoutController();

  @override
  Widget build(BuildContext context) {
    return Flyout(
        controller: _controller,
        flyoutBuilder: widget.flyoutBuilder,
        navigator: widget.navigator,
        child: MiuixButton(
          onPressed: () {
            _controller.show();
          },
          child: widget.child,
        ));
  }
}

class FlyoutIconButton extends StatefulWidget {
  const FlyoutIconButton(
      {super.key,
      required this.icon,
      required this.flyoutBuilder,
      this.navigator});

  final Widget icon;

  final WidgetBuilder flyoutBuilder;

  final NavigatorState? navigator;

  @override
  State<FlyoutIconButton> createState() => _FlyoutIconButtonState();
}

class _FlyoutIconButtonState extends State<FlyoutIconButton> {
  final FlyoutController _controller = FlyoutController();

  @override
  Widget build(BuildContext context) {
    return Flyout(
        controller: _controller,
        flyoutBuilder: widget.flyoutBuilder,
        navigator: widget.navigator,
        child: MiuixIconButton(
          onPressed: () {
            _controller.show();
          },
          child: widget.icon,
        ));
  }
}

class FlyoutFilledButton extends StatefulWidget {
  const FlyoutFilledButton(
      {super.key,
      required this.child,
      required this.flyoutBuilder,
      this.navigator});

  final Widget child;

  final WidgetBuilder flyoutBuilder;

  final NavigatorState? navigator;

  @override
  State<FlyoutFilledButton> createState() => _FlyoutFilledButtonState();
}

class _FlyoutFilledButtonState extends State<FlyoutFilledButton> {
  final FlyoutController _controller = FlyoutController();

  @override
  Widget build(BuildContext context) {
    return Flyout(
        controller: _controller,
        flyoutBuilder: widget.flyoutBuilder,
        navigator: widget.navigator,
        child: MiuixButton(
          colors: MiuixButtonDefaults.buttonColorsPrimary(context),
          onPressed: () {
            _controller.show();
          },
          child: widget.child,
        ));
  }
}
