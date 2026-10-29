// Miuix Flutter 移植版 - GlassShape
// 源自 compose-miuix-ui/miuix 的 GlassShape.kt。
// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

/// 对应 Kotlin GlassShape。shader 使用连续圆角距离场；普通裁剪同上游使用圆角矩形。
@immutable
class MiuixGlassShape extends OutlinedBorder {
  const MiuixGlassShape({
    this.cornerRadius = 24,
    this.smoothing = 1,
    this.borderRadius,
  }) : assert(cornerRadius >= 0),
       assert(smoothing >= 0 && smoothing <= 1);
  final double cornerRadius;
  final double smoothing;
  final BorderRadiusGeometry? borderRadius;
  BorderRadius resolve(TextDirection direction) =>
      (borderRadius ?? BorderRadius.circular(cornerRadius)).resolve(direction);
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  MiuixGlassShape copyWith({BorderSide? side}) => this;
  @override
  ShapeBorder scale(double t) => MiuixGlassShape(
    cornerRadius: cornerRadius * t,
    smoothing: smoothing,
    borderRadius: borderRadius == null ? null : borderRadius! * t,
  );
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      resolve(textDirection ?? TextDirection.ltr).toRRect(rect).scaleRadii(),
    );
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
}
