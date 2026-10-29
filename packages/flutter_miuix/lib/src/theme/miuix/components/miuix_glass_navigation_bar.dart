// Miuix Flutter 移植版 - GlassNavigationBar
// 源自 compose-miuix-ui/miuix 的 GlassNavigationBar.kt、NavigationDragTarget.kt。
// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../blur/miuix_backdrop.dart';
import '../foundation/miuix_content_color.dart';
import '../glass/miuix_glass_decoration.dart';
import '../glass/miuix_glass_material.dart';
import '../glass/miuix_glass_motion.dart';
import '../glass/miuix_glass_navigation_geometry.dart';
import '../glass/miuix_glass_shape.dart';
import '../glass/miuix_glass_style.dart';
import '../glass/internal/animation.dart';
import '../glass/internal/interactive.dart';
import '../theme/miuix_theme.dart';
import 'miuix_glass.dart';

/// 对应 Kotlin GlassNavigationItem。
@immutable
class MiuixGlassNavigationItem {
  const MiuixGlassNavigationItem({
    required this.icon,
    this.label,
    this.contentDescription,
    this.isAction = false,
  });
  final Widget icon;
  final String? label, contentDescription;
  final bool isAction;
}

/// 对应 Kotlin GlassNavigationBarDefaults。
class MiuixGlassNavigationBarDefaults {
  MiuixGlassNavigationBarDefaults._();
  static const height = 54.0,
      iconSize = 28.0,
      labelSize = 11.0,
      largeLabelSize = 16.0,
      contentPaddingVertical = 6.0,
      contentPaddingHorizontal = 8.0,
      indicatorPaddingVertical = 3.0,
      indicatorOverhang = 5.0,
      pressedAlpha = .6;
}

/// 对应 Kotlin GlassNavigationBar，支持跨目的地拖动、可中断回弹和自适应双行标签。
class MiuixGlassNavigationBar extends StatefulWidget {
  const MiuixGlassNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.backdrop,
    this.style,
    this.material,
    this.alpha = 1,
    this.visible = true,
    this.height = 54,
    this.shape,
    this.stroke,
    this.shadow = MiuixGlassShadows.floating,
    this.indicatorColor,
    this.indicatorPressedColor,
    this.selectedColor,
    this.unselectedColor,
  });
  final List<MiuixGlassNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final MiuixBackdrop? backdrop;
  final MiuixGlassStyle? style;
  final MiuixGlassMaterial? material;
  final double alpha, height;
  final bool visible;
  final MiuixGlassShape? shape;
  final MiuixGlassStroke? stroke;
  final MiuixGlassShadow? shadow;
  final Color? indicatorColor,
      indicatorPressedColor,
      selectedColor,
      unselectedColor;
  @override
  State<MiuixGlassNavigationBar> createState() =>
      _MiuixGlassNavigationBarState();
}

