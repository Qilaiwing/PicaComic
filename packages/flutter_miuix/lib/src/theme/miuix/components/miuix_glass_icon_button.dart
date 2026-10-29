// Miuix Flutter 移植版 - GlassIconButton
// 源自 compose-miuix-ui/miuix 的 GlassTopAppBar.kt、GlassPress.kt。
// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import '../blur/miuix_backdrop.dart';
import '../foundation/miuix_content_color.dart';
import '../glass/miuix_glass_decoration.dart';
import '../glass/miuix_glass_material.dart';
import '../glass/miuix_glass_motion.dart';
import '../glass/miuix_glass_popup_anchor.dart';
import '../glass/miuix_glass_shape.dart';
import '../glass/miuix_glass_style.dart';
import '../glass/internal/animation.dart';
import '../glass/internal/bar_scope.dart';
import '../theme/miuix_theme.dart';
import 'miuix_glass.dart';

/// 对应 Kotlin GlassIconButton；自动继承 OS4 顶栏材质与同步的显隐进度。
class MiuixGlassIconButton extends StatefulWidget {
  const MiuixGlassIconButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backdrop,
    this.anchor,
    this.style,
    this.size,
    this.shape,
    this.surfaceAlpha = 1,
    this.fill,
    this.stroke,
    this.shadow = MiuixGlassShadows.regular,
    this.semanticLabel,
    this.tooltip,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final MiuixBackdrop? backdrop;
  final MiuixGlassPopupAnchor? anchor;
  final MiuixGlassStyle? style;
  final double? size;
  final MiuixGlassShape? shape;
  final double surfaceAlpha;
  final Color? fill;
  final MiuixGlassStroke? stroke;
  final MiuixGlassShadow? shadow;
  final String? semanticLabel, tooltip;
  @override
  State<MiuixGlassIconButton> createState() => _MiuixGlassIconButtonState();
}

class _MiuixGlassIconButtonState extends State<MiuixGlassIconButton> {
  bool _pressed = false, _focused = false;
  @override
  void didUpdateWidget(MiuixGlassIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final scope = GlassBarScope.maybeOf(context),
        theme = MiuixTheme.of(context);
    final dark = theme.colors.background.computeLuminance() < .5;
    final size = widget.size ?? scope?.buttonSize ?? 44;
    final shape = widget.shape ?? MiuixGlassShape(cornerRadius: size / 2);
    final material =
        scope?.material ?? MiuixGlassMaterials.puredThinGlass(dark);
    final backdrop = scope == null ? widget.backdrop : scope.backdrop;
    final alpha = (widget.surfaceAlpha * (scope?.progress ?? 1)).clamp(
      0.0,
      1.0,
    );
    final style =
        widget.style ?? scope?.style ?? MiuixGlassDefaults.style(context);
    final stroke = widget.stroke ?? MiuixGlassStrokes.small(dark);
    final enabled = widget.onPressed != null;
    widget.anchor?.surface = MiuixGlassAnchorSurface(
      backdrop: backdrop,
      style: style,
      material: material,
      underlay: scope?.underlay,
      stroke: stroke,
      fill: widget.fill,
      alpha: alpha,
    );
    Widget button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: GlassSpringBuilder(
            value: _pressed ? MiuixGlassMotion.pressScale(size) : 1,
            spring: _pressed
                ? MiuixGlassMotion.pressDown
                : MiuixGlassMotion.pressUp,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: MiuixGlassPanel(
                      backdrop: backdrop,
                      style: style,
                      shape: shape,
                      material: material,
                      underlayMaterial: scope?.underlay,
                      alpha: alpha,
                      fill: widget.fill,
                      stroke: stroke,
                      shadow: widget.shadow,
                      shading: false,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: shape,
                        color: _pressed
                            ? (dark
                                  ? Colors.white.withValues(alpha: .14)
                                  : Colors.black.withValues(alpha: .10))
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  if (_focused)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(size / 2),
                            side: BorderSide(
                              color: theme.colors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Opacity(
                      opacity: enabled ? (_pressed ? .6 : 1) : .4,
                      child: MiuixContentColor(
                        color: theme.colors.onSurface,
                        child: IconTheme.merge(
                          data: IconThemeData(
                            color: theme.colors.onSurface,
                            size: 24,
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.anchor != null) {
      button = MiuixGlassAnchor(anchor: widget.anchor!, child: button);
    }
    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
