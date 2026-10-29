// Miuix Flutter 移植版 - OS4 popup lifecycle
// 源自 compose-miuix-ui/miuix 的 GlassPopup / Transform / Secondary / Dropdown / Overlay。
// OverlayPortal 保留调用处主题，返回栈与退出动画同生共灭。
// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../blur/miuix_backdrop.dart';
import '../../components/miuix_glass.dart';
import '../../theme/miuix_theme.dart';
import '../miuix_glass_decoration.dart';
import '../miuix_glass_material.dart';
import '../miuix_glass_motion.dart';
import '../miuix_glass_popup_anchor.dart';
import '../miuix_glass_popup_style.dart';
import '../miuix_glass_shape.dart';
import 'animation.dart';
import 'popup_layout.dart';

class GlassPopupPresenter extends StatefulWidget {
  const GlassPopupPresenter({
    super.key,
    required this.show,
    required this.onDismissRequest,
    required this.child,
    required this.motion,
    this.anchor,
    this.anchorBounds,
    this.materialAnchor,
    this.anchorContent,
    this.backdrop,
    this.sizing = const MiuixGlassPopupSizing(),
    this.visuals = const MiuixGlassPopupVisuals(),
    this.cornerRadius = 24,
    this.gap = 0,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 8),
    this.simplified = false,
    this.stacked = false,
    this.maskColor,
    this.scrimAlpha,
    this.onDismissFinished,
    this.onMeasured,
  });
  final bool show, simplified, stacked;
  final VoidCallback onDismissRequest;
  final VoidCallback? onDismissFinished;
  final ValueChanged<Size>? onMeasured;
  final Widget child;
  final Widget? anchorContent;
  final MiuixGlassPopupMotion motion;
  final MiuixGlassPopupAnchor? anchor, materialAnchor;
  final Rect? anchorBounds;
  final MiuixBackdrop? backdrop;
  final MiuixGlassPopupSizing sizing;
  final MiuixGlassPopupVisuals visuals;
  final double cornerRadius, gap;
  final EdgeInsets contentPadding;
  final Color? maskColor;
  final double? scrimAlpha;
  @override
  State<GlassPopupPresenter> createState() => _GlassPopupPresenterState();
}

