// Miuix Flutter 移植版 - GlassStyle（自动生成）
// 源自 compose-miuix-ui/miuix 的 miuix-glass，基准 3f7debbf。
// 由 tool/gen_os4_assets.mjs 生成，请勿手改。
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

/// 对应 Kotlin `GlassStyle`。
@immutable
class MiuixGlassStyle {
  const MiuixGlassStyle({
    required this.blend,
    required this.inner,
    required this.edge,
    required this.reflect,
    required this.light,
    required this.refract,
    required this.background,
    required this.blur,
  });
  final MiuixGlassBlend blend;
  final MiuixGlassInner inner;
  final MiuixGlassEdge edge;
  final MiuixGlassReflect reflect;
  final MiuixGlassLight light;
  final MiuixGlassRefract refract;
  final MiuixGlassBackground background;
  final MiuixGlassBlur blur;
  MiuixGlassStyle copyWith({
    MiuixGlassBlend? blend,
    MiuixGlassInner? inner,
    MiuixGlassEdge? edge,
    MiuixGlassReflect? reflect,
    MiuixGlassLight? light,
    MiuixGlassRefract? refract,
    MiuixGlassBackground? background,
    MiuixGlassBlur? blur,
  }) => MiuixGlassStyle(
    blend: blend ?? this.blend,
    inner: inner ?? this.inner,
    edge: edge ?? this.edge,
    reflect: reflect ?? this.reflect,
    light: light ?? this.light,
    refract: refract ?? this.refract,
    background: background ?? this.background,
    blur: blur ?? this.blur,
  );
}

/// 对应 Kotlin `GlassBlend`。
@immutable
class MiuixGlassBlend {
  const MiuixGlassBlend({
    required this.curveA,
    required this.curveB,
    required this.curveC,
    required this.curveD,
    required this.amount,
    required this.saturation,
    required this.brightness,
    required this.darker,
    required this.darkerStart,
    required this.darkerEnd,
  });
  final double curveA;
  final double curveB;
  final double curveC;
  final double curveD;
  final double amount;
  final double saturation;
  final double brightness;
  final double darker;
  final double darkerStart;
  final double darkerEnd;
  MiuixGlassBlend copyWith({
    double? curveA,
    double? curveB,
    double? curveC,
    double? curveD,
    double? amount,
    double? saturation,
    double? brightness,
    double? darker,
    double? darkerStart,
    double? darkerEnd,
  }) => MiuixGlassBlend(
    curveA: curveA ?? this.curveA,
    curveB: curveB ?? this.curveB,
    curveC: curveC ?? this.curveC,
    curveD: curveD ?? this.curveD,
    amount: amount ?? this.amount,
    saturation: saturation ?? this.saturation,
    brightness: brightness ?? this.brightness,
    darker: darker ?? this.darker,
    darkerStart: darkerStart ?? this.darkerStart,
    darkerEnd: darkerEnd ?? this.darkerEnd,
  );
}

/// 对应 Kotlin `GlassInner`。
@immutable
class MiuixGlassInner {
  const MiuixGlassInner({
    required this.bottom,
    required this.tint,
    required this.tintStrength,
    required this.colorWhite,
    required this.colorMix,
    required this.colorPow,
    required this.alpha,
  });
  final double bottom;
  final Color tint;
  final double tintStrength;
  final double colorWhite;
  final double colorMix;
  final double colorPow;
  final double alpha;
  MiuixGlassInner copyWith({
    double? bottom,
    Color? tint,
    double? tintStrength,
    double? colorWhite,
    double? colorMix,
    double? colorPow,
    double? alpha,
  }) => MiuixGlassInner(
    bottom: bottom ?? this.bottom,
    tint: tint ?? this.tint,
    tintStrength: tintStrength ?? this.tintStrength,
    colorWhite: colorWhite ?? this.colorWhite,
    colorMix: colorMix ?? this.colorMix,
    colorPow: colorPow ?? this.colorPow,
    alpha: alpha ?? this.alpha,
  );
}

/// 对应 Kotlin `GlassEdge`。
@immutable
class MiuixGlassEdge {
  const MiuixGlassEdge({
    required this.width,
    required this.pow,
    required this.thickness,
    required this.reflectOffset,
  });
  final double width;
  final double pow;
  final double thickness;
  final double reflectOffset;
  MiuixGlassEdge copyWith({
    double? width,
    double? pow,
    double? thickness,
    double? reflectOffset,
  }) => MiuixGlassEdge(
    width: width ?? this.width,
    pow: pow ?? this.pow,
    thickness: thickness ?? this.thickness,
    reflectOffset: reflectOffset ?? this.reflectOffset,
  );
}

/// 对应 Kotlin `GlassReflect`。
@immutable
class MiuixGlassReflect {
  const MiuixGlassReflect({required this.lighten, required this.strength});
  final double lighten;
  final double strength;
  MiuixGlassReflect copyWith({double? lighten, double? strength}) =>
      MiuixGlassReflect(
        lighten: lighten ?? this.lighten,
        strength: strength ?? this.strength,
      );
}

/// 对应 Kotlin `GlassLight`。
@immutable
class MiuixGlassLight {
  const MiuixGlassLight({
    required this.directionX,
    required this.directionY,
    required this.directionZ,
    required this.intensity,
    required this.oppositeIntensity,
    required this.angleRange,
  });
  final double directionX;
  final double directionY;
  final double directionZ;
  final double intensity;
  final double oppositeIntensity;
  final double angleRange;
  MiuixGlassLight copyWith({
    double? directionX,
    double? directionY,
    double? directionZ,
    double? intensity,
    double? oppositeIntensity,
    double? angleRange,
  }) => MiuixGlassLight(
    directionX: directionX ?? this.directionX,
    directionY: directionY ?? this.directionY,
    directionZ: directionZ ?? this.directionZ,
    intensity: intensity ?? this.intensity,
    oppositeIntensity: oppositeIntensity ?? this.oppositeIntensity,
    angleRange: angleRange ?? this.angleRange,
  );
}

/// 对应 Kotlin `GlassRefract`。
@immutable
class MiuixGlassRefract {
  const MiuixGlassRefract({required this.ior});
  final double ior;
  MiuixGlassRefract copyWith({double? ior}) =>
      MiuixGlassRefract(ior: ior ?? this.ior);
}

/// 对应 Kotlin `GlassBackground`。
@immutable
class MiuixGlassBackground {
  const MiuixGlassBackground({
    required this.saturation,
    required this.brightness,
    required this.burn,
    required this.unShade,
  });
  final double saturation;
  final double brightness;
  final double burn;
  final double unShade;
  MiuixGlassBackground copyWith({
    double? saturation,
    double? brightness,
    double? burn,
    double? unShade,
  }) => MiuixGlassBackground(
    saturation: saturation ?? this.saturation,
    brightness: brightness ?? this.brightness,
    burn: burn ?? this.burn,
    unShade: unShade ?? this.unShade,
  );
}

/// 对应 Kotlin `GlassBlur`。
@immutable
class MiuixGlassBlur {
  const MiuixGlassBlur({required this.small, required this.big});
  final double small;
  final double big;
  MiuixGlassBlur copyWith({double? small, double? big}) =>
      MiuixGlassBlur(small: small ?? this.small, big: big ?? this.big);
}
