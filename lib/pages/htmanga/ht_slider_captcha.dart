import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/miuix.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/tools/translations.dart';

/// 绅士漫画滑块拼图验证弹窗。
///
/// 站点自 2026-10 起在登录/注册提交前强制要求滑块拼图验证
/// （`statics/js/slider-captcha.js`）：先 `ctl=slider&act=create` 取题，
/// 拖动拼图块对齐缺口后 `act=verify` 提交位置与轨迹，通过后拿到一次性
/// 通行证 `slider_pass`，登录时才可成功。
///
/// 该站点校验的是「原图坐标系」下的拼图块左边缘 X 与拖动轨迹，且 token
/// 一次性、有时效。因此这里在本地用灰度归一化互相关（NCC）自动定位缺口，
/// 用户只需把滑块拖到缺口附近松手，即可精确对齐——比纯手动拖拽可靠得多。
class HtSliderCaptchaDialog extends StatefulWidget {
  const HtSliderCaptchaDialog({super.key});

  /// 弹出滑块验证；通过时返回一次性通行证，取消/失败时返回 null。
  static Future<String?> show(BuildContext context) {
    return showMiuixDialog<String>(
      context: context,
      dismissible: false,
      contentBuilder: (context, close) => const HtSliderCaptchaDialog(),
    );
  }

  @override
  State<HtSliderCaptchaDialog> createState() => _HtSliderCaptchaDialogState();
}

class _HtSliderCaptchaDialogState extends State<HtSliderCaptchaDialog> {
  /// 画布显示宽度（逻辑像素）。
  double _boardWidth = 300;

  /// 题目原图宽 → 画布宽的缩放比。
  double _scale = 1;

  HtSliderChallenge? _challenge;

  /// 解码后的题目位图（用于自动求缺口）。
  ui.Image? _backgroundImage;
  ui.Image? _pieceImage;

  /// 自动匹配出的缺口左边缘（原图坐标）；匹配失败时为 null。
  double? _answerX;

  bool _loading = true;
  bool _verifying = false;
  String? _error;

  /// 当前拼图块位移（画布像素）。
  double _offset = 0;

  bool _dragging = false;

  /// 拖动轨迹 `[毫秒, 原图坐标位移, 触点Y]`（服务端会校验其合理性）。
  final List<List<num>> _track = [];

