// Miuix Flutter 移植版 - GlassPopup
// 源自 compose-miuix-ui/miuix 的 GlassPopup.kt。
// SPDX-License-Identifier: Apache-2.0
import '../glass/miuix_glass_popup_style.dart';
import '../glass/internal/popup_presenter.dart';

/// 对应 Kotlin GlassPopup。普通玻璃菜单，固定靠近触发控件的一角展开。
/// 保持组件挂载并切换 show，让退出动画完成后自动清除弹层和返回记录。
class MiuixGlassPopup extends GlassPopupWidget {
  const MiuixGlassPopup({
    super.key,
    required super.show,
    required super.onDismissRequest,
    required super.child,
    super.anchor,
    super.anchorBounds,
    super.backdrop,
    super.sizing,
    super.visuals,
    super.cornerRadius,
    super.contentPadding,
    super.onDismissFinished,
    super.onMeasured,
  }) : super(motion: MiuixGlassPopupMotion.ordinary);
}
