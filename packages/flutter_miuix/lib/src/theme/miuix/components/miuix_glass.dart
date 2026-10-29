// Miuix Flutter 移植版 - Glass / GlassPanel / GlassSurface
// 源自 compose-miuix-ui/miuix 的 Glass.kt、GlassPanel.kt 与 internal/GlassUniforms.kt。
// 背景先低分辨率高斯模糊/混色，再运行源端折射 shader；轮廓、高光和阴影全分辨率绘制。
// SPDX-License-Identifier: Apache-2.0
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../blur/miuix_backdrop.dart';
import '../glass/miuix_glass_decoration.dart';
import '../glass/miuix_glass_material.dart';
import '../glass/miuix_glass_shape.dart';
import '../glass/miuix_glass_style.dart';
import '../glass/miuix_glass_styles.dart';
import '../glass/internal/miuix_glass_uniforms.dart';
import '../foundation/miuix_popup_utils.dart';
import '../theme/miuix_theme.dart';

/// 对应 Kotlin GlassDefaults。
class MiuixGlassDefaults {
  MiuixGlassDefaults._();
  static const cornerRadius = 24.0;
  static const smoothing = 1.0;
  static const sourceDensity = 3.0;
  static MiuixGlassStyle style(BuildContext context) =>
      MiuixGlassStyles.forTheme(
        MiuixTheme.of(context).colors.background.computeLuminance() < .5,
      );
}

/// 预加载 OS4 shader。可在首屏之前 await；绘制对象各自持有并释放 FragmentShader。
class MiuixGlassRendering {
  MiuixGlassRendering._();
  static final Map<String, ui.FragmentProgram> _programs = {};
  static Future<void>? _loading;
  static bool get isLoaded => _programs.length == miuixGlassUniforms.length;

  /// 加载失败的原因；`null` 表示没失败过。shader 缺失会静默把玻璃降级成
  /// 「模糊 + 原生混色」，看起来只是「不够通透」而不是报错，所以把原因留在
  /// 这里供排查（另见 [loadedPrograms]）。
  static Object? loadError;

  /// 已成功加载的 shader 名字，用来判断能降级到哪一档。
  static Iterable<String> get loadedPrograms => _programs.keys;
  static bool has(String name) => _programs.containsKey(name);

  static Future<void> load() => _loading ??= _load();
  static Future<void> _load() async {
    // 逐个捕获：一个 shader 编不过不该把其余八个一起拖下水——mask/stroke 挂了
    // 也还能靠 blend 画出真玻璃。
    Object? failure;
    for (final name in miuixGlassUniforms.keys) {
      if (_programs.containsKey(name)) continue;
      final asset = 'shaders/miuix_os4_$name.frag';
      try {
        ui.FragmentProgram program;
        try {
          program = await ui.FragmentProgram.fromAsset(
            'packages/flutter_miuix/$asset',
          );
        } catch (_) {
          program = await ui.FragmentProgram.fromAsset(asset);
        }
        _programs[name] = program;
      } catch (error) {
        failure ??= error;
        assert(() {
          debugPrint('Miuix OS4: shader "$asset" unavailable → $error');
          return true;
        }());
      }
    }
    loadError = failure;
  }
}

/// 对应 Kotlin Modifier.glass。必须放在 backdrop 捕获子树之外，防止反馈采样。
///
/// 无 backdrop 或 shader 不可用时保留纯色轮廓、阴影及可绘制的高光，不伪装成折射效果。
/// [shading] 为 false 时使用 OS4 栏/菜单的 MaterialToken，而非仿生折射 GlassToken。
class MiuixGlass extends StatefulWidget {
  const MiuixGlass({
    super.key,
    this.backdrop,
    this.style,
    this.material,
    this.underlayMaterial,
    this.shape = const MiuixGlassShape(),
    this.alpha = 1,
    this.tint,
    this.fill,
    this.stroke,
    this.shadow,
    this.shading = true,
    this.enabled = true,
    required this.child,
  }) : assert(alpha >= 0 && alpha <= 1);
  final MiuixBackdrop? backdrop;
  final MiuixGlassStyle? style;
  final MiuixGlassMaterial? material, underlayMaterial;
  final MiuixGlassShape shape;
  final double alpha;
  final Color? tint, fill;
  final MiuixGlassStroke? stroke;
  final MiuixGlassShadow? shadow;
  final bool shading, enabled;
  final Widget child;
  @override
  State<MiuixGlass> createState() => _MiuixGlassState();
}

