// Miuix Flutter 移植版 - NavigationDragTarget
// 源自 compose-miuix-ui/miuix 的 NavigationDragTarget.kt。
// SPDX-License-Identifier: Apache-2.0
import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

/// 对应上游 NavigationDragTarget。跟手拉伸上限为 60 个物理像素，不能当作 60dp。
@immutable
class MiuixGlassNavigationDragTarget {
  const MiuixGlassNavigationDragTarget(
    this.left,
    this.right,
    this.following,
    this.movingRight,
  );
  final double left, right;
  final bool following, movingRight;
}

MiuixGlassNavigationDragTarget miuixGlassNavigationDragTarget({
  required double left,
  required double width,
  required double containerWidth,
  required double delta,
  required bool changedItem,
  double devicePixelRatio = 1,
}) {
  final start = left.clamp(0.0, math.max(0, containerWidth - width)).toDouble(),
      end = start + width;
  final trail = changedItem
      ? 0.0
      : math.min(delta.abs() * 4, 60 / devicePixelRatio);
  return MiuixGlassNavigationDragTarget(
    delta > 0 && end < containerWidth ? start - trail : start,
    delta < 0 && start > 0 ? end + trail : end,
    !changedItem,
    delta > 0,
  );
}

/// 对应上游 navigationIndicatorBounds，限制渲染而不截断弹簧速度。
Offset miuixGlassNavigationIndicatorBounds(
  double left,
  double right,
  double width,
  double inset,
) {
  final min = inset.clamp(0.0, math.max(0, width) / 2),
      max = math.max(min, width - min);
  final start = left.clamp(min, max);
  return Offset(start, right.clamp(start, max));
}
