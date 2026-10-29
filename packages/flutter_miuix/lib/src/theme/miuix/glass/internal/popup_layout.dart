// Miuix Flutter 移植版 - OS4 弹层单次测量与形变布局
// 源自 compose-miuix-ui/miuix 的 GlassPopupSurface.kt。
// SPDX-License-Identifier: Apache-2.0
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../miuix_glass_popup_anchor.dart';
import '../miuix_glass_popup_style.dart';

class GlassPopupLayout extends MultiChildRenderObjectWidget {
  GlassPopupLayout({
    super.key,
    required Widget panel,
    required Widget content,
    Widget? anchorContent,
    required this.motion,
    required this.sizing,
    required this.progress,
    required this.positionProgress,
    required this.cornerRadius,
    required this.insets,
    required this.direction,
    this.anchor,
    this.anchorBounds,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.gap = 0,
    this.interactive = true,
    this.onMeasured,
    this.stackProgress = 0,
    this.maskColor = const Color(0x66000000),
  }) : super(children: [panel, content, if (anchorContent != null) anchorContent]);
  final MiuixGlassPopupMotion motion;
  final MiuixGlassPopupSizing sizing;
  final MiuixGlassPopupAnchor? anchor;
  final Rect? anchorBounds;
  final double progress, positionProgress, cornerRadius, gap, stackProgress;
  final EdgeInsets insets, padding;
  final TextDirection direction;
  final bool interactive;
  final ValueChanged<Size>? onMeasured;
  final Color maskColor;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGlassPopupLayout(this);
  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderGlassPopupLayout).update(this);
}

class _PopupParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderGlassPopupLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PopupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PopupParentData> {
  _RenderGlassPopupLayout(this.data);
  GlassPopupLayout data;
  late MiuixGlassPopupFrame frame;
  Rect anchor = Rect.zero;
  Size? _measured;
  RenderBox get panel => firstChild!;
  RenderBox get content => childAfter(panel)!;
  RenderBox? get copy => childAfter(content);
  Matrix4 get stackTransform => Matrix4.identity()
    ..translateByDouble(frame.rect.center.dx, frame.rect.center.dy, 0, 1)
    ..scaleByDouble(
      1 - .05 * data.stackProgress,
      1 - .05 * data.stackProgress,
      1,
      1,
    )
    ..translateByDouble(-frame.rect.center.dx, -frame.rect.center.dy, 0, 1);
  double get contentScale => data.motion == MiuixGlassPopupMotion.secondary
      ? 1
      : math.min(1, frame.rect.width / math.max(content.size.width, .01));
  Matrix4 get contentTransform => stackTransform
    ..translateByDouble(frame.rect.left, frame.rect.top, 0, 1)
    ..scaleByDouble(contentScale, contentScale, 1, 1);
  Matrix4 get copyTransform {
    final s = frame.rect.width / math.max(anchor.width, .01);
    return stackTransform
      ..translateByDouble(
        frame.rect.center.dx - anchor.width * s / 2,
        frame.rect.center.dy - anchor.height * s / 2,
        0,
        1,
      )
      ..scaleByDouble(s, s, 1, 1);
  }

  void update(GlassPopupLayout value) {
    data = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PopupParentData) {
      child.parentData = _PopupParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final margin = data.sizing.safeMargin;
    final left = math.min(size.width, data.insets.left + margin),
        top = math.min(size.height, data.insets.top + margin);
    final bounds = Rect.fromLTRB(
      left,
      top,
      math.max(left, size.width - data.insets.right - margin),
      math.max(top, size.height - data.insets.bottom - margin),
    );
    final maxWidth = math.min(data.sizing.maxWidth, bounds.width);
    content.layout(
      BoxConstraints(
        minWidth: math.min(data.sizing.minWidth, maxWidth),
        maxWidth: maxWidth,
        maxHeight: math.min(data.sizing.maxHeight, bounds.height),
      ),
      parentUsesSize: true,
    );
    // 锚点在弹出前的帧末采样，不在布局阶段读取另一棵子树的 size。
    final global = data.anchorBounds;
    anchor = global == null
        ? Rect.fromCenter(center: bounds.center, width: 1, height: 1)
        : Rect.fromPoints(
            globalToLocal(global.topLeft),
            globalToLocal(global.bottomRight),
          );
    frame = miuixGlassPopupFrame(
      motion: data.motion,
      anchor: anchor,
      end: content.size,
      bounds: bounds,
      progress: data.progress,
      positionProgress: data.positionProgress,
      cornerRadius: data.cornerRadius,
      gap: data.gap,
      padding: data.padding,
      direction: data.direction,
    );
    panel.layout(BoxConstraints.tight(frame.rect.size), parentUsesSize: true);
    copy?.layout(BoxConstraints.tight(anchor.size), parentUsesSize: true);
    if (_measured != content.size) {
      _measured = content.size;
      final measured = content.size;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (attached) data.onMeasured?.call(measured);
      });
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushTransform(needsCompositing, offset, stackTransform, (
      context,
      offset,
    ) {
      context.paintChild(panel, offset + frame.rect.topLeft);
      context.pushClipRRect(
        needsCompositing,
        offset,
        frame.rect,
        RRect.fromRectAndRadius(
          frame.rect,
          Radius.circular(frame.cornerRadius),
        ),
        (context, offset) {
          final transform = Matrix4.identity()
            ..translateByDouble(frame.rect.left, frame.rect.top, 0, 1)
            ..scaleByDouble(contentScale, contentScale, 1, 1);
          context.pushTransform(
            needsCompositing,
            offset,
            transform,
            (context, offset) => context.paintChild(content, offset),
          );
        },
        clipBehavior: Clip.antiAlias,
      );
      if (data.stackProgress > 0) {
        context.canvas.drawRRect(
          RRect.fromRectAndRadius(
            frame.rect.shift(offset),
            Radius.circular(frame.cornerRadius),
          ),
          Paint()
            ..color = data.maskColor.withValues(
              alpha: data.maskColor.a * data.stackProgress,
            ),
        );
      }
    });
    if (copy != null) {
      context.pushTransform(
        needsCompositing,
        offset,
        copyTransform,
        (context, offset) => context.paintChild(copy!, offset),
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (!data.interactive || !frame.rect.contains(position)) return false;
    return result.addWithPaintTransform(
      transform: contentTransform,
      position: position,
      hitTest: (result, position) =>
          content.hitTest(result, position: position),
    );
  }

  @override
  bool hitTestSelf(Offset position) => frame.rect.contains(position);
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (child == content) {
      transform.multiply(contentTransform);
    } else if (child == copy) {
      transform.multiply(copyTransform);
    } else {
      transform.multiply(
        stackTransform
          ..translateByDouble(frame.rect.left, frame.rect.top, 0, 1),
      );
    }
  }
}


extension _Matrix4Compat on Matrix4 {
  void translateByDouble(double x, double y, double z, [double w = 1.0]) {
    translate(x, y, z);
  }
  void scaleByDouble(double x, double y, double z, [double w = 1.0]) {
    scale(x, y, z);
  }
}