class _MiuixGlassState extends State<MiuixGlass> {
  /// shader 的加载**已经结束**（成功与否逐个看 [MiuixGlassRendering.has]）。
  /// 结束前所有 shader 路径都按缺失处理，结束后重绘一次。
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    _ready = MiuixGlassRendering.isLoaded;
    if (_ready) return;
    MiuixGlassRendering.load().whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final fill =
        widget.fill ??
        (colors.background.computeLuminance() < .5
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFFFFFFF));
    return _GlassRenderWidget(
      config: widget,
      ready: _ready,
      style: widget.style ?? MiuixGlassDefaults.style(context),
      fill: fill,
      direction: Directionality.of(context),
      dpr: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: widget.shape),
        child: widget.child,
      ),
    );
  }
}

/// 对应 Kotlin Modifier.glassPanel，默认附带 Regular 阴影。
class MiuixGlassPanel extends MiuixGlass {
  const MiuixGlassPanel({
    super.key,
    super.backdrop,
    super.style,
    super.material,
    super.underlayMaterial,
    super.shape,
    super.alpha,
    super.tint,
    super.fill,
    super.stroke,
    super.shadow = MiuixGlassShadows.regular,
    super.shading,
    super.enabled,
    required super.child,
  });
}

/// 对应 Kotlin glassSurface，供已有级联菜单的 surfaceBuilder 注入 OS4 表面。
MiuixPopupSurfaceBuilder miuixGlassSurface({
  MiuixBackdrop? backdrop,
  MiuixGlassStyle? style,
  MiuixGlassMaterial? material,
  Color? fill,
  MiuixGlassStroke? stroke,
  MiuixGlassShadow? shadow = MiuixGlassShadows.floating,
  double alpha = 1,
}) => (context, shape, child) {
  final radius = shape is RoundedRectangleBorder ? shape.borderRadius : null;
  final dark = MiuixTheme.of(context).colors.background.computeLuminance() < .5;
  return MiuixGlassPanel(
    backdrop: backdrop,
    style: style,
    material: material ?? MiuixGlassMaterials.popupViewGlass(dark),
    shape: shape is MiuixGlassShape
        ? shape
        : MiuixGlassShape(borderRadius: radius),
    fill: fill,
    stroke: stroke ?? MiuixGlassStrokes.forTheme(dark),
    shadow: shadow,
    alpha: alpha,
    shading: false,
    child: child,
  );
};

class _GlassRenderWidget extends SingleChildRenderObjectWidget {
  const _GlassRenderWidget({
    required this.config,
    required this.ready,
    required this.style,
    required this.fill,
    required this.direction,
    required this.dpr,
    required super.child,
  });
  final MiuixGlass config;
  final bool ready;
  final MiuixGlassStyle style;
  final Color fill;
  final TextDirection direction;
  final double dpr;
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGlass(this);
  @override
  void updateRenderObject(BuildContext context, _RenderGlass renderObject) =>
      renderObject.update(this);
}

class _RenderGlass extends RenderProxyBox {
  _RenderGlass(this.data);
  _GlassRenderWidget data;
  final _shaders = <String, ui.FragmentShader>{};
  ui.Image? _texture;
  Object? _textureKey;
  MiuixBackdrop? get backdrop => data.config.backdrop;
  void update(_GlassRenderWidget value) {
    if (attached && backdrop != value.config.backdrop) {
      backdrop?.removeListener(markNeedsPaint);
      value.config.backdrop?.addListener(markNeedsPaint);
    }
    data = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    backdrop?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    backdrop?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    for (final s in _shaders.values) {
      s.dispose();
    }
    _texture?.dispose();
    super.dispose();
  }

