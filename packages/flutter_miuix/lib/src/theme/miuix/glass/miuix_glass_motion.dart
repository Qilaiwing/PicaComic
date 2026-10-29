// Miuix Flutter 移植版 - GlassMotion
// 源自 compose-miuix-ui/miuix 的 GlassMotion.kt、GlassPress.kt。
// SPDX-License-Identifier: Apache-2.0
import 'dart:math' as math;
import 'package:flutter/animation.dart';
import '../theme/miuix_motion.dart';

/// 对应 Kotlin GlassMotion，response 以秒计，stiffness=(2*pi/response)^2。
class MiuixGlassMotion {
  MiuixGlassMotion._();
  static SpringDescription springOf(double damping, double response) {
    if (!response.isFinite ||
        response <= 0 ||
        !damping.isFinite ||
        damping < 0) {
      throw ArgumentError(
        'A glass spring requires finite damping >= 0 and response > 0',
      );
    }
    return folmeSpring(damping: damping, response: response);
  }

  static final navIndicator = springOf(.7, .4);
  static final navIndicatorTrail = springOf(.75, .5);
  static final navDragFollow = springOf(1, .15);
  static final navPressEnter = springOf(1, .2);
  static final navPressExit = springOf(.95, .35);
  static final popupPressExit = springOf(1, .15);
  static final navShowHide = springOf(1, .3);
  static final standard = springOf(.95, .35);
  static final barExpand = springOf(1, .3);
  static final barCollapse = springOf(1, .15);
  static final barTrack = springOf(1, .6);
  static final popupEnter = springOf(.8, .28);
  static final popupExit = springOf(.95, .2);
  static final popupMorph = springOf(.82, .33);
  static final dialogEnter = springOf(.95, .35);
  static final dialogExit = springOf(.95, .15);
  static final pressDown = springOf(.99, .15);
  static final pressUp = springOf(.99, .3);
  static final scaleIn = springOf(.6, .35);
  static final scaleOut = springOf(.75, .2);
  static SpringDescription edgeSpring(bool leading) =>
      leading ? navIndicator : navIndicatorTrail;
  static SpringDescription secondaryPopup(bool entering) =>
      springOf(.95, entering ? .35 : .2);
  static SpringDescription transformBounds(bool entering) =>
      springOf(.8, entering ? .4 : .28);
  static SpringDescription transformCenter(bool entering) =>
      springOf(.8, entering ? .25 : .4);
  static SpringDescription arcBounds(bool entering) =>
      springOf(.8, entering ? .35 : .22);
  static SpringDescription arcPosition(bool entering) =>
      springOf(.8, entering ? .22 : .35);
  static const topBarButtonFloat = Duration(milliseconds: 350);
  static const topBarMask = Duration(milliseconds: 100);
  static const fadeIn = Duration(milliseconds: 80);
  static const fadeOut = Duration(milliseconds: 150);
  static const transformMaterial = Duration(milliseconds: 80);
  static const transformMaterialDelay = Duration(milliseconds: 50);
  static const navShowDelay = Duration(milliseconds: 100);
  static const navContentCurve = Cubic(.33, 0, .67, 1);
  static const navContentDuration = Duration(milliseconds: 150);
  static const transformBlurPx = 50.0;
  static const transformVisibilityThreshold = .0015;
  static const popupStartWidth = .15;
  static const popupStartRatio = .2;
  static const popupStartCorner = 4.0;
  static const popupMorphBlurPx = 40.0;
  static const arcStartWidth = .69;
  static const arcStartRatio = .2;
  static const arcExitBlur = 30.0;
  static const arcVisibleFraction = .1;
  static const navHideScale = .6;
  static const navHideBlur = 18.0;
  static const pressScaleMin = .9;
  static const pressInset = 10.0;
  static double pressScale(double shorterSide) => shorterSide <= 0
      ? 1
      : math.max((shorterSide - pressInset) / shorterSide, pressScaleMin);
}
