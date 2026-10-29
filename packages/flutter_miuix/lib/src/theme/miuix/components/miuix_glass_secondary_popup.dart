// Miuix Flutter 移植版 - GlassSecondaryPopup
// 源自 compose-miuix-ui/miuix 的 GlassSecondaryPopup.kt。
// SPDX-License-Identifier: Apache-2.0
import '../glass/miuix_glass_popup_style.dart';
import '../glass/internal/popup_presenter.dart';

/// 对应 Kotlin GlassSecondaryPopup。从菜单行展开二级面板；materialAnchor 可共享一级菜单材质。
/// 保持组件挂载并切换 show，让退出动画完成后自动清除弹层和返回记录。
class MiuixGlassSecondaryPopup extends GlassPopupWidget {
  const MiuixGlassSecondaryPopup({
    super.key,
    required super.show,
    required super.onDismissRequest,
    required super.child,
    super.anchor,
    super.anchorBounds,
    super.materialAnchor,
    super.backdrop,
    super.sizing,
    super.visuals,
    super.cornerRadius,
    super.contentPadding,
    super.onDismissFinished,
    super.onMeasured,
  }) : super(motion: MiuixGlassPopupMotion.secondary);
}
