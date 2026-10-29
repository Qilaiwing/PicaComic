// Miuix Flutter 移植版 - GlassSegmentedTabRow
// 源自 compose-miuix-ui/miuix 的 GlassTabRow.kt（连体式 FilterSortView）。
// SPDX-License-Identifier: Apache-2.0
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../blur/miuix_backdrop.dart';
import '../glass/miuix_glass_decoration.dart';
import '../glass/miuix_glass_material.dart';
import '../glass/miuix_glass_motion.dart';
import '../glass/miuix_glass_shape.dart';
import '../glass/miuix_glass_style.dart';
import '../glass/internal/animation.dart';
import '../glass/internal/bar_scope.dart';
import '../glass/internal/interactive.dart';
import '../theme/miuix_theme.dart';
import '../theme/miuix_text_styles.dart';
import 'miuix_glass.dart';

/// 对应 Kotlin GlassSegmentedTabRowDefaults。
class MiuixGlassSegmentedTabRowDefaults {
  MiuixGlassSegmentedTabRowDefaults._();
  static const height = 40.0,
      trackPadding = 3.0,
      tabGap = 8.0,
      tabPaddingHorizontal = 16.0;
  static Color restingTrackColor(BuildContext context) {
    final c = MiuixTheme.of(context).colors;
    return c.background.computeLuminance() < .5
        ? Color.alphaBlend(Colors.white.withValues(alpha: .133), c.surface)
        : Colors.white;
  }

  static Color indicatorColor(BuildContext context) =>
      MiuixTheme.of(context).colors.background.computeLuminance() < .5
      ? Colors.white.withValues(alpha: .133)
      : Colors.black.withValues(alpha: .06);
}

/// 对应 Kotlin GlassSegmentedTabRow：共用轨道，选中指示器连续移动。
class MiuixGlassSegmentedTabRow extends StatelessWidget {
  const MiuixGlassSegmentedTabRow({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
    this.backdrop,
    this.style,
    this.material,
    this.alpha = 1,
    this.surfaceAlpha = 1,
    this.height = 40,
    this.trackColor,
    this.indicatorColor,
    this.selectedContentColor,
    this.contentColor,
    this.stroke,
    this.shadow = MiuixGlassShadows.floating,
  });
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onSelect;
  final MiuixBackdrop? backdrop;
  final MiuixGlassStyle? style;
  final MiuixGlassMaterial? material;
  final double alpha, surfaceAlpha, height;
  final Color? trackColor, indicatorColor, selectedContentColor, contentColor;
  final MiuixGlassStroke? stroke;
  final MiuixGlassShadow? shadow;
  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();
    final theme = MiuixTheme.of(context),
        scope = GlassBarScope.maybeOf(context);
    final dark = theme.colors.background.computeLuminance() < .5,
        ramp = (surfaceAlpha * (scope?.progress ?? 1)).clamp(0.0, 1.0);
    final selected = selectedIndex.clamp(0, tabs.length - 1),
        shape = MiuixGlassShape(cornerRadius: height / 2, smoothing: 0);
    final fill =
        trackColor ??
        MiuixGlassSegmentedTabRowDefaults.restingTrackColor(context);
    return SizedBox(
      height: height,
      child: MiuixGlassPanel(
        backdrop: scope == null ? backdrop : scope.backdrop,
        style: style ?? scope?.style,
        material:
            material ??
            scope?.material ??
            MiuixGlassMaterials.puredThinGlass(dark),
        underlayMaterial: scope?.underlay,
        shape: shape,
        alpha: (alpha * ramp).clamp(0, 1),
        stroke: stroke ?? MiuixGlassStrokes.forTheme(dark),
        shadow: shadow,
        shading: false,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            color: fill.withValues(alpha: fill.a * (1 - ramp)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = math.min(
                  8.0,
                  constraints.maxWidth / math.max(1, tabs.length - 1),
                );
                final width = math.max(
                  0.0,
                  (constraints.maxWidth - gap * (tabs.length - 1)) /
                      tabs.length,
                );
                final rtl = Directionality.of(context) == TextDirection.rtl;
                return GlassSpringBuilder(
                  value:
                      (rtl ? tabs.length - 1 - selected : selected) *
                      (width + gap),
                  spring: MiuixGlassMotion.standard,
                  builder: (context, left, _) => Stack(
                    children: [
                      Positioned(
                        left: left.clamp(
                          0,
                          math.max(0, constraints.maxWidth - width),
                        ),
                        top: 0,
                        bottom: 0,
                        width: width,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: const StadiumBorder(),
                            color:
                                indicatorColor ??
                                MiuixGlassSegmentedTabRowDefaults.indicatorColor(
                                  context,
                                ),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < tabs.length; i++) ...[
                            if (i > 0) SizedBox(width: gap),
                            Expanded(
                              child: GlassInteractive(
                                selected: i == selected,
                                onTap: onSelect == null
                                    ? null
                                    : () => onSelect!(i),
                                builder: (context, pressed, focused) => DecoratedBox(
                                  decoration: ShapeDecoration(
                                    shape: StadiumBorder(
                                      side: focused
                                          ? BorderSide(
                                              color: theme.colors.primary,
                                              width: 2,
                                            )
                                          : BorderSide.none,
                                    ),
                                    color: pressed
                                        ? theme.colors.onSurface.withValues(
                                            alpha: .05,
                                          )
                                        : Colors.transparent,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration:
                                            MiuixGlassMotion.navContentDuration,
                                        style: DefaultTextStyle.of(context)
                                            .style
                                            .merge(
                                              (i == selected
                                                      ? theme
                                                            .textStyles
                                                            .subtitle
                                                      : theme.textStyles.body2)
                                                  .copyWith(
                                                    color:
                                                        (i == selected
                                                            ? selectedContentColor
                                                            : contentColor) ??
                                                        theme.colors.onSurface,
                                                  )
                                                  .withMiuixWeight(
                                                    theme.fontWeightAdjustment,
                                                  ),
                                            ),
                                        child: Text(
                                          tabs[i],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
