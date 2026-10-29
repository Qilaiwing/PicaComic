// Miuix Flutter 移植版 - GlassDropdownPopup
// 源自 compose-miuix-ui/miuix 的 GlassDropdownPopup.kt。
// SPDX-License-Identifier: Apache-2.0
import '../glass/miuix_glass_popup_style.dart';
import '../glass/internal/popup_presenter.dart';

/// 对应 Kotlin GlassDropdownPopup。设置项下拉选择，尺寸与中心分别由两条弹簧控制。
/// 保持组件挂载并切换 show，让退出动画完成后自动清除弹层和返回记录。
class MiuixGlassDropdownPopup extends GlassPopupWidget {
  const MiuixGlassDropdownPopup({
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
  }) : super(motion: MiuixGlassPopupMotion.dropdown);
}
