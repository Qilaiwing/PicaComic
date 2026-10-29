// Miuix Flutter 移植版 - Glass shader uniform layouts（自动生成）
// 源自 compose-miuix-ui/miuix 的 miuix-glass，基准 3f7debbf。
// 由 tool/gen_os4_assets.mjs 生成，请勿手改。
// SPDX-License-Identifier: Apache-2.0

const miuixGlassUniforms = <String, Map<String, int>>{
  'glass': {
    'u_textureSize': 0,
    'in_pad': 2,
    'in_maxCoord': 4,
    'in_alphaEdge': 6,
    'in_iorRefl': 10,
    'in_tint': 14,
    'in_whiteMixBg': 18,
    'in_darker': 22,
    'in_lightDir': 26,
    'in_lightAmt': 30,
    'in_lumCurve': 34,
    'in_satBri': 38,
    'in_edgePow': 42,
    'in_size': 46,
    'in_radii': 48,
    'in_smoothing': 52,
  },
  'mask': {'in_size': 0, 'in_radii': 2, 'in_smoothing': 6},
  'stroke': {
    'in_size': 0,
    'in_radii': 2,
    'in_smoothing': 6,
    'in_halfViewFloor': 7,
    'in_strokeBand': 9,
    'in_strokeColor': 11,
    'in_strokeAlpha': 15,
    'in_light1': 16,
    'in_light1Color': 20,
    'in_light2': 24,
    'in_light2Color': 28,
  },
  'shadow': {
    'in_size': 0,
    'in_radii': 2,
    'in_smoothing': 6,
    'in_shadowOffset': 7,
    'in_shadowShape': 9,
    'in_shadowColor': 11,
  },
  'rim': {
    'in_size': 0,
    'in_radii': 2,
    'in_smoothing': 6,
    'in_rimEdge': 7,
    'in_lightDir': 11,
    'in_lightAmt': 15,
    'in_surface': 19,
  },
  'blend': {
    'u_textureSize': 0,
    'in_blend0': 2,
    'in_blend1': 6,
    'in_blend2': 10,
    'in_blendMode': 14,
  },
};
