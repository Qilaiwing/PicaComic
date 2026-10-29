// Miuix Flutter 移植版 - GlassStroke / GlassShadow
// 源自 compose-miuix-ui/miuix 的 GlassStroke.kt、GlassShadow.kt。
// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

/// 对应 Kotlin GlassStrokeLight，位置在归一化表面坐标系中。
@immutable
class MiuixGlassStrokeLight {
  const MiuixGlassStrokeLight(this.x, this.y, this.z, this.color);
  final double x, y, z;
  final Color color;
}

/// 对应 Kotlin GlassStroke，宽度/倒角采用逻辑像素。
@immutable
class MiuixGlassStroke {
  const MiuixGlassStroke({
    this.width = .8,
    this.bevel = 1.2,
    required this.color,
    required this.primary,
    required this.secondary,
  });
  final double width, bevel;
  final Color color;
  final MiuixGlassStrokeLight primary, secondary;
}

/// 对应 Kotlin GlassStrokes：六组源端 bloom stroke。
class MiuixGlassStrokes {
  MiuixGlassStrokes._();
  static const bigLight = MiuixGlassStroke(
    color: Color.from(alpha: .1, red: 1, green: 1, blue: 1),
    primary: MiuixGlassStrokeLight(
      .2,
      .5,
      0,
      Color.from(alpha: .6, red: 1, green: 1, blue: 1),
    ),
    secondary: MiuixGlassStrokeLight(
      .5,
      .9,
      -.5,
      Color.from(alpha: .05, red: 1, green: 1, blue: 1),
    ),
  );
  static const middleLight = MiuixGlassStroke(
    color: Color.from(alpha: .1, red: 1, green: 1, blue: 1),
    primary: MiuixGlassStrokeLight(
      .2,
      .5,
      0,
      Color.from(alpha: .5, red: 1, green: 1, blue: 1),
    ),
    secondary: MiuixGlassStrokeLight(
      .7,
      .8,
      0,
      Color.from(alpha: .3, red: 1, green: 1, blue: 1),
    ),
  );
  static const smallLight = MiuixGlassStroke(
    color: Color.from(alpha: .05, red: 1, green: 1, blue: 1),
    primary: MiuixGlassStrokeLight(
      .2,
      .5,
      0,
      Color.from(alpha: .6, red: 1, green: 1, blue: 1),
    ),
    secondary: MiuixGlassStrokeLight(
      .5,
      .95,
      -.5,
      Color.from(alpha: .35, red: 1, green: 1, blue: 1),
    ),
  );
  static const bigDark = MiuixGlassStroke(
    color: Color.from(alpha: .1, red: 1, green: 1, blue: 1),
    primary: MiuixGlassStrokeLight(
      .2,
      .5,
      0,
      Color.from(alpha: .4, red: 1, green: 1, blue: 1),
    ),
    secondary: MiuixGlassStrokeLight(
      .5,
      .9,
      -.5,
      Color.from(alpha: .01, red: 1, green: 1, blue: 1),
    ),
  );
  static const middleDark = MiuixGlassStroke(
    color: Color.from(alpha: .1, red: 1, green: 1, blue: 1),
    primary: MiuixGlassStrokeLight(
      .2,
      .5,
      0,
      Color.from(alpha: .4, red: 1, green: 1, blue: 1),
    ),
    secondary: MiuixGlassStrokeLight(
      .7,
      .8,
      0,
      Color.from(alpha: .2, red: 1, green: 1, blue: 1),
    ),
  );
  static const smallDark = MiuixGlassStroke(
    color: Color.from(alpha: .05, red: 1, green: 1, blue: 1),
    primary: MiuixGlassStrokeLight(
      .2,
      .5,
      0,
      Color.from(alpha: .6, red: 1, green: 1, blue: 1),
    ),
    secondary: MiuixGlassStrokeLight(
      .5,
      .95,
      -.36,
      Color.from(alpha: .25, red: 1, green: 1, blue: 1),
    ),
  );
  static MiuixGlassStroke forTheme(bool isDark) =>
      isDark ? middleDark : middleLight;
  static MiuixGlassStroke small(bool isDark) => isDark ? smallDark : smallLight;
}

/// 对应 Kotlin GlassShadow。位移和 radius 为源端像素，绘制时除以 sourceDensity=3。
@immutable
class MiuixGlassShadow {
  const MiuixGlassShadow({
    this.color = const Color.from(alpha: .05, red: 0, green: 0, blue: 0),
    this.offsetX = 0,
    this.offsetY = 0,
    this.radius = 64,
    this.dispersion = .5,
  });
  final Color color;
  final double offsetX, offsetY, radius, dispersion;
}

/// 对应 Kotlin GlassShadows。
class MiuixGlassShadows {
  MiuixGlassShadows._();
  static const low = MiuixGlassShadow(radius: 44);
  static const regular = MiuixGlassShadow(offsetY: 2);
  static const high = MiuixGlassShadow(offsetY: 4, radius: 80);
  static const extraHigh = MiuixGlassShadow(offsetY: 70, radius: 96);
  static const floating = MiuixGlassShadow(radius: 24);
}