class _GlassPopupPresenterState extends State<GlassPopupPresenter>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static final _active = <_GlassPopupPresenterState>[];
  final _portal = OverlayPortalController();
  final _controllers = <AnimationController>[];
  late final _bounds = AnimationController.unbounded(vsync: this)
    ..addListener(_repaint);
  late final _center = AnimationController.unbounded(vsync: this)
    ..addListener(_repaint);
  late final _fade = AnimationController.unbounded(vsync: this)
    ..addListener(_repaint);
  late final _content = AnimationController.unbounded(vsync: this)
    ..addListener(_repaint);
  late final _icon = AnimationController.unbounded(vsync: this)
    ..addListener(_repaint);
  late final _back = AnimationController.unbounded(vsync: this)
    ..addListener(_repaint);
  late final _stack = AnimationController.unbounded(vsync: this)
    ..addListener(_repaint);
  LocalHistoryEntry? _history;
  Rect? _openingAnchorBounds;
  FocusNode? _previousFocus;
  bool _present = false,
      _removingHistory = false,
      _dismissRequested = false,
      _previewing = false;
  int _generation = 0;
  bool get _reduce => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  bool get _hideAnchor =>
      widget.motion == MiuixGlassPopupMotion.transform ||
      widget.motion == MiuixGlassPopupMotion.dropdown;
  void _repaint() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controllers.addAll([
      _bounds,
      _center,
      _fade,
      _content,
      _icon,
      _back,
      _stack,
    ]);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.show) _transition(true);
    });
  }

  @override
  void didUpdateWidget(GlassPopupPresenter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _transition(widget.show);
      });
    }
    if (widget.stacked != oldWidget.stacked) {
      animateGlassTo(
        _stack,
        widget.stacked ? 1 : 0,
        MiuixGlassMotion.secondaryPopup(widget.stacked),
        disableAnimations: _reduce,
      );
    }
  }

  void _removeHistory() {
    _removingHistory = true;
    _history?.remove();
    _history = null;
    _removingHistory = false;
  }

  void _requestDismiss() {
    if (!widget.show || _dismissRequested || widget.stacked) return;
    _dismissRequested = true;
    widget.onDismissRequest();
  }

  Future<void> _linear(
    AnimationController controller,
    double target,
    int milliseconds,
    int generation, {
    int delay = 0,
  }) async {
    if (delay > 0) await Future<void>.delayed(Duration(milliseconds: delay));
    if (!mounted || generation != _generation) return;
    await controller
        .animateTo(
          target,
          duration: Duration(milliseconds: milliseconds),
          curve: Curves.linear,
        )
        .orCancel;
  }

  Future<void> _transition(bool show) async {
    if (!show && !_present) return;
    final generation = ++_generation;
    _dismissRequested = false;
    if (show) {
      _openingAnchorBounds = widget.anchorBounds ?? widget.anchor?.bounds;
      if (!_present) {
        _previousFocus = FocusManager.instance.primaryFocus;
        _portal.show();
        _present = true;
        _active.add(this);
      }
      if (_history == null) {
        _history = LocalHistoryEntry(
          onRemove: () {
            _history = null;
            if (!_removingHistory) _requestDismiss();
          },
        );
        ModalRoute.of(context)?.addLocalHistoryEntry(_history!);
      }
      if (_hideAnchor) widget.anchor?.contentHidden = true;
    } else {
      _removeHistory();
    }
    final target = show ? 1.0 : 0.0, kind = widget.motion;
    if (_reduce) {
      for (final c in [_bounds, _center, _fade, _content, _icon]) {
        c.value = target;
      }
      if (!show) _finish();
      return;
    }
    final boundsSpring = switch (kind) {
      MiuixGlassPopupMotion.transform => MiuixGlassMotion.transformBounds(show),
      MiuixGlassPopupMotion.dropdown => MiuixGlassMotion.arcBounds(show),
      MiuixGlassPopupMotion.secondary => MiuixGlassMotion.secondaryPopup(show),
      MiuixGlassPopupMotion.dialog =>
        show ? MiuixGlassMotion.dialogEnter : MiuixGlassMotion.dialogExit,
      _ => MiuixGlassMotion.popupMorph,
    };
    final centerSpring = switch (kind) {
      MiuixGlassPopupMotion.transform => MiuixGlassMotion.transformCenter(show),
      MiuixGlassPopupMotion.dropdown => MiuixGlassMotion.arcPosition(show),
      _ => boundsSpring,
    };
    final boundsDone = animateGlassTo(_bounds, target, boundsSpring).orCancel;
    final centerDone = animateGlassTo(_center, target, centerSpring).orCancel;
    try {
      await Future.wait([
        boundsDone,
        centerDone,
        _linear(
          _fade,
          target,
          kind == MiuixGlassPopupMotion.dropdown
              ? (show ? 50 : 200)
              : (kind == MiuixGlassPopupMotion.dialog
                    ? (show ? 80 : 150)
                    : (show ? 200 : 150)),
          generation,
        ),
        _linear(
          _content,
          target,
          kind == MiuixGlassPopupMotion.transform ? 80 : 200,
          generation,
          delay: kind == MiuixGlassPopupMotion.transform && show ? 50 : 0,
        ),
        _linear(
          _icon,
          target,
          80,
          generation,
          delay: kind == MiuixGlassPopupMotion.transform && !show ? 50 : 0,
        ),
      ]);
      if (mounted && generation == _generation && !widget.show) _finish();
    } on TickerCanceled {
      /* Reversal/disposal owns the next completion. */
    }
  }

  void _finish() {
    if (!_present) return;
    final wasTop = _active.isNotEmpty && _active.last == this;
    _portal.hide();
    _present = false;
    _active.remove(this);
    if (_hideAnchor) widget.anchor?.contentHidden = false;
    if (wasTop && (_previousFocus?.context?.mounted ?? false)) {
      _previousFocus?.requestFocus();
    }
    widget.onDismissFinished?.call();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (!_present ||
        !widget.show ||
        widget.stacked ||
        _active.isEmpty ||
        _active.last != this) {
      return false;
    }
    _previewing = true;
    _back.stop();
    _back.value = backEvent.progress;
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (_previewing) _back.value = backEvent.progress.clamp(0, 1);
  }

  @override
  void handleCancelBackGesture() {
    if (!_previewing) return;
    _previewing = false;
    animateGlassTo(
      _back,
      0,
      MiuixGlassMotion.secondaryPopup(true),
      disableAnimations: _reduce,
    );
  }

  @override
  void handleCommitBackGesture() {
    if (!_previewing) return;
    _previewing = false;
    final remaining = 1 - _back.value;
    _bounds.value *= remaining;
    _center.value *= remaining;
    _content.value *= remaining;
    _icon.value *= remaining;
    _back.value = 0;
    _requestDismiss();
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _removeHistory();
    _active.remove(this);
    if (_hideAnchor && widget.anchor != null) {
      final anchor = widget.anchor!;
      // 不在父级销毁过程中通知锚点；所属按钮也将随路由一同卸载。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        anchor.contentHidden = false;
      });
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _overlay(BuildContext context) {
    final c = MiuixTheme.of(context).colors,
        dark = c.background.computeLuminance() < .5;
    final kind = widget.motion, v = widget.visuals;
    final source = (widget.materialAnchor ?? widget.anchor)?.surface;
    final dpr = MediaQuery.devicePixelRatioOf(context),
        viewPadding = MediaQuery.viewPaddingOf(context),
        back = 1 - _back.value.clamp(0, 1);
    final progress = _bounds.value * back, position = _center.value * back;
    final fade = _fade.value.clamp(0.0, 1.0) * back,
        content = _content.value.clamp(0.0, 1.0) * back;
    final icon = _icon.value.clamp(0.0, 1.0) * back;
    final isTransform = kind == MiuixGlassPopupMotion.transform,
        isSecondary = kind == MiuixGlassPopupMotion.secondary;
    final scrim = kind == MiuixGlassPopupMotion.dialog
        ? (widget.scrimAlpha ?? (dark ? .6 : .3)) * fade
        : 0.0;
    final inherited = source != null && (isTransform || isSecondary);
    final radius = switch (kind) {
      MiuixGlassPopupMotion.transform => ui.lerpDouble(
        (_openingAnchorBounds?.shortestSide ?? 48) / 2,
        widget.cornerRadius,
        progress,
      )!,
      MiuixGlassPopupMotion.ordinary || MiuixGlassPopupMotion.dropdown =>
        ui.lerpDouble(4, widget.cornerRadius, progress)!,
      _ => widget.cornerRadius,
    };
    final panelAlpha =
        kind == MiuixGlassPopupMotion.dropdown &&
            widget.show &&
            progress <= MiuixGlassMotion.arcVisibleFraction
        ? 0.0
        : isTransform
        ? ui.lerpDouble(source?.alpha ?? 1, 1, icon)!.clamp(0.0, 1.0)
        : (kind == MiuixGlassPopupMotion.dropdown ||
                  kind == MiuixGlassPopupMotion.dialog
              ? fade
              : 1.0);
    final blur = isTransform
        ? (1 - content) * 50 / dpr
        : isSecondary
        ? 0.0
        : kind == MiuixGlassPopupMotion.dropdown
        ? (widget.show ? 0.0 : (1 - fade) * 30)
        : kind == MiuixGlassPopupMotion.dialog
        ? 0.0
        : (1 - content) * 40 / dpr;
    Widget rows = SingleChildScrollView(
      primary: false,
      child: Padding(padding: widget.contentPadding, child: widget.child),
    );
    rows = Opacity(
      opacity: isSecondary
          ? 1
          : isTransform
          ? content
          : fade,
      child: ImageFiltered(
        enabled: blur > .01,
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: rows,
      ),
    );
    final interactive = widget.show && !widget.stacked;
    rows = ExcludeFocus(
      excluding: !interactive,
      child: ExcludeSemantics(excluding: !interactive, child: rows),
    );

    Widget? copy;
    if (isTransform &&
        widget.anchorContent != null &&
        (!widget.simplified || !widget.show || _previewing) &&
        icon < .999) {
      final blur = 50 * icon / dpr;
      copy = ExcludeSemantics(
        child: IgnorePointer(
          child: Opacity(
            opacity: 1 - icon,
            child: ImageFiltered(
              enabled: blur > .01,
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blur,
                sigmaY: blur,
                tileMode: TileMode.decal,
              ),
              child: widget.anchorContent!,
            ),
          ),
        ),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _requestDismiss,
        },
        child: FocusScope(
          autofocus: true,
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    label: MaterialLocalizations.of(
                      context,
                    ).modalBarrierDismissLabel,
                    button: true,
                    onTap: _requestDismiss,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      onTap: _requestDismiss,
                      child: ColoredBox(
                        color: Colors.black.withValues(
                          alpha: scrim.clamp(0, 1),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GlassPopupLayout(
                    motion: kind,
                    sizing: widget.sizing,
                    anchor: widget.anchor,
                    anchorBounds: widget.anchorBounds ?? _openingAnchorBounds,
                    progress: progress,
                    positionProgress: position,
                    cornerRadius: widget.cornerRadius,
                    gap: widget.gap,
                    padding: widget.contentPadding,
                    direction: Directionality.of(context),
                    interactive: widget.show && !widget.stacked,
                    insets: EdgeInsets.fromLTRB(
                      viewPadding.left,
                      viewPadding.top,
                      viewPadding.right,
                      math.max(
                        viewPadding.bottom,
                        MediaQuery.viewInsetsOf(context).bottom,
                      ),
                    ),
                    stackProgress: _stack.value.clamp(0, 1),
                    maskColor:
                        widget.maskColor ??
                        (dark ? Colors.black : Colors.white).withValues(
                          alpha: .4,
                        ),
                    onMeasured: (size) {
                      if (mounted) widget.onMeasured?.call(size);
                    },
                    panel: Opacity(
                      opacity: panelAlpha,
                      child: MiuixGlassPanel(
                        backdrop: inherited
                            ? (isTransform
                                  ? source.backdrop
                                  : (widget.backdrop ?? source.backdrop))
                            : widget.backdrop,
                        style: inherited ? source.style : v.style,
                        material: inherited
                            ? source.material
                            : (kind == MiuixGlassPopupMotion.dialog
                                  ? v.material
                                  : (v.material ??
                                        MiuixGlassMaterials.popupViewGlass(
                                          dark,
                                        ))),
                        underlayMaterial: inherited ? source.underlay : null,
                        shape: MiuixGlassShape(
                          cornerRadius: math.max(0, radius),
                        ),
                        alpha: v.alpha,
                        stroke: !v.showStroke
                            ? null
                            : inherited
                            ? source.stroke
                            : (v.stroke ?? MiuixGlassStrokes.forTheme(dark)),
                        shadow: v.shadow,
                        fill: inherited ? source.fill : v.containerColor,
                        shading: kind == MiuixGlassPopupMotion.dialog,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    content: rows,
                    anchorContent: copy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    
    controller: _portal,
    overlayChildBuilder: _overlay,
    child: const SizedBox.shrink(),
  );
}

/// Internal adapter shared by the public, separately named OS4 components.
class GlassPopupWidget extends StatelessWidget {
  const GlassPopupWidget({
    super.key,
    required this.show,
    required this.onDismissRequest,
    required this.child,
    required this.motion,
    this.anchor,
    this.anchorBounds,
    this.materialAnchor,
    this.anchorContent,
    this.backdrop,
    this.sizing = const MiuixGlassPopupSizing(),
    this.visuals = const MiuixGlassPopupVisuals(),
    this.cornerRadius = 24,
    this.gap = 0,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 8),
    this.simplified = false,
    this.stacked = false,
    this.maskColor,
    this.scrimAlpha,
    this.onDismissFinished,
    this.onMeasured,
  }) : assert(
         motion == MiuixGlassPopupMotion.dialog ||
             anchor != null ||
             anchorBounds != null,
       );
  final bool show, simplified, stacked;
  final VoidCallback onDismissRequest;
  final VoidCallback? onDismissFinished;
  final ValueChanged<Size>? onMeasured;
  final Widget child;
  final Widget? anchorContent;
  final MiuixGlassPopupMotion motion;
  final MiuixGlassPopupAnchor? anchor, materialAnchor;
  final Rect? anchorBounds;
  final MiuixBackdrop? backdrop;
  final MiuixGlassPopupSizing sizing;
  final MiuixGlassPopupVisuals visuals;
  final double cornerRadius, gap;
  final EdgeInsets contentPadding;
  final Color? maskColor;
  final double? scrimAlpha;
  @override
  Widget build(BuildContext context) => GlassPopupPresenter(
    show: show,
    onDismissRequest: onDismissRequest,
    motion: motion,
    anchor: anchor,
    anchorBounds: anchorBounds,
    materialAnchor: materialAnchor,
    anchorContent: anchorContent,
    backdrop: backdrop,
    sizing: sizing,
    visuals: visuals,
    cornerRadius: cornerRadius,
    gap: gap,
    contentPadding: contentPadding,
    simplified: simplified,
    stacked: stacked,
    maskColor: maskColor,
    scrimAlpha: scrimAlpha,
    onDismissFinished: onDismissFinished,
    onMeasured: onMeasured,
    child: child,
  );
}
