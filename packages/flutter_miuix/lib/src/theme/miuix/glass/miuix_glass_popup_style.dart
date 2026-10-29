// Miuix Flutter 移植版 - GlassPopupSizing / Visuals / Frame
// 源自 compose-miuix-ui/miuix 的 GlassPopupSurface.kt。
// SPDX-License-Identifier: Apache-2.0
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/widgets.dart';
import 'miuix_glass_decoration.dart';
import 'miuix_glass_material.dart';
import 'miuix_glass_style.dart';

/// 对应 Kotlin GlassPopupDefaults。
class MiuixGlassPopupDefaults {
  MiuixGlassPopupDefaults._();
  static const minWidth = 200.0,
      maxWidth = 288.0,
      maxHeight = 416.0,
      safeMargin = 12.0,
      contentPaddingVertical = 8.0,
      cornerRadius = 24.0,
      itemMinHeight = 44.0,
      itemPaddingHorizontal = 20.0,
      itemPaddingVertical = 10.0,
      itemIconSize = 24.0,
      itemIconGap = 8.0,
      itemPressInset = 7.0,
      itemPressRadius = 15.0,
      dividerPaddingHorizontal = 20.0,
      dividerPaddingVertical = 7.75,
      dividerThickness = .5;
}

/// 对应 Kotlin GlassPopupSizing。
@immutable
class MiuixGlassPopupSizing {
  const MiuixGlassPopupSizing({
    this.minWidth = 200,
    this.maxWidth = 288,
    this.maxHeight = 416,
    this.safeMargin = 12,
  }) : assert(minWidth >= 0),
       assert(maxWidth >= minWidth),
       assert(maxHeight > 0),
       assert(safeMargin >= 0);
  final double minWidth, maxWidth, maxHeight, safeMargin;
}

/// 对应 Kotlin GlassPopupVisuals，null 参数从当前 MiuixTheme 解析。
@immutable
class MiuixGlassPopupVisuals {
  const MiuixGlassPopupVisuals({
    this.style,
    this.alpha = 1,
    this.stroke,
    this.showStroke = true,
    this.shadow = MiuixGlassShadows.floating,
    this.material,
    this.containerColor,
  }) : assert(alpha >= 0 && alpha <= 1);
  final MiuixGlassStyle? style;
  final double alpha;
  final MiuixGlassStroke? stroke;
  final bool showStroke;
  final MiuixGlassShadow? shadow;
  final MiuixGlassMaterial? material;
  final Color? containerColor;
}

/// OS4 三种主菜单开场，以及二级菜单、对话框。
enum MiuixGlassPopupMotion { ordinary, transform, secondary, dropdown, dialog }

/// 对应 Kotlin GlassPopupFrame。
@immutable
class MiuixGlassPopupFrame {
  const MiuixGlassPopupFrame(this.rect, this.cornerRadius);
  final Rect rect;
  final double cornerRadius;
}

/// 上游菜单几何的纯函数移植；[bounds] 为扣除安全区、键盘和 safeMargin 后的范围。
MiuixGlassPopupFrame miuixGlassPopupFrame({
  required MiuixGlassPopupMotion motion,
  required Rect anchor,
  required Size end,
  required Rect bounds,
  required double progress,
  required double positionProgress,
  double cornerRadius = 24,
  double gap = 0,
  EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8),
  TextDirection direction = TextDirection.ltr,
}) {
  double lerp(double a, double b, double p) => lerpDouble(a, b, p)!;
  final rtl = direction == TextDirection.rtl;
  final x = (rtl ? anchor.left : anchor.right - end.width).clamp(
    bounds.left,
    math.max(bounds.left, bounds.right - end.width),
  );
  final below = bounds.bottom - anchor.top, above = anchor.bottom - bounds.top;
  final alignTop = end.height <= below || below >= above;
  final y = ((alignTop ? anchor.top : anchor.bottom - end.height) + gap).clamp(
    bounds.top,
    math.max(bounds.top, bounds.bottom - end.height),
  );
  final settled = Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        end.width,
        end.height,
      ),
      t = progress.clamp(0.0, 1.0);
  if (motion == MiuixGlassPopupMotion.secondary) {
    final left = (rtl ? anchor.right - end.width : anchor.left).clamp(
      bounds.left,
      math.max(bounds.left, bounds.right - end.width),
    );
    final top = anchor.top.clamp(
      bounds.top,
      math.max(bounds.top, bounds.bottom - end.height),
    );
    final target = Rect.fromLTWH(
      left.toDouble(),
      top.toDouble(),
      end.width,
      end.height,
    );
    final start = Rect.fromLTRB(
      anchor.left,
      anchor.top - padding.top,
      anchor.right,
      anchor.bottom + padding.bottom,
    );
    return MiuixGlassPopupFrame(Rect.lerp(start, target, t)!, cornerRadius);
  }
  if (motion == MiuixGlassPopupMotion.dialog) {
    final scale = lerp(.86, 1, progress);
    return MiuixGlassPopupFrame(
      Rect.fromCenter(
        center: bounds.center,
        width: end.width * scale,
        height: end.height * scale,
      ),
      cornerRadius * scale,
    );
  }
  if (motion == MiuixGlassPopupMotion.transform) {
    final width = math.max(.01, lerp(anchor.width, end.width, progress)),
        height = math.max(.01, lerp(anchor.height, end.height, progress));
    final center = Offset.lerp(
      anchor.center,
      settled.center,
      positionProgress,
    )!;
    return MiuixGlassPopupFrame(
      Rect.fromCenter(center: center, width: width, height: height),
      math.max(0, lerp(anchor.shortestSide / 2, cornerRadius, progress)),
    );
  }
  final ratio = end.width > 0 ? end.height / end.width : 1.0;
  if (motion == MiuixGlassPopupMotion.dropdown) {
    final startWidth = end.width * .69, startHeight = startWidth * .2;
    final width = math.max(.01, lerp(startWidth, end.width, progress)),
        height = math.max(.01, width * lerp(.2, ratio, progress));
    final startCenter = Offset(
      rtl ? settled.left + startWidth / 2 : settled.right - startWidth / 2,
      alignTop
          ? settled.top + startHeight / 2
          : settled.bottom - startHeight / 2,
    );
    return MiuixGlassPopupFrame(
      Rect.fromCenter(
        center: Offset.lerp(startCenter, settled.center, positionProgress)!,
        width: width,
        height: height,
      ),
      math.max(0, lerp(4, cornerRadius, progress)),
    );
  }
  final width = end.width * lerp(.15, 1, t),
      height = math.min(end.height, width * lerp(.2, ratio, t));
  return MiuixGlassPopupFrame(
    Rect.fromLTWH(
      rtl ? settled.left : settled.right - width,
      alignTop ? settled.top : settled.bottom - height,
      width,
      height,
    ),
    lerp(4, cornerRadius, t),
  );
}
