// App-side replacement of flutter_miuix's MiuixTooltipBox (same API).
// Fixes vs. the package version (the submodule is intentionally untouched):
//  * never calls OverlayEntry.markNeedsBuild() synchronously from
//    didUpdateWidget (that ran during the parent's build and triggered
//    "setState() or markNeedsBuild() called during build ... _OverlayEntryWidget");
//  * removes the overlay immediately when the anchor is deactivated/disposed
//    or its route stops ticking (covered by a pushed page). Previously the
//    hide animation was muted by TickerMode, so the bubble stayed stuck on
//    top of the next page;
//  * the CurvedAnimations are created once instead of on every overlay build.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_miuix/miuix.dart' hide MiuixTooltipBox;

class MiuixTooltipBox extends StatefulWidget {
  const MiuixTooltipBox({
    super.key,
    required this.tooltip,
    required this.child,
    this.state,
    this.positioning = MiuixTooltipAnchorPosition.below,
    this.spacing = MiuixTooltipDefaults.spacingBetweenTooltipAndAnchor,
    this.focusable = false,
    this.enableUserInput = true,
    this.semanticLabel = '显示提示',
  });

  final Widget Function(BuildContext context, MiuixTooltipScope scope) tooltip;
  final Widget child;
  final MiuixTooltipState? state;
  final MiuixTooltipAnchorPosition positioning;
  final double spacing;
  final bool focusable;
  final bool enableUserInput;
  final String semanticLabel;

  @override
  State<MiuixTooltipBox> createState() => _MiuixTooltipBoxState();
}

