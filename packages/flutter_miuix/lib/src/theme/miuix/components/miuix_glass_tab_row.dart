// Miuix Flutter 移植版 - GlassTabRow
// 源自 compose-miuix-ui/miuix 的 GlassTabRow.kt（分离式 FilterSortView2）。
// SPDX-License-Identifier: Apache-2.0
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

/// 对应 Kotlin GlassTabColors。
@immutable
class MiuixGlassTabColors {
  const MiuixGlassTabColors({
    required this.selectedContainerColor,
    required this.selectedContentColor,
    required this.restingContainerColor,
    required this.containerColor,
    required this.contentColor,
    required this.pressedOverlayColor,
    required this.restingStrokeAlpha,
  });
  final Color selectedContainerColor,
      selectedContentColor,
      restingContainerColor,
      containerColor,
      contentColor,
      pressedOverlayColor;
  final double restingStrokeAlpha;
}

/// 对应 Kotlin GlassTabRowDefaults。
class MiuixGlassTabRowDefaults {
  MiuixGlassTabRowDefaults._();
  static const height = 40.0,
      neutralHeight = 35.0,
      tabGap = 12.0,
      tabPaddingHorizontal = 16.0,
      tabPaddingVertical = 6.0;
  static MiuixGlassTabColors primaryColors(BuildContext context) {
    final c = MiuixTheme.of(context).colors,
        dark = c.background.computeLuminance() < .5;
    return MiuixGlassTabColors(
      selectedContainerColor: c.primary,
      selectedContentColor: Colors.white.withValues(alpha: dark ? .8 : 1),
      restingContainerColor: dark
          ? Color.alphaBlend(Colors.white.withValues(alpha: .067), c.surface)
          : Colors.white,
      containerColor: Colors.transparent,
      contentColor: dark
          ? Colors.white.withValues(alpha: .5)
          : Colors.black.withValues(alpha: .6),
      pressedOverlayColor: dark
          ? Colors.white.withValues(alpha: .16)
          : Colors.black.withValues(alpha: .05),
      restingStrokeAlpha: 1,
    );
  }

  static MiuixGlassTabColors neutralColors(BuildContext context) {
    final c = MiuixTheme.of(context).colors,
        dark = c.background.computeLuminance() < .5;
    return MiuixGlassTabColors(
      selectedContainerColor: dark
          ? const Color(0xFFE6E6E6)
          : const Color(0xFF383838),
      selectedContentColor: dark ? Colors.black : Colors.white,
      restingContainerColor: Color.alphaBlend(
        (dark ? Colors.white : Colors.black).withValues(alpha: .06),
        c.surface,
      ),
      containerColor: Colors.transparent,
      contentColor: c.onSurface,
      pressedOverlayColor: dark
          ? Colors.white.withValues(alpha: .16)
          : Colors.black.withValues(alpha: .05),
      restingStrokeAlpha: 0,
    );
  }
}

/// 对应 Kotlin GlassTabRow：每个标签是独立胶囊，无跨标签滑动指示器。
class MiuixGlassTabRow extends StatelessWidget {
  const MiuixGlassTabRow({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
    this.backdrop,
    this.style,
    this.material,
    this.colors,
    this.alpha = 1,
    this.surfaceAlpha = 1,
    this.height = 40,
    this.tabGap = 12,
    this.stroke,
    this.shadow = MiuixGlassShadows.floating,
  });
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onSelect;
  final MiuixBackdrop? backdrop;
  final MiuixGlassStyle? style;
  final MiuixGlassMaterial? material;
  final MiuixGlassTabColors? colors;
  final double alpha, surfaceAlpha, height, tabGap;
  final MiuixGlassStroke? stroke;
  final MiuixGlassShadow? shadow;
  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();
    final theme = MiuixTheme.of(context),
        scope = GlassBarScope.maybeOf(context);
    final c = colors ?? MiuixGlassTabRowDefaults.primaryColors(context);
    final dark = theme.colors.background.computeLuminance() < .5;
    final ramp = (surfaceAlpha * (scope?.progress ?? 1)).clamp(0.0, 1.0);
    final shape = MiuixGlassShape(cornerRadius: height / 2, smoothing: 0),
        rim = stroke ?? MiuixGlassStrokes.forTheme(dark);
    final selected = selectedIndex.clamp(0, tabs.length - 1);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) SizedBox(width: tabGap),
            Expanded(
              child: GlassInteractive(
                selected: i == selected,
                onTap: onSelect == null ? null : () => onSelect!(i),
                builder: (context, pressed, focused) => GlassSpringBuilder(
                  value: pressed ? 1 : 0,
                  spring: pressed
                      ? MiuixGlassMotion.navPressEnter
                      : MiuixGlassMotion.navPressExit,
                  builder: (context, p, _) => Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      MiuixGlassPanel(
                        backdrop: scope == null ? backdrop : scope.backdrop,
                        style: style ?? scope?.style,
                        shape: shape,
                        alpha: (alpha * ramp).clamp(0, 1),
                        material:
                            material ??
                            scope?.material ??
                            MiuixGlassMaterials.puredThinGlass(dark),
                        underlayMaterial: scope?.underlay,
                        stroke: rim,
                        shadow: shadow,
                        shading: false,
                        child: const SizedBox.expand(),
                      ),
                      AnimatedContainer(
                        duration: MiuixGlassMotion.navContentDuration,
                        curve: MiuixGlassMotion.navContentCurve,
                        decoration: ShapeDecoration(
                          shape: shape,
                          color: i == selected
                              ? c.selectedContainerColor
                              : Color.lerp(
                                  c.restingContainerColor,
                                  c.containerColor,
                                  ramp,
                                ),
                        ),
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: shape,
                            color: c.pressedOverlayColor.withValues(
                              alpha: c.pressedOverlayColor.a * p.clamp(0, 1),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: MiuixGlassMotion.navContentDuration,
                                style: DefaultTextStyle.of(context).style.merge(
                                  (i == selected
                                          ? theme.textStyles.subtitle
                                          : theme.textStyles.body2)
                                      .copyWith(
                                        color: i == selected
                                            ? c.selectedContentColor
                                            : c.contentColor,
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
                      if (i != selected && ramp < 1 && c.restingStrokeAlpha > 0)
                        IgnorePointer(
                          child: MiuixGlass(
                            shape: shape,
                            fill: Colors.transparent,
                            stroke: rim,
                            shading: false,
                            alpha: (alpha * (1 - ramp) * c.restingStrokeAlpha)
                                .clamp(0, 1),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      if (focused)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: theme.colors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