  @override
  Rect get paintBounds {
    final shadow = data.config.shadow;
    return super.paintBounds.inflate(
      shadow == null
          ? 0
          : (shadow.radius +
                    math.max(shadow.offsetX.abs(), shadow.offsetY.abs())) /
                3,
    );
  }

  /// 该 shader 可用（asset 已加载且加载流程已结束）。逐个判断而不是一刀切
  /// `data.ready`：折射挂了不该连混色一起放弃，否则玻璃直接塌成一块实色。
  bool has(String key) => data.ready && MiuixGlassRendering.has(key);

  ui.FragmentShader shader(String key) => _shaders.putIfAbsent(
    key,
    () => MiuixGlassRendering._programs[key]!.fragmentShader(),
  );
  void uniform(String key, String name, List<double> values) {
    final s = shader(key), start = miuixGlassUniforms[key]![name]!;
    for (var i = 0; i < values.length; i++) {
      s.setFloat(start + i, values[i]);
    }
  }

  void silhouette(String key, double scale) {
    final r = data.config.shape.resolve(data.direction),
        half = size.shortestSide / 2;
    uniform(key, 'in_size', [size.width * scale, size.height * scale]);
    uniform(
      key,
      'in_radii',
      [
        r.topLeft.x,
        r.topRight.x,
        r.bottomRight.x,
        r.bottomLeft.x,
      ].map((r) => r.clamp(0, half) * scale).toList(),
    );
    uniform(key, 'in_smoothing', [data.config.shape.smoothing]);
  }

  void bind(String key, ui.Image image) {
    shader(key).setImageSampler(0, image);
    uniform(key, 'u_textureSize', [
      image.width.toDouble(),
      image.height.toDouble(),
    ]);
  }

