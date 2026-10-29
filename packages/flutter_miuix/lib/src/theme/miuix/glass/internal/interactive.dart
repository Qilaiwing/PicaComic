// Miuix Flutter 移植版 - OS4 无涟漪交互
// 源自 compose-miuix-ui/miuix 的 GlassTabRow.kt、GlassPopup.kt。
// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

class GlassInteractive extends StatefulWidget {
  const GlassInteractive({
    super.key,
    required this.onTap,
    required this.builder,
    this.selected,
    this.label,
    this.pointerInput = true,
  });
  final VoidCallback? onTap;
  final bool pointerInput;
  final Widget Function(BuildContext, bool, bool) builder;
  final bool? selected;
  final String? label;
  @override
  State<GlassInteractive> createState() => _GlassInteractiveState();
}

class _GlassInteractiveState extends State<GlassInteractive> {
  bool _pressed = false, _focused = false;
  @override
  void didUpdateWidget(GlassInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onTap == null) _pressed = false;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.onTap != null,
    selected: widget.selected,
    inMutuallyExclusiveGroup: widget.selected != null,
    label: widget.label,
    onTap: widget.pointerInput ? null : widget.onTap,
    child: FocusableActionDetector(
      enabled: widget.onTap != null,
      mouseCursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.pointerInput ? widget.onTap : null,
        onTapDown: !widget.pointerInput || widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: !widget.pointerInput || widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.pointerInput
            ? () => setState(() => _pressed = false)
            : null,
        child: widget.builder(context, _pressed, _focused),
      ),
    ),
  );
}