class _MiuixTooltipBoxState extends State<MiuixTooltipBox>
    with SingleTickerProviderStateMixin {
  late MiuixTooltipState _state;
  late bool _ownsState;
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  OverlayEntry? _entry;
  LocalHistoryEntry? _historyEntry;
  bool _hoveringAnchor = false;
  bool _hoveringTooltip = false;
  bool _rebuildScheduled = false;

  @override
  void initState() {
    super.initState();
    _setState(widget.state);
    _controller = AnimationController(
      vsync: this,
      duration: MiuixTooltipDefaults.animationDuration,
      reverseDuration: MiuixTooltipDefaults.animationDuration,
    )..addStatusListener(_onAnimationStatus);
    _opacity = CurvedAnimation(
        parent: _controller, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.9, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _state.isVisible) _syncVisibility();
    });
  }

  void _setState(MiuixTooltipState? value) {
    _ownsState = value == null;
    _state = value ?? MiuixTooltipState();
    _state.addListener(_syncVisibility);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route covered by another page (or otherwise muted): hide right away,
    // the reverse animation would never run while tickers are disabled.
    if (!TickerMode.of(context) && _entry != null) {
      _hideNow();
    }
  }

  @override
  void didUpdateWidget(MiuixTooltipBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state, widget.state)) {
      _state.removeListener(_syncVisibility);
      if (_ownsState) _state.dispose();
      _setState(widget.state);
      _scheduleSync();
    } else if (_entry != null) {
      _scheduleEntryRebuild();
    }
  }

  void _scheduleSync() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _syncVisibility());
  }

  void _scheduleEntryRebuild() {
    if (_rebuildScheduled) return;
    _rebuildScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (mounted) _entry?.markNeedsBuild();
    });
  }

  void _syncVisibility() {
    if (!mounted) return;
    if (_state.isVisible) {
      if (!TickerMode.of(context)) {
        _state.dismiss();
        return;
      }
      _showOverlay();
      _controller.forward();
    } else {
      _removeHistoryEntry();
      if (_entry == null) return;
      if (TickerMode.of(context)) {
        _controller.reverse();
      } else {
        _removeEntry();
      }
    }
  }

  void _hideNow() {
    if (_state.isVisible) {
      _state.removeListener(_syncVisibility);
      _state.dismiss();
      _state.addListener(_syncVisibility);
    }
    _removeHistoryEntry();
    _removeEntry();
  }

  void _removeEntry() {
    final entry = _entry;
    _entry = null;
    _controller.stop();
    _controller.value = 0;
    if (entry != null && entry.mounted) entry.remove();
  }

  void _showOverlay() {
    if (_entry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final anchorBox = context.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (anchorBox == null || overlayBox == null || !anchorBox.hasSize) return;
    final topLeft = anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchor = topLeft & anchorBox.size;
    final theme = MiuixTheme.of(context);
    final direction = Directionality.of(context);
    final actualPosition = ValueNotifier<MiuixTooltipAnchorPosition>(
      _resolvePosition(widget.positioning, direction),
    );

    _entry = OverlayEntry(
      builder: (overlayContext) => MiuixTheme(
        data: theme,
        // Overlay entries sit outside any Material: without this the text
        // falls back to the debug style (yellow double underline).
        child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
        style: theme.textStyles.body2,
        child: Directionality(
          textDirection: direction,
          child: Stack(
            children: [
              if (widget.focusable)
                Positioned.fill(
                  child: Semantics(
                    button: true,
                    label: '关闭提示',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _state.dismiss,
                    ),
                  ),
                ),
              CustomSingleChildLayout(
                delegate: _MiuixTooltipPositionDelegate(
                  anchor: anchor,
                  preferred: widget.positioning,
                  spacing: widget.spacing,
                  textDirection: direction,
                  actualPosition: actualPosition,
                ),
                child: FadeTransition(
                  opacity: _opacity,
                  child: ScaleTransition(
                    scale: _scale,
                    child: MouseRegion(
                      onEnter: (_) => _hoveringTooltip = true,
                      onExit: (_) {
                        _hoveringTooltip = false;
                        if (!_hoveringAnchor && !_state.isPersistent) {
                          _state.dismiss();
                        }
                      },
                      child: Semantics(
                        liveRegion: true,
                        container: true,
                        label: '提示',
                        child:
                            ValueListenableBuilder<MiuixTooltipAnchorPosition>(
                          valueListenable: actualPosition,
                          builder: (context, position, _) => widget.tooltip(
                            context,
                            MiuixTooltipScope(
                              positioning: position,
                              anchorBounds: anchor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ))),
      ),
    );
    overlay.insert(_entry!);
    if (widget.focusable) {
      _historyEntry = LocalHistoryEntry(onRemove: _state.dismiss);
      ModalRoute.of(context)?.addLocalHistoryEntry(_historyEntry!);
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_state.isVisible) {
      final entry = _entry;
      _entry = null;
      if (entry != null && entry.mounted) entry.remove();
    }
  }

  void _removeHistoryEntry() {
    final entry = _historyEntry;
    _historyEntry = null;
    entry?.remove();
  }

  @override
  void deactivate() {
    // Anchor leaves the tree (route popped / subtree replaced): the overlay
    // entry must not outlive it.
    _hideNow();
    super.deactivate();
  }

  @override
  void dispose() {
    _state.removeListener(_syncVisibility);
    if (_ownsState) _state.dispose();
    _removeHistoryEntry();
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
    _controller
      ..removeStatusListener(_onAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;
    if (widget.enableUserInput) {
      result = MouseRegion(
        onEnter: (_) {
          _hoveringAnchor = true;
          _state.show();
        },
        onExit: (_) {
          _hoveringAnchor = false;
          scheduleMicrotask(() {
            if (!_hoveringTooltip && !_state.isPersistent) _state.dismiss();
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          excludeFromSemantics: true,
          onLongPress: _state.show,
          // A new touch means the user is activating the control (often
          // pushing a route): never leave a bubble behind. Listener does not
          // take part in the gesture arena, so the child's taps are intact.
          child: Listener(
            onPointerDown: (_) {
              if (_state.isVisible) _state.dismiss();
            },
            child: result,
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      onLongPress: widget.enableUserInput ? _state.show : null,
      onLongPressHint: widget.enableUserInput ? widget.semanticLabel : null,
      child: result,
    );
  }
}

class _MiuixTooltipPositionDelegate extends SingleChildLayoutDelegate {
  _MiuixTooltipPositionDelegate({
    required this.anchor,
    required this.preferred,
    required this.spacing,
    required this.textDirection,
    required this.actualPosition,
  });

  final Rect anchor;
  final MiuixTooltipAnchorPosition preferred;
  final double spacing;
  final TextDirection textDirection;
  final ValueNotifier<MiuixTooltipAnchorPosition> actualPosition;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final resolved = _resolvePosition(preferred, textDirection);
    final opposite = _opposite(resolved);
    final selected = _fits(resolved, size, childSize) ||
            !_fits(opposite, size, childSize)
        ? resolved
        : opposite;
    if (actualPosition.value != selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (actualPosition.value != selected) actualPosition.value = selected;
      });
    }

    double x = anchor.center.dx - childSize.width / 2;
    double y = anchor.center.dy - childSize.height / 2;
    switch (selected) {
      case MiuixTooltipAnchorPosition.above:
        y = anchor.top - childSize.height - spacing;
      case MiuixTooltipAnchorPosition.below:
        y = anchor.bottom + spacing;
      case MiuixTooltipAnchorPosition.left:
        x = anchor.left - childSize.width - spacing;
      case MiuixTooltipAnchorPosition.right:
        x = anchor.right + spacing;
      case MiuixTooltipAnchorPosition.start:
      case MiuixTooltipAnchorPosition.end:
        break;
    }
    return Offset(
      x.clamp(0.0, (size.width - childSize.width).clamp(0.0, size.width)),
      y.clamp(0.0, (size.height - childSize.height).clamp(0.0, size.height)),
    );
  }

  bool _fits(MiuixTooltipAnchorPosition side, Size area, Size child) {
    return switch (side) {
      MiuixTooltipAnchorPosition.above =>
        anchor.top - spacing >= child.height,
      MiuixTooltipAnchorPosition.below =>
        area.height - anchor.bottom - spacing >= child.height,
      MiuixTooltipAnchorPosition.left =>
        anchor.left - spacing >= child.width,
      MiuixTooltipAnchorPosition.right =>
        area.width - anchor.right - spacing >= child.width,
      MiuixTooltipAnchorPosition.start || MiuixTooltipAnchorPosition.end => false,
    };
  }

  @override
  bool shouldRelayout(_MiuixTooltipPositionDelegate oldDelegate) =>
      anchor != oldDelegate.anchor ||
      preferred != oldDelegate.preferred ||
      spacing != oldDelegate.spacing ||
      textDirection != oldDelegate.textDirection;
}

MiuixTooltipAnchorPosition _resolvePosition(
  MiuixTooltipAnchorPosition position,
  TextDirection direction,
) {
  if (position == MiuixTooltipAnchorPosition.start) {
    return direction == TextDirection.ltr
        ? MiuixTooltipAnchorPosition.left
        : MiuixTooltipAnchorPosition.right;
  }
  if (position == MiuixTooltipAnchorPosition.end) {
    return direction == TextDirection.ltr
        ? MiuixTooltipAnchorPosition.right
        : MiuixTooltipAnchorPosition.left;
  }
  return position;
}

MiuixTooltipAnchorPosition _opposite(MiuixTooltipAnchorPosition position) {
  return switch (position) {
    MiuixTooltipAnchorPosition.above => MiuixTooltipAnchorPosition.below,
    MiuixTooltipAnchorPosition.below => MiuixTooltipAnchorPosition.above,
    MiuixTooltipAnchorPosition.left => MiuixTooltipAnchorPosition.right,
    MiuixTooltipAnchorPosition.right => MiuixTooltipAnchorPosition.left,
    MiuixTooltipAnchorPosition.start => MiuixTooltipAnchorPosition.end,
    MiuixTooltipAnchorPosition.end => MiuixTooltipAnchorPosition.start,
  };
}