  ui.Image blend(ui.Image image, MiuixGlassMaterial material, double alpha) {
    bind('blend', image);
    final layers = material.layers;
    for (var i = 0; i < 3; i++) {
      final color = i < layers.length
          ? layers[i].color
          : const Color(0x00000000);
      uniform('blend', 'in_blend$i', [
        color.r,
        color.g,
        color.b,
        color.a * alpha,
      ]);
    }
    uniform('blend', 'in_blendMode', [
      for (var i = 0; i < 3; i++)
        i < layers.length ? layers[i].mode.index.toDouble() : 0,
      layers.length.toDouble(),
    ]);
    final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Paint()..shader = shader('blend'),
    );
    final picture = recorder.endRecording();
    final result = picture.toImageSync(image.width, image.height);
    picture.dispose();
    return result;
  }

  /// [_texture] 里是否已经混过色。blend shader 缺席时只做模糊，混色留给
  /// [paint] 用原生 [BlendMode] 补。
  bool _textureBlended = false;

  ui.Image prepare(double padding, double ratio, double alpha) {
    final cfg = data.config, source = backdrop!, image = source.snapshot!;
    final global = localToGlobal(Offset.zero),
        origin = global - source.globalOffset!;
    final blur = cfg.material?.blurRadius ?? data.style.blur.small / 3;
    final blendable = has('blend');
    final key = (
      image,
      origin,
      size,
      ratio,
      blur,
      cfg.material,
      cfg.underlayMaterial,
      alpha,
      blendable,
    );
    if (_textureKey == key && _texture != null) return _texture!;
    final width = math.max(1, ((size.width + 2 * padding) * ratio).ceil());
    final height = math.max(1, ((size.height + 2 * padding) * ratio).ceil());
    final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
    canvas.scale(ratio);
    final dest = Rect.fromLTWH(
      -origin.dx + padding,
      -origin.dy + padding,
      image.width / source.pixelRatio,
      image.height / source.pixelRatio,
    );
    // 模糊走 saveLayer 而不是 `Paint.imageFilter`：drawImageRect 上的 image
    // filter 在各后端（尤其 Impeller）不是稳定语义，静默失效的表现正好是
    // 「玻璃里能看清背后的字」。saveLayer + imageFilter 就是 ImageFiltered 的
    // 语义，各后端一致。sigma 沿用源端 BLUR_RADIUS_TO_SIGMA = .45，单位是
    // 逻辑像素（CTM 里的 ratio 会把它一并缩到纹理分辨率）。
    final layerBounds = Rect.fromLTWH(0, 0, width / ratio, height / ratio);
    canvas.saveLayer(
      layerBounds,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: blur * .45,
          sigmaY: blur * .45,
          tileMode: TileMode.clamp,
        ),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dest,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
    final picture = recorder.endRecording();
    var result = picture.toImageSync(width, height);
    picture.dispose();
    if (blendable) {
      // 顺序固定：先父级 actionBar 遮罩（永远满强度），再本体材质。
      for (var i = 0; i < 2; i++) {
        final material = i == 0 ? cfg.underlayMaterial : cfg.material;
        if (material == null) continue;
        final next = blend(result, material, i == 0 ? 1 : alpha);
        result.dispose();
        result = next;
      }
    }
    _textureBlended = blendable;
    _texture?.dispose();
    _texture = result;
    _textureKey = key;
    return result;
  }

  /// blend shader 缺席时的混色：把材质的颜色层用原生 [BlendMode] 直接盖在
  /// 已模糊的背景上。七种模式有一一对应，另两种取最近似（见
  /// [MiuixGlassColorBlendMode.fallback]）。
  void blendLayersNatively(Canvas canvas, Rect rect, double alpha) {
    final cfg = data.config;
    for (var i = 0; i < 2; i++) {
      final material = i == 0 ? cfg.underlayMaterial : cfg.material;
      if (material == null) continue;
      final layerAlpha = i == 0 ? 1.0 : alpha;
      for (final layer in material.layers) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = layer.color.withValues(alpha: layer.color.a * layerAlpha)
            ..blendMode = layer.mode.fallback,
        );
      }
    }
  }

  void glassUniforms(ui.Image texture, double padding, double ratio) {
    final s = data.style, cfg = data.config;
    bind('glass', texture);
    silhouette('glass', ratio);
    uniform('glass', 'in_pad', [padding * ratio, padding * ratio]);
    uniform('glass', 'in_maxCoord', [texture.width - .5, texture.height - .5]);
    uniform('glass', 'in_alphaEdge', [
      (s.inner.alpha * cfg.alpha).clamp(0, 1),
      math.max(s.edge.width / 3, 1 / data.dpr) * ratio,
      s.edge.thickness / 3 * ratio,
      s.edge.reflectOffset / 3 * ratio,
    ]);
    uniform('glass', 'in_iorRefl', [
      s.refract.ior,
      s.reflect.strength,
      s.reflect.lighten,
      s.inner.colorPow,
    ]);
    final tint = cfg.tint ?? s.inner.tint;
    uniform('glass', 'in_tint', [
      tint.r,
      tint.g,
      tint.b,
      cfg.tint?.a ?? s.inner.tintStrength,
    ]);
    uniform('glass', 'in_whiteMixBg', [
      s.inner.colorWhite,
      s.inner.colorMix,
      s.background.saturation,
      s.background.brightness,
    ]);
    uniform('glass', 'in_darker', [
      s.blend.darkerStart,
      s.blend.darkerEnd,
      s.blend.darker,
      s.inner.bottom,
    ]);
    uniform('glass', 'in_lightDir', [
      s.light.directionX,
      s.light.directionY,
      s.light.directionZ,
      s.light.angleRange * math.pi,
    ]);
    uniform('glass', 'in_lightAmt', [
      s.light.intensity,
      s.light.oppositeIntensity,
      s.blend.amount,
      3 * ratio,
    ]);
    uniform('glass', 'in_lumCurve', [
      s.blend.curveA,
      s.blend.curveB,
      s.blend.curveC,
      s.blend.curveD,
    ]);
    uniform('glass', 'in_satBri', [
      s.blend.saturation,
      s.blend.brightness,
      s.background.burn,
      s.background.unShade.clamp(0, 1),
    ]);
    final reach = s.blur.big / 3 * ratio;
    uniform('glass', 'in_edgePow', [
      math.max(s.edge.pow, .01),
      math.min(reach, texture.width / 2),
      math.min(reach, texture.height / 2),
      (reach / math.max(size.longestSide * ratio / 2, 1)).clamp(0, 1),
    ]);
  }

  void light(String name, MiuixGlassStrokeLight light) {
    final dx = light.x - .5, dy = light.y - .7, dz = light.z;
    final len = math.max(math.sqrt(dx * dx + dy * dy + dz * dz), 1e-6),
        c = light.color;
    uniform('stroke', name, [dx / len, dy / len, dz / len, c.a]);
    uniform('stroke', '${name}Color', [c.r, c.g, c.b, 0]);
  }

  void drawShader(
    Canvas canvas,
    String key,
    Offset offset,
    Rect rect,
    double scale, {
    BlendMode blendMode = BlendMode.srcOver,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(1 / scale);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = shader(key)
        ..blendMode = blendMode,
    );
    canvas.restore();
  }

  void _drawStroke(Canvas canvas, Offset offset, double dpr, double alpha) {
    final cfg = data.config;
    final shapePath = cfg.shape.getOuterPath(
      offset & size,
      textDirection: data.direction,
    );
    final stroke = cfg.stroke;
    if (stroke != null) {
      if (has('stroke')) {
        silhouette('stroke', dpr);
        uniform('stroke', 'in_halfViewFloor', [
          (size.width * dpr / 2).floorToDouble(),
          (size.height * dpr / 2).floorToDouble(),
        ]);
        uniform('stroke', 'in_strokeBand', [
          (stroke.width * dpr + .5).clamp(
            .5,
            math.max(.5, size.shortestSide * dpr / 2),
          ),
          math.max(stroke.bevel * dpr + .5, .5),
        ]);
        final c = stroke.color;
        uniform('stroke', 'in_strokeColor', [c.r, c.g, c.b, c.a]);
        uniform('stroke', 'in_strokeAlpha', [alpha]);
        light('in_light1', stroke.primary);
        light('in_light2', stroke.secondary);
        drawShader(
          canvas,
          'stroke',
          offset,
          Offset.zero & (size * dpr),
          dpr,
          blendMode: BlendMode.plus,
        );
      } else {
        canvas.drawPath(
          shapePath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke.width
            ..color = stroke.color.withValues(alpha: stroke.color.a * alpha),
        );
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final cfg = data.config,
        canvas = context.canvas,
        rect = offset & size,
        dpr = data.dpr;
    if (size.isEmpty || !cfg.enabled || cfg.alpha <= 0) {
      super.paint(context, offset);
      return;
    }
    final shapePath = cfg.shape.getOuterPath(
          rect,
          textDirection: data.direction,
        ),
        shadow = cfg.shadow;
    if (shadow != null) {
      if (has('shadow')) {
        silhouette('shadow', dpr);
        final reach = math.max(shadow.radius * dpr / 3, 1.0),
            ox = shadow.offsetX * dpr / 3,
            oy = shadow.offsetY * dpr / 3;
        uniform('shadow', 'in_shadowOffset', [ox, oy]);
        uniform('shadow', 'in_shadowShape', [reach, shadow.dispersion]);
        final c = shadow.color;
        uniform('shadow', 'in_shadowColor', [c.r, c.g, c.b, c.a * cfg.alpha]);
        drawShader(
          canvas,
          'shadow',
          offset,
          Rect.fromLTWH(
            -reach + ox,
            -reach + oy,
            size.width * dpr + reach * 2,
            size.height * dpr + reach * 2,
          ),
          dpr,
        );
      } else {
        canvas.drawPath(
          shapePath.shift(Offset(shadow.offsetX / 3, shadow.offsetY / 3)),
          Paint()
            ..color = shadow.color.withValues(alpha: shadow.color.a * cfg.alpha)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              math.max(shadow.radius / 9, .01),
            ),
        );
      }
    }
    // 不做仿生着色的表面（栏、菜单、栏内按钮）里，材质**就是**它的全部本体：
    // 混色层的 alpha 压不住底下那张不透明的模糊背景图，只调层 alpha 的话，
    // 淡入过程中看到的是「一枚硬边模糊圆片先整个冒出来、颜色再慢慢补上」——
    // 也就是那种「有延迟、不像柔光玻璃」的观感。源端 GlassButtonSurface 因此
    // 给 glass 传 alpha = 1，再用 graphicsLayer{alpha} 整层淡入；这里等价地把
    // alpha 交给 saveLayer，子层一律按满强度画。
    final fadeAsLayer = !cfg.shading;
    final surfaceAlpha = fadeAsLayer ? 1.0 : cfg.alpha;
    canvas.saveLayer(
      rect,
      // saveLayer 只取 paint 的 alpha（RGB 不参与），等价于给整层套 Opacity。
      fadeAsLayer
          ? (Paint()..color = Color.fromRGBO(0, 0, 0, cfg.alpha))
          : Paint(),
    );
    if (backdrop?.snapshot != null && backdrop?.globalOffset != null) {
      final ratio = (dpr / 4).clamp(.5, 1.0);
      final blur = cfg.material?.blurRadius ?? data.style.blur.small / 3;
      final padding = math.max(blur * 1.5, 24.0),
          image = prepare(padding, ratio, surfaceAlpha);
      final src = Rect.fromLTWH(
        padding * ratio,
        padding * ratio,
        size.width * ratio,
        size.height * ratio,
      );
      if (cfg.shading && has('glass')) {
        glassUniforms(image, padding, ratio);
        drawShader(
          canvas,
          'glass',
          offset - Offset(padding, padding),
          src,
          ratio,
        );
      } else {
        // 材质本体：模糊过的背景 + 混色层。折射 shader 缺席时也走这里——
        // 少了折射，但仍是真玻璃，好过退化成一块实色圆片。
        canvas.save();
        // mask shader 缺席时得自己裁形，否则方角会溢出圆角。
        if (!has('mask')) canvas.clipPath(shapePath);
        canvas.drawImageRect(
          image,
          src,
          rect,
          Paint()..filterQuality = FilterQuality.medium,
        );
        if (!_textureBlended) blendLayersNatively(canvas, rect, surfaceAlpha);
        canvas.restore();
      }
    } else {
      // 完全没有背景快照（未接 backdrop / 首帧尚未捕获）才退到实色。
      canvas.drawPath(
        shapePath,
        Paint()
          ..color = data.fill.withValues(alpha: data.fill.a * surfaceAlpha),
      );
    }
    _drawStroke(canvas, offset, dpr, surfaceAlpha);
    if (has('mask')) {
      silhouette('mask', dpr);
      drawShader(
        canvas,
        'mask',
        offset,
        Offset.zero & (size * dpr),
        dpr,
        blendMode: BlendMode.dstIn,
      );
    }
    canvas.restore();
    if (has('rim') && cfg.shading && data.style.background.unShade < .999) {
      final style = data.style, color = cfg.tint ?? data.style.inner.tint;
      silhouette('rim', dpr);
      uniform('rim', 'in_rimEdge', [
        (style.edge.width * dpr / 3).clamp(
          1.0,
          math.max(1.0, size.shortestSide * dpr / 2),
        ),
        math.max(style.edge.pow, .01),
        cfg.alpha,
        0,
      ]);
      uniform('rim', 'in_lightDir', [
        style.light.directionX,
        style.light.directionY,
        style.light.directionZ,
        style.light.angleRange * math.pi,
      ]);
      uniform('rim', 'in_lightAmt', [
        style.light.intensity,
        style.light.oppositeIntensity,
        0,
        0,
      ]);
      uniform('rim', 'in_surface', [color.r, color.g, color.b, 1]);
      drawShader(
        canvas,
        'rim',
        offset,
        Offset.zero & (size * dpr),
        dpr,
        blendMode: BlendMode.plus,
      );
    }
    super.paint(context, offset);
  }
}
