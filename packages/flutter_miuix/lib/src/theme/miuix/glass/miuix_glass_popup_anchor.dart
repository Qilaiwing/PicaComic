// Miuix Flutter 移植版 - GlassPopupAnchor
// 源自 compose-miuix-ui/miuix 的 GlassTransformPopup.kt。
// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/widgets.dart';
import '../blur/miuix_backdrop.dart';
import 'miuix_glass_material.dart';
import 'miuix_glass_style.dart';
import 'miuix_glass_decoration.dart';

/// 对应 Kotlin GlassPopupAnchor。用 MiuixGlassAnchor 或图标按钮的 anchor 参数绑定。
/// 调用方创建并 dispose，不能把同一 anchor 绑定到两个控件。
class MiuixGlassPopupAnchor extends ChangeNotifier {
  final GlobalKey key = GlobalKey(debugLabel: 'MiuixGlassPopupAnchor');
  bool _hidden = false;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool get contentHidden => _hidden;
  set contentHidden(bool value) {
    if (_disposed || _hidden == value) return;
    _hidden = value;
    notifyListeners();
  }

  /// 窗口全局坐标；弹层会转换到自己的 Overlay 坐标系。
  Rect? get bounds {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
  }

  /// 图标按钮发布的共享表面，不要求调用方重复配置。
  MiuixGlassAnchorSurface? surface;
}

/// 对应上游锚点携带的 button surface 配置。
@immutable
class MiuixGlassAnchorSurface {
  const MiuixGlassAnchorSurface({
    required this.backdrop,
    required this.style,
    required this.material,
    this.underlay,
    this.stroke,
    this.fill,
    required this.alpha,
  });
  final MiuixBackdrop? backdrop;
  final MiuixGlassStyle style;
  final MiuixGlassMaterial material;
  final MiuixGlassMaterial? underlay;
  final MiuixGlassStroke? stroke;
  final Color? fill;
  final double alpha;
}

/// 对应 Kotlin glassPopupAnchor / glassPopupAnchorValue。
class MiuixGlassAnchor extends StatelessWidget {
  const MiuixGlassAnchor({
    super.key,
    required this.anchor,
    required this.child,
  });
  final MiuixGlassPopupAnchor anchor;
  final Widget child;
  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: anchor.key,
    child: ListenableBuilder(
      listenable: anchor,
      child: child,
      builder: (context, child) => IgnorePointer(
        ignoring: anchor.contentHidden,
        child: Opacity(opacity: anchor.contentHidden ? 0 : 1, child: child),
      ),
    ),
  );
}
