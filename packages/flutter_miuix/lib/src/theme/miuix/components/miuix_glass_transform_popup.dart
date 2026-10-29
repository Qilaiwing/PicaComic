// Miuix Flutter 移植版 - GlassTransformPopup
// 源自 compose-miuix-ui/miuix 的 GlassTransformPopup.kt。
// SPDX-License-Identifier: Apache-2.0
import '../glass/miuix_glass_popup_style.dart';
import '../glass/internal/popup_presenter.dart';

/// 对应 Kotlin GlassTransformPopup。从按钮连续变形成菜单；anchorContent 传入无 GlobalKey 的图标副本。
/// 保持组件挂载并切换 show，让退出动画完成后自动清除弹层和返回记录。
class MiuixGlassTransformPopup extends GlassPopupWidget {
  const MiuixGlassTransformPopup({
    super.key,
    required super.show,
    required super.onDismissRequest,
    required super.child,
    required super.anchor,
    required super.anchorContent,
    super.simplified,
    super.stacked,
    super.maskColor,
    super.gap,
    super.backdrop,
    super.sizing,
    super.visuals,
    super.cornerRadius,
    super.contentPadding,
    super.onDismissFinished,
    super.onMeasured,
  }) : super(motion: MiuixGlassPopupMotion.transform);
}
