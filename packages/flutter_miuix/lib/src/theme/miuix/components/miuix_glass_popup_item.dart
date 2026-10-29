// Miuix Flutter 移植版 - GlassPopupItem
// 源自 compose-miuix-ui/miuix 的 GlassPopup.kt。
// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import '../foundation/miuix_content_color.dart';
import '../glass/miuix_glass_motion.dart';
import '../glass/miuix_glass_shape.dart';
import '../glass/internal/animation.dart';
import '../glass/internal/interactive.dart';
import '../icon/miuix_basic_icons.dart';
import '../theme/miuix_theme.dart';
import '../theme/miuix_text_styles.dart';
import 'miuix_icon.dart';

/// 对应 Kotlin GlassPopupItem：图标、副说明、选中勾号和子菜单箭头均可选。
class MiuixGlassPopupItem extends StatelessWidget {
  const MiuixGlassPopupItem({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.summary,
    this.enabled = true,
    this.selected = false,
    this.showArrow = false,
    this.arrowRotation = 0,
    this.contentColor,
    this.summaryColor,
    this.selectedContentColor,
    this.pressedColor,
  });
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final String? summary;
  final bool enabled, selected, showArrow;

  /// 角度制，同 Kotlin arrowRotation；RTL 的展开箭头通常取 +90，LTR 取 -90。
  final double arrowRotation;
  final Color? contentColor, summaryColor, selectedContentColor, pressedColor;
  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context), c = theme.colors;
    final dark = c.background.computeLuminance() < .5,
        active = enabled && onPressed != null;
    final base = selected
        ? (selectedContentColor ?? c.primary)
        : (contentColor ?? c.onSurfaceContainer);
    final color = active ? base : base.withValues(alpha: base.a * .4);
    final press =
        pressedColor ??
        (dark ? Colors.white : Colors.black).withValues(alpha: .1);
    return GlassInteractive(
      selected: selected,
      onTap: active ? onPressed : null,
      builder: (context, pressed, focused) => GlassSpringBuilder(
        value: pressed ? 1 : 0,
        spring: MiuixGlassMotion.popupPressExit,
        builder: (context, p, _) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: const MiuixGlassShape(cornerRadius: 15),
                color: press.withValues(
                  alpha: press.a * (focused ? 1 : p.clamp(0, 1)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                child: MiuixContentColor(
                  color: color,
                  child: IconTheme.merge(
                    data: IconThemeData(color: color, size: 24),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          SizedBox.square(dimension: 24, child: icon),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: theme.textStyles.body1
                                    .copyWith(color: color)
                                    .withMiuixWeight(
                                      theme.fontWeightAdjustment,
                                    ),
                              ),
                              if (summary != null)
                                Text(
                                  summary!,
                                  style: theme.textStyles.footnote1
                                      .copyWith(
                                        color:
                                            (summaryColor ??
                                                    c.onSurfaceContainerVariant)
                                                .withValues(
                                                  alpha: active ? 1 : .4,
                                                ),
                                      )
                                      .withMiuixWeight(
                                        theme.fontWeightAdjustment,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          MiuixIcon(
                            vector: MiuixIcons.basic.check,
                            size: 24,
                            tint: color,
                          ),
                        ],
                        if (showArrow) ...[
                          const SizedBox(width: 8),
                          Transform.rotate(
                            angle: arrowRotation * 3.141592653589793 / 180,
                            child: Transform.flip(
                              flipX:
                                  Directionality.of(context) ==
                                  TextDirection.rtl,
                              child: MiuixIcon(
                                vector: MiuixIcons.basic.arrowRight,
                                size: 16,
                                tint: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