  DateTime _dragStart = DateTime.now();
  double _dragStartGlobalX = 0;
  double _dragStartOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _backgroundImage?.dispose();
    _pieceImage?.dispose();
    super.dispose();
  }

  double get _maxOffset {
    final c = _challenge;
    if (c == null) return 0;
    return (_boardWidth - c.pieceSize * _scale).clamp(0.0, double.infinity);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _track.clear();
      _answerX = null;
    });

    // 释放上一题的位图，避免多题叠加占用内存。
    _backgroundImage?.dispose();
    _pieceImage?.dispose();
    _backgroundImage = null;
    _pieceImage = null;

    final res = await HtmangaNetwork().createSliderChallenge();
    if (!mounted) return;
    if (res.error) {
      setState(() {
        _loading = false;
        _error = res.errorMessageWithoutNull;
      });
      return;
    }
    final c = res.data;

    ui.Image? bg;
    ui.Image? piece;
    double? answer;
    try {
      bg = await _decodeImage(c.background);
      piece = await _decodeImage(c.piece);
      if (bg != null && piece != null) {
        answer = _matchGap(
          background: bg,
          backgroundPixels: await _readPixels(bg),
          piece: piece,
          piecePixels: await _readPixels(piece),
          hintY: c.y,
        );
      }
    } catch (_) {
      // 解码失败不影响手动验证：此时只隐藏自动定位能力。
    }
    if (!mounted) {
      bg?.dispose();
      piece?.dispose();
      return;
    }

    setState(() {
      _challenge = c;
      _scale = _boardWidth / c.width;
      _backgroundImage = bg;
      _pieceImage = piece;
      _answerX = answer;
      _loading = false;
    });
  }

  /// 灰度归一化互相关（NCC）定位缺口。
  ///
  /// 服务端返回的 `y` 是缺口顶边在原图中的位置，附近搜索即可。
  /// 用 NCC 而非绝对色差：缺口区域常带阴影/亮度差，绝对差会误判。
  double? _matchGap({
    required ui.Image background,
    required Uint8List backgroundPixels,
    required ui.Image piece,
    required Uint8List piecePixels,
    required double hintY,
  }) {
    final bgW = background.width;
    final bgH = background.height;
    final pw = piece.width;
    final ph = piece.height;
    if (pw <= 0 || ph <= 0 || bgW < pw || bgH < ph) return null;

    // 采集拼图块不透明像素（灰度）与相对偏移。
    final sampleX = <int>[];
    final sampleY = <int>[];
    final sampleG = <double>[];
    for (var y = 0; y < ph; y++) {
      for (var x = 0; x < pw; x++) {
        final i = (y * pw + x) * 4;
        if (piecePixels[i + 3] < 200) continue;
        sampleX.add(x);
        sampleY.add(y);
        sampleG.add(0.299 * piecePixels[i] +
            0.587 * piecePixels[i + 1] +
            0.114 * piecePixels[i + 2]);
      }
    }
    final n = sampleG.length;
    if (n < 16) return null;

    var meanP = 0.0;
    for (final g in sampleG) {
      meanP += g;
    }
    meanP /= n;
    var varP = 0.0;
    for (final g in sampleG) {
      varP += (g - meanP) * (g - meanP);
    }
    final sdP = varP <= 0 ? 0.0 : math.sqrt(varP);
    if (sdP <= 0.001) return null;

    final y0 = (hintY.round() - 8).clamp(0, bgH - ph);
    final y1 = (hintY.round() + 8).clamp(0, bgH - ph);

    var bestCorr = -2.0;
    var bestX = -1;
    for (var cy = y0; cy <= y1; cy++) {
      for (var cx = 0; cx <= bgW - pw; cx++) {
        var sum = 0.0;
        var sumSq = 0.0;
        var cross = 0.0;
        for (var i = 0; i < n; i++) {
          final bi = ((cy + sampleY[i]) * bgW + (cx + sampleX[i])) * 4;
          final g = 0.299 * backgroundPixels[bi] +
              0.587 * backgroundPixels[bi + 1] +
              0.114 * backgroundPixels[bi + 2];
          sum += g;
          sumSq += g * g;
          cross += g * sampleG[i];
        }
        final meanB = sum / n;
        final varB = sumSq - n * meanB * meanB;
        if (varB <= 0.001) continue;
        final cov = cross - n * meanP * meanB;
        final corr = cov / (sdP * math.sqrt(varB));
        if (corr > bestCorr) {
          bestCorr = corr;
          bestX = cx;
        }
      }
    }

    // 相关性过低说明匹配不可靠，宁可让用户凭肉眼对准。
    if (bestX < 0 || bestCorr < 0.45) return null;
    return bestX.toDouble();
  }

  Future<void> _verify() async {
    final c = _challenge;
    if (c == null) return;
    if (_track.length < 3) {
      setState(() {
        _offset = 0;
        _error = "請按住滑塊拖動完成拼圖".tl;
      });
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    // 以原图坐标系提交；服务端只认这个坐标系。
    final x = _offset / _scale;
    final res = await HtmangaNetwork().verifySliderChallenge(
      token: c.token,
      x: x,
      track: _track,
    );
    if (!mounted) return;

    if (res.error) {
      HapticFeedback.mediumImpact();
      setState(() {
        _verifying = false;
        _dragging = false;
        _offset = 0;
        _error = res.errorMessageWithoutNull;
        _track.clear();
      });
      // token 一次性且有时效：失败后自动换题，避免反复失败。
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _load();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _verifying = false);
    if (mounted) Navigator.of(context).pop(res.data);
  }

  void _onDragStart(DragStartDetails details) {
    if (_challenge == null || _loading || _verifying) return;
    _dragStartGlobalX = details.globalPosition.dx;
    _dragStartOffset = _offset;
    _dragStart = DateTime.now();
    setState(() {
      _dragging = true;
      _error = null;
      _track
        ..clear()
        ..add([
          0,
          _offset / _scale,
          details.globalPosition.dy.round(),
        ]);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging || _challenge == null) return;
    final next = (_dragStartOffset +
            (details.globalPosition.dx - _dragStartGlobalX))
        .clamp(0.0, _maxOffset);
    final elapsed = DateTime.now().difference(_dragStart).inMilliseconds;
    setState(() {
      _offset = next;
      _track.add([
        elapsed,
        next / _scale,
        details.globalPosition.dy.round(),
      ]);
      if (_track.length > 400) _track.removeAt(1);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    // 松手时若拖到了自动解出的缺口附近，则吸附到精确位置再提交。
    final answer = _answerX;
    if (answer != null) {
      final answerOffset = answer * _scale;
      if ((_offset - answerOffset).abs() <= 24) {
        _offset = answerOffset;
      }
    }
    final elapsed = DateTime.now().difference(_dragStart).inMilliseconds;
    final lastY = _track.isNotEmpty ? _track.last[2] : 0;
    _track.add([
      elapsed,
      _offset / _scale,
      lastY,
    ]);
    setState(() => _dragging = false);
    _verify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final colors = theme.colors;

    return LayoutBuilder(
          builder: (context, constraints) {
            // 画布宽度自适应对话框可用宽度（上限 320，与网页端一致）。
            final width = constraints.maxWidth.clamp(200.0, 320.0);
            if ((width - _boardWidth).abs() > 0.5) {
              final c = _challenge;
              _boardWidth = width;
              if (c != null) _scale = width / c.width;
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 12),
                _buildBoard(theme),
                const SizedBox(height: 12),
                Text(
                  _error ?? "拖动滑块，让拼图对齐缺口".tl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: _error != null
                        ? colors.error
                        : colors.onSurfaceVariantSummary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSlider(theme),
              ],
            );
          },
    );
  }

  Widget _buildHeader(MiuixThemeData theme) {
    final colors = theme.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            "安全验证".tl,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.onBackground,
            ),
          ),
        ),
        MiuixIconButton(
          minWidth: 32,
          minHeight: 32,
          onPressed: _verifying
              ? null
              : () => Navigator.of(context).pop(),
          child: MiuixIcon(
            vector: MiuixIcons.os4.close,
            size: 16,
            tint: colors.onSurfaceVariantSummary,
          ),
        ),
      ],
    );
  }

  Widget _buildBoard(MiuixThemeData theme) {
    final colors = theme.colors;
    final c = _challenge;
    final height = _boardWidth * 180 / 320;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: _boardWidth,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colors.secondaryContainer),
            if (_backgroundImage != null)
              RawImage(image: _backgroundImage, fit: BoxFit.fill),
            if (_pieceImage != null && c != null)
              Positioned(
                left: _offset,
                top: c.y * _scale,
                width: c.pieceSize * _scale,
                height: c.pieceSize * _scale,
                child: RawImage(image: _pieceImage, fit: BoxFit.fill),
              ),
            if (_loading)
              ColoredBox(
                color: colors.background.withValues(alpha: 0.72),
                child: Center(
                  child: MiuixCircularProgressIndicator(
                    size: 26,
                    strokeWidth: 2.5,
                    colors: MiuixProgressIndicatorDefaults.defaultColors(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(MiuixThemeData theme) {
    final colors = theme.colors;
    final maxOffset = _maxOffset;
    final enabled = !_loading && !_verifying && _challenge != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final track = constraints.maxWidth;
        // 把手行程 = 轨道长 - 把手宽，与拼图块行程换算成同一比例后定位。
        final handleTravel = (track - 44).clamp(1.0, double.infinity);
        final progress = maxOffset <= 0 ? 0.0 : (_offset / maxOffset);
        return SizedBox(
          height: 44,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colors.secondaryContainer,
                    shape: const MiuixSquircleBorder(cornerRadius: 22),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: (handleTravel * progress + 22).clamp(0.0, track),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colors.primary.withValues(alpha: 0.16),
                    shape: const MiuixSquircleBorder(cornerRadius: 22),
                  ),
                ),
              ),
              Center(
                child: _verifying
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MiuixCircularProgressIndicator(
                            size: 15,
                            strokeWidth: 2,
                            colors: MiuixProgressIndicatorDefaults.defaultColors(
                              context,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "验证中".tl,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.onSurfaceVariantSummary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        enabled ? "按住滑块，拖动完成拼图".tl : "加载中".tl,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.onSurfaceVariantSummary,
                        ),
                      ),
              ),
              Positioned(
                left: handleTravel * progress,
                top: 0,
                child: GestureDetector(
                  onHorizontalDragStart: enabled ? _onDragStart : null,
                  onHorizontalDragUpdate: enabled ? _onDragUpdate : null,
                  onHorizontalDragEnd: enabled ? _onDragEnd : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: ShapeDecoration(
                      // Always theme primary (alpha when idle) so the handle
                      // never flashes Material blue before the theme settles.
                      color: colors.primary.withValues(
                        alpha: enabled ? 1.0 : 0.45,
                      ),
                      shape: const MiuixSquircleBorder(cornerRadius: 22),
                    ),
                    child: Center(
                      child: MiuixIcon(
                        vector: MiuixIcons.os4.chevronForward,
                        size: 18,
                        tint: colors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 把 `data:image/...;base64,...` 解码成 `ui.Image`。
  static Future<ui.Image?> _decodeImage(String dataUrl) async {
    final comma = dataUrl.indexOf(',');
    final raw = comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl;
    final bytes = base64Decode(base64.normalize(raw));
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  /// 取出位图的 RGBA 像素（预乘 alpha 的直通拷贝）。
  static Future<Uint8List> _readPixels(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  }
}

/// 便捷方法：需要时弹出滑块验证并返回通行证。
Future<String?> requestHtSliderPass(BuildContext context) {
  return HtSliderCaptchaDialog.show(context);
}
