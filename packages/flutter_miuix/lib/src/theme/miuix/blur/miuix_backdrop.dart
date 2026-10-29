// Miuix Flutter 移植版 - Backdrop 抽象
// 源自 compose-miuix-ui/miuix 的 miuix-blur/Backdrop.kt + LayerBackdrop.kt。
// Backdrop 定义"模糊表面背后要绘制的内容"如何提供；MiuixLayerBackdrop 通过
// 一个被捕获的图层快照（ui.Image）+ 全局坐标提供背景，供模糊组件按偏移取样。
// SPDX-License-Identifier: Apache-2.0

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// 背景内容提供者。对应 Kotlin `interface Backdrop`。
///
/// 模糊组件（[MiuixTextureBlur] 等）通过它拿到"自己背后的内容"来做模糊。
/// 阶段 5A 只实现 [MiuixLayerBackdrop]（图层快照捕获）。
abstract class MiuixBackdrop extends ChangeNotifier {
  /// 是否需要布局坐标来正确定位（图层型 backdrop 为 true）。
  /// 对应 Kotlin `isCoordinatesDependent`。
  bool get isCoordinatesDependent;

  /// 当前可用于取样的背景快照；未捕获时为 null。
  ui.Image? get snapshot;

  /// 背景快照在全局（窗口）坐标系中的左上角位置。用于与模糊表面对齐。
  Offset? get globalOffset;

  /// 快照的设备像素比（快照按此比例录制）。
  double get pixelRatio;
}

/// 通过捕获的图层快照提供背景的 [MiuixBackdrop]。对应 Kotlin `LayerBackdrop`。
///
/// 用 [MiuixLayerBackdropCapture] 包裹背景容器来录制其渲染输出，再把本对象传给
/// 模糊组件。用 [rememberMiuixLayerBackdrop] 或直接 `MiuixLayerBackdrop()` 创建，
/// 需在 dispose 时释放。
class MiuixLayerBackdrop extends MiuixBackdrop {
  MiuixLayerBackdrop();

  @override
  bool get isCoordinatesDependent => true;

  ui.Image? _snapshot;
  Offset? _globalOffset;
  double _pixelRatio = 1.0;
  RenderBox? _capture;

  @override
  ui.Image? get snapshot => _snapshot;

  /// 快照左上角的全局坐标，**读取时**才计算。对应 Kotlin `LayerBackdrop.layerCoordinates`
  /// 在消费者绘制时读 `positionInWindow()`，而不是记录录制那一刻的位置。
  ///
  /// 捕获子树是重绘边界：路由转场、顶栏量完后的内容内缩、滚动都只更新它的图层变换而
  /// 不会重新 paint。若把录制时的坐标冻住，消费者就会按旧原点去采样快照——采样窗口整体
  /// 偏移，落在快照外的部分取到透明，玻璃表面被切成"一半有背景、一半全透"。
  @override
  Offset? get globalOffset {
    final capture = _capture;
    if (capture != null && capture.attached && capture.hasSize) {
      return capture.localToGlobal(Offset.zero);
    }
    return _globalOffset;
  }

  @override
  double get pixelRatio => _pixelRatio;

  /// 由 [MiuixLayerBackdropCapture] 的渲染对象在 attach 时登记自身，供 [globalOffset] 实时取坐标。
  void registerCapture(RenderBox capture) => _capture = capture;

  /// 由 [MiuixLayerBackdropCapture] 的渲染对象在 detach / 换 backdrop 时注销。
  void unregisterCapture(RenderBox capture) {
    if (identical(_capture, capture)) _capture = null;
  }

  /// 由 [MiuixLayerBackdropCapture] 在每帧录制后调用，更新快照与坐标。
  ///
  /// [globalOffset] 只作为捕获节点未挂载时的兜底；正常路径走实时坐标。
  /// 旧快照在替换后被释放（Flutter 的 [ui.Image] 需显式 dispose）。
  void updateSnapshot(ui.Image image, Offset globalOffset, double pixelRatio) {
    final old = _snapshot;
    _snapshot = image;
    _globalOffset = globalOffset;
    _pixelRatio = pixelRatio;
    // 先通知再释放旧图，避免正在使用旧图的绘制被拉黑。
    notifyListeners();
    if (old != null && !identical(old, image)) {
      old.dispose();
    }
  }

  @override
  void dispose() {
    _snapshot?.dispose();
    _snapshot = null;
    super.dispose();
  }
}
