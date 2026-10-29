// Miuix Flutter 移植版 - GlassTopAppBarContext
// 源自 compose-miuix-ui/miuix 的 GlassTopAppBar.kt。
// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/widgets.dart';
import '../../blur/miuix_backdrop.dart';
import '../miuix_glass_material.dart';
import '../miuix_glass_style.dart';

class GlassBarScope extends InheritedWidget {
  const GlassBarScope({
    super.key,
    required this.backdrop,
    required this.material,
    required this.underlay,
    required this.style,
    required this.progress,
    required this.buttonSize,
    required super.child,
  });
  final MiuixBackdrop? backdrop;
  final MiuixGlassMaterial material, underlay;
  final MiuixGlassStyle style;
  final double progress, buttonSize;
  static GlassBarScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassBarScope>();
  @override
  bool updateShouldNotify(GlassBarScope oldWidget) =>
      backdrop != oldWidget.backdrop ||
      material != oldWidget.material ||
      underlay != oldWidget.underlay ||
      style != oldWidget.style ||
      progress != oldWidget.progress ||
      buttonSize != oldWidget.buttonSize;
}