class _MiuixGlassNavigationBarState extends State<MiuixGlassNavigationBar>
    with TickerProviderStateMixin {
  late final _show = AnimationController.unbounded(
    vsync: this,
    value: widget.visible ? 1 : 0,
  );
  late final _left = AnimationController.unbounded(vsync: this);
  late final _right = AnimationController.unbounded(vsync: this);
  final _key = GlobalKey();
  final _controllers = <AnimationController>[];
  @override
  void initState() {
    super.initState();
    _controllers.addAll([_show, _left, _right]);
  }

  Timer? _timer;
  int? _pointer;
  int? _actionIndex;
  final _pressedIndex = ValueNotifier<int>(-1);
  int get _pressed => _pressedIndex.value;
  set _pressed(int value) => _pressedIndex.value = value;
  double _width = 0;
  late final _indicatorAnimation = Listenable.merge([_left, _right]);
  bool _positioned = false;
  bool get _disabledMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  int get _index => widget.items.isEmpty
      ? 0
      : widget.selectedIndex.clamp(0, widget.items.length - 1);
  double get _slot =>
      (_width - 16).clamp(0.0, double.infinity) /
      math.max(1, widget.items.length);
  bool get _rtl => Directionality.of(context) == TextDirection.rtl;
  double leftOf(int index) =>
      8 + (_rtl ? widget.items.length - 1 - index : index) * _slot - 5;
  void _select(int index) {
    if (!widget.items[index].isAction) {
      _move(leftOf(index), leftOf(index) + _slot + 10);
    }
    widget.onSelect(index);
  }

  void _move(double left, double right) {
    final rightwards = left > _left.value;
    animateGlassTo(
      _left,
      left,
      MiuixGlassMotion.edgeSpring(!rightwards),
      disableAnimations: _disabledMotion,
    );
    animateGlassTo(
      _right,
      right,
      MiuixGlassMotion.edgeSpring(rightwards),
      disableAnimations: _disabledMotion,
    );
  }

  void _follow(double x) {
    final indicatorWidth = _slot + 10;
    final left = (x - indicatorWidth / 2)
        .clamp(0.0, math.max(0.0, _width - indicatorWidth))
        .toDouble();
    _left.value = left;
    _right.value = left + indicatorWidth;
  }

  @override
  void didUpdateWidget(MiuixGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _timer?.cancel();
      void run() {
        if (mounted) {
          animateGlassTo(
            _show,
            widget.visible ? 1 : 0,
            MiuixGlassMotion.navShowHide,
            disableAnimations: _disabledMotion,
          );
        }
      }

      if (widget.visible && !_disabledMotion) {
        _timer = Timer(MiuixGlassMotion.navShowDelay, run);
      } else {
        run();
      }
      if (!widget.visible) {
        _pointer = null;
        _actionIndex = null;
        _pressed = -1;
        _positioned = false;
      }
    }
    if (oldWidget.items.length != widget.items.length) {
      _positioned = false;
      _pointer = null;
      _actionIndex = null;
      _pressed = -1;
    }
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        _pointer == null &&
        _width > 0) {
      _move(leftOf(_index), leftOf(_index) + _slot + 10);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pointer = null;
    _actionIndex = null;
    _pressedIndex.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double _x(Offset global) =>
      (_key.currentContext!.findRenderObject() as RenderBox)
          .globalToLocal(global)
          .dx;
  int _item(double x) {
    final raw = ((x - 8) / math.max(_slot, .01)).floor().clamp(
      0,
      widget.items.length - 1,
    );
    return _rtl ? widget.items.length - 1 - raw : raw;
  }

  void _release({bool commit = false}) {
    if (_pointer == null) return;
    final target = _pressed;
    final actionGesture = _actionIndex != null;
    _pointer = null;
    _actionIndex = null;
    _pressed = -1;
    if (!actionGesture) {
      _move(leftOf(_index), leftOf(_index) + _slot + 10);
    }
    if (commit &&
        widget.visible &&
        target >= 0 &&
        target < widget.items.length &&
        (widget.items[target].isAction || target != _index)) {
      widget.onSelect(target);
    }
  }

  bool _contains(Offset global) {
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    return box.size.contains(box.globalToLocal(global));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final theme = MiuixTheme.of(context),
        dark = theme.colors.background.computeLuminance() < .5;
    final neutral = dark ? Colors.white : Colors.black;
    final fontSize = MediaQuery.textScalerOf(context).scale(1) >= 1.6
        ? 16.0
        : 11.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.items.length * 80.0;
        if (_width != width || !_positioned) {
          _width = width;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || widget.items.isEmpty) return;
            if (!_positioned) {
              _left.value = leftOf(_index);
              _right.value = leftOf(_index) + _slot + 10;
              _positioned = true;
            } else {
              _move(leftOf(_index), leftOf(_index) + _slot + 10);
            }
          });
        }
        final content = SizedBox(
          width: width,
          child: Listener(
            key: _key,
            onPointerDown: (event) {
              if (!widget.visible || _pointer != null) return;
              _pointer = event.pointer;
              _pressed = _item(_x(event.position));
              _actionIndex = widget.items[_pressed].isAction ? _pressed : null;
              if (_actionIndex == null) {
                _move(leftOf(_pressed), leftOf(_pressed) + _slot + 10);
              }
            },
            onPointerMove: (event) {
              if (_pointer != event.pointer) return;
              final x = _x(event.position);
              final target = _item(x);
              if (_actionIndex != null) {
                _pressed = target == _actionIndex ? target : -1;
                return;
              }
              final previous = _pressed;
              _pressed = target;
              if (widget.items[target].isAction) {
                if (previous != target) {
                  _move(leftOf(_index), leftOf(_index) + _slot + 10);
                }
              } else {
                _follow(x);
              }
            },
            onPointerUp: (e) {
              if (_pointer != e.pointer) return;
              final target = _item(_x(e.position));
              _pressed = _actionIndex == null || target == _actionIndex
                  ? target
                  : -1;
              _release(commit: _contains(e.position));
            },
            onPointerCancel: (e) {
              if (_pointer == e.pointer) _release();
            },
            child: MiuixGlassPanel(
              backdrop: widget.backdrop,
              style: widget.style,
              material:
                  widget.material ?? MiuixGlassMaterials.puredThinGlass(dark),
              shape: widget.shape ?? const MiuixGlassShape(cornerRadius: 999),
              alpha: widget.alpha,
              stroke: widget.stroke ?? MiuixGlassStrokes.forTheme(dark),
              shadow: widget.shadow,
              shading: false,
              child: ValueListenableBuilder<int>(
                valueListenable: _pressedIndex,
                builder: (context, pressedIndex, _) {
                  final color =
                      pressedIndex >= 0 && !widget.items[pressedIndex].isAction
                      ? (widget.indicatorPressedColor ??
                            neutral.withValues(alpha: dark ? .26 : .16))
                      : (widget.indicatorColor ??
                            neutral.withValues(alpha: dark ? .12 : .06));
                  return RepaintBoundary(
                    child: IntrinsicHeight(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Stack(
                              children: [
                                AnimatedBuilder(
                                  animation: _indicatorAnimation,
                                  child: AnimatedContainer(
                                    duration:
                                        MiuixGlassMotion.navContentDuration,
                                    decoration: ShapeDecoration(
                                      shape: const StadiumBorder(),
                                      color: color,
                                    ),
                                  ),
                                  builder: (context, child) {
                                    final bounds =
                                        miuixGlassNavigationIndicatorBounds(
                                          _left.value,
                                          _right.value,
                                          width,
                                          3,
                                        );
                                    return Positioned(
                                      left: bounds.dx,
                                      right: math.max(0, width - bounds.dy),
                                      top: 3,
                                      bottom: 3,
                                      child: child!,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: widget.height,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0; i < widget.items.length; i++)
                                    Expanded(
                                      child: GlassInteractive(
                                        selected:
                                            !widget.items[i].isAction &&
                                            i == _index,
                                        label:
                                            widget.items[i].contentDescription,
                                        pointerInput: false,
                                        onTap: () {
                                          if (_pointer == null &&
                                              widget.visible &&
                                              (widget.items[i].isAction ||
                                                  i != _index)) {
                                            _select(i);
                                          }
                                        },
                                        builder: (context, pressed, focused) {
                                          final tint =
                                              (!widget.items[i].isAction &&
                                                      i == _index
                                                  ? widget.selectedColor
                                                  : widget.unselectedColor) ??
                                              theme.colors.onBackground;
                                          return DecoratedBox(
                                            decoration: ShapeDecoration(
                                              shape: StadiumBorder(
                                                side: focused
                                                    ? BorderSide(
                                                        color: theme
                                                            .colors
                                                            .primary,
                                                        width: 2,
                                                      )
                                                    : BorderSide.none,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                    horizontal: 3,
                                                  ),
                                              child: Opacity(
                                                opacity: pressedIndex == i
                                                    ? .6
                                                    : 1,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox.square(
                                                      dimension: 28,
                                                      child: MiuixContentColor(
                                                        color: tint,
                                                        child: IconTheme.merge(
                                                          data: IconThemeData(
                                                            color: tint,
                                                            size: 28,
                                                          ),
                                                          child: widget
                                                              .items[i]
                                                              .icon,
                                                        ),
                                                      ),
                                                    ),
                                                    if (widget.items[i].label !=
                                                        null)
                                                      Text(
                                                        widget.items[i].label!,
                                                        maxLines: 2,
                                                        textAlign:
                                                            TextAlign.center,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textScaler: TextScaler
                                                            .noScaling,
                                                        style: TextStyle(
                                                          fontSize: fontSize,
                                                          color: tint,
                                                          height: 1.2,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        return AnimatedBuilder(
          animation: _show,
          child: content,
          builder: (context, child) {
            final progress = _show.value.clamp(0.0, 1.0);
            if (!widget.visible && progress < .001) {
              return SizedBox(width: width, height: widget.height);
            }
            return IgnorePointer(
              ignoring: !widget.visible,
              child: ExcludeSemantics(
                excluding: !widget.visible,
                child: Opacity(
                  opacity: progress,
                  child: Transform.scale(
                    scale: .6 + .4 * progress,
                    child: ImageFiltered(
                      enabled: progress < .999,
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: (1 - progress) * 18,
                        sigmaY: (1 - progress) * 18,
                      ),
                      child: child!,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
