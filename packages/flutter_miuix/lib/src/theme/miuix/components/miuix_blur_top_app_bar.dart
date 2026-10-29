// Miuix Flutter 移植版 - BlurTopAppBar
// 源自 compose-miuix-ui/miuix 的 TopAppBar.kt / BlurTopAppBar。
// SPDX-License-Identifier: Apache-2.0
import 'miuix_top_app_bar.dart';

/// 对应 Kotlin BlurTopAppBar。仅增加大标题模糊，不自动替换旧顶栏。
class MiuixBlurTopAppBar extends MiuixTopAppBar {
  const MiuixBlurTopAppBar({
    super.key,
    required super.title,
    super.largeTitleBlurRadius = 12,
    super.titleAlpha,
    super.color,
    super.titleColor,
    super.largeTitle,
    super.largeTitleColor,
    super.subtitle,
    super.subtitleColor,
    super.navigationIcon,
    super.actions,
    super.scrollBehavior,
    super.defaultWindowInsetsPadding,
    super.titlePadding,
    super.navigationIconPadding,
    super.actionIconPadding,
    super.bottomContent,
    super.clipBehavior,
  });
}
