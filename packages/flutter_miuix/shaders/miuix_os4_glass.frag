#version 460 core
#include <flutter/runtime_effect.glsl>
// Generated from GLASS_SHADER; upstream 3f7debbf.
// SPDX-License-Identifier: Apache-2.0
uniform vec2 u_textureSize;

uniform sampler2D child;
vec4 sampleChild(vec2 p) { return texture(child, p / u_textureSize); }

uniform vec2 in_pad;          // component origin inside the padded layer
uniform vec2 in_maxCoord;     // sampling clamp of the padded layer
uniform vec4 in_alphaEdge;    // alpha, edge width, thickness, reflect offset
uniform vec4 in_iorRefl;      // ior, reflect strength, reflect lighten, colour gamma
uniform vec4 in_tint;         // tint rgb, tint strength
uniform vec4 in_whiteMixBg;   // colour white, colour mix, backdrop saturation, backdrop brightness
uniform vec4 in_darker;       // darker start, darker end, darker, inner bottom
uniform vec4 in_lightDir;     // direction xyz, angle range * pi
uniform vec4 in_lightAmt;     // intensity, opposite intensity, luminance amount, overspill
uniform vec4 in_lumCurve;     // cubic coefficients A, B, C, D
uniform vec4 in_satBri;       // saturation, brightness, burn, unshade
uniform vec4 in_edgePow;      // edge pow, wide-sample radius

const vec3 kCurveWeights = vec3(0.2125, 0.7153, 0.0721);
const vec3 kShadowTint = vec3(0.07874, 0.02848, 0.09278);

// ------------------------------------------------- silhouette and edge profile

uniform vec2 in_size;         // component size
uniform vec4 in_radii;        // topLeft, topRight, bottomRight, bottomLeft
uniform float in_smoothing;     // 0 = circular corner, 1 = continuous corner

float roundedBoxSdf(vec2 p, vec2 b, float r) {
    vec2 d = p - b + r;
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2(0.0))) - r;
}

float supercircleSdf(vec2 off, float tile) {
    vec2 q = max(vec2(0.0), (vec2(tile) + off) / tile);
    float hi = max(q.x, q.y);
    float ratio = (hi == 0.0) ? 0.0 : clamp(min(q.x, q.y) / hi, 0.0, 1.0);
    float fit = ((((-0.7391197269 * ratio + 2.4034927648) * ratio + -2.4907319173) * ratio + 0.4768708960) * ratio + 0.4747847594);
    float len = length(q);
    float distBase = (len + 1.0) - 1.0 / (1.0 - ratio * ratio * clamp(len, 0.0, 1.0) * fit);
    return min(max(tile + off.x, tile + off.y), 0.0) + tile * (distBase - 1.0);
}

float pickRadius(vec2 local, vec2 b) {
    float top = (local.x < b.x) ? in_radii.x : in_radii.y;
    float bottom = (local.x < b.x) ? in_radii.w : in_radii.z;
    return min((local.y < b.y) ? top : bottom, min(b.x, b.y));
}

float sdfShape(vec2 p, vec2 b, float r) {
    float box = roundedBoxSdf(p, b, r);
    float minHalf = min(b.x, b.y);
    if (in_smoothing <= 0.001 || r < 0.5 || (minHalf - r) <= 1.0) {
        return box;
    }
    float tile = min(1.5286649465560913 * r, minHalf);
    return mix(box, supercircleSdf(p - b, tile), in_smoothing);
}

// Distance to the silhouette from a point in component space. Negative inside.
float silhouetteSdf(vec2 local) {
    vec2 b = in_size * 0.5;
    return sdfShape(abs(local - b), b, pickRadius(local, b));
}


const vec3 kLumaWeights = vec3(0.2126, 0.7152, 0.0722);

float luma(vec3 color) {
    return dot(color, kLumaWeights);
}

float smooth5Map(float t) {
    t = clamp(mix(0.5, 1.0, t), 0.0, 1.0);
    t = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    return (t - 0.5) * 2.0;
}

// Depth 0 at the silhouette, 1 once the surface is flat. `p` shapes how fast it gets there.
float edgeCurve(float x, float p) {
    if (x >= 0.85) return 1.0;
    float c = smooth5Map(sqrt(clamp(x, 0.0, 1.0)));
    return 1.0 - pow(1.0 - c, p);
}

// Slope of `edgeCurve` in `x`.
//
// The source effect differentiates the rim profile with a one-*display*-pixel step, which against
// a sixty-pixel band is as good as exact. The material pass runs on the downscaled backdrop layer,
// where the smallest honest step is several display pixels — a sixth of the band — and a step that
// coarse does not measure the turn, it averages it away: the tilt it reports far inside the band
// is seven times the real one, and the rim reads as a dome instead of an edge. Differentiating the
// curve in closed form removes the step, and with it the resolution the answer depends on.
float edgeCurveSlope(float x, float p) {
    if (x >= 0.85) return 0.0;
    float t = sqrt(clamp(x, 0.000001, 1.0));
    float u = 0.5 + 0.5 * t;
    float um = u - 1.0;
    float c = smooth5Map(t);
    // d(smooth5Map(sqrt x))/dx, the quintic's derivative carried through the square root.
    float slope = 15.0 * u * u * um * um / t;
    return p * pow(max(1.0 - c, 0.0), p - 1.0) * slope;
}

// Direction the distance field grows in: a unit vector pointing out of the shape. The unshaped
// field is locally a plane, so a float-pixel difference reads it exactly.
vec2 sdfGradient(vec2 local) {
    float dx = silhouetteSdf(local + vec2(0.5, 0.0)) - silhouetteSdf(local - vec2(0.5, 0.0));
    float dy = silhouetteSdf(local + vec2(0.0, 0.5)) - silhouetteSdf(local - vec2(0.0, 0.5));
    vec2 gradient = vec2(dx, dy);
    float length2d = length(gradient);
    return (length2d < 0.0001) ? vec2(0.0) : gradient / length2d;
}

// Lifts a colour toward white without clipping: the gain is applied around a luminance-dependent
// pivot, so bright pixels move less than dark ones.
vec3 liftToward(vec3 color, float amount) {
    float v = luma(color);
    float w = smoothstep(0.0, 0.5, v);
    float k = mix(1.0 - v, v, w);
    float gain = 1.0 + smoothstep(0.0, 1.0, amount) * mix(0.75, 0.4, w);
    return (color + k) * gain - k;
}

float dynamicAdd(vec3 color) {
    float toWhite = smoothstep(0.2, 1.0, distance(vec3(1.0), color));
    return mix(0.8, mix(0.2, 1.0, toWhite), luma(color));
}

// acos is not worth its cost here; this is the usual sqrt-based polynomial fit.
float lightFalloff(vec3 normal, vec3 direction, float intensity, float angleRange) {
    float dp = dot(normal, direction);
    float d = clamp(dp, -1.0, 1.0);
    float u = 1.0 - d;
    float positive = sqrt(u) * (u * (u * 0.04587603 + 0.10884186) + 1.41502593);
    float angle = (d < 0.0) ? (3.14159265 - positive) : positive;
    return max(dp, 0.0) * max(intensity * (1.0 - angle / max(angleRange, 0.0001)), 0.0);
}

// How much light the rim carries where neither directional light reaches. Calibrated so the sides
// between the two lit arcs come out about a dozen levels above the surface, as the source does.
const float kEdgeAmbient = 0.24;

// How much of the rim band the light rides, measured from the silhouette inward. The band itself
// is what bends the refraction ray; the highlight the source draws on it is a hairline.
const float kRimBandFraction = 0.33;

// How far the two lights lift a surface of `color`, in `[0, 1]`. The second light points the
// opposite way in x and y, so one direction lights both sides of the shape.
float rimLighten(vec3 normal, vec4 lightDir, vec2 amounts, vec3 color) {
    vec3 lit = vec3(normal.x, -normal.y, normal.z);
    float primary = lightFalloff(lit, lightDir.xyz, amounts.x, lightDir.w);
    float opposite = lightFalloff(lit, lightDir.xyz * vec3(-1.0, -1.0, 1.0), amounts.y, lightDir.w);
    // Two opposed lights alone leave two lit arcs and two dark ones. The source rim is continuous:
    // measured round a 44dp button, the two arcs the lights own come out about thirty levels above
    // the surface and the sides between them still ten to fifteen — lit, not dark. An ambient term
    // proportional to how far the rim has turned away from the viewer is what joins them up, and
    // the compositor's own shader carries one under that name.
    float edgeFactor = clamp(length(lit.xy), 0.0, 1.0);
    float raw = clamp(primary + opposite + kEdgeAmbient * edgeFactor, 0.0, 1.0) * dynamicAdd(color);
    raw = pow(clamp(raw, 0.0, 1.0), 0.85);
    // A soft knee, tighter over a bright backdrop: full light lifts the rim about float way, never
    // to white. Without it the whole edge band clips and the hairline has nothing left to sit on.
    float knee = mix(1.0, 0.7, smoothstep(0.0, 0.5, luma(color)));
    return raw / (raw + knee);
}

// The steepest the bevel is allowed to get, as a rise over a run.
//
// The closed-form slope runs to the thousands at the silhouette, which stands the normal on end
// and hands both lights everything they can take. The source system never sees that: it reads its
// normal out of a cached corner image, and an image has a resolution, so the tilt it reports tops
// out. Measured against its own rim — peak twenty-nine levels above the surface, about two pixels
// wide — the cap it behaves as though it has is a little under sixty degrees.
const float kMaxBevelSlope = 1.7;

// ------------------------------------------------------------------ sampling

vec4 tapLayer(vec2 local) {
    return vec4(sampleChild(clamp(local + in_pad, vec2(0.5), in_maxCoord)));
}

// The refraction and reflection rays reach past the silhouette, and the recorded layer only
// carries backdrop for as far as the blur padding. A tap that lands beyond it returns transparent
// black, which would ring the whole shape in a dark halo, so fall back to the nearest tap that is
// inside the surface itself.
vec4 sampleBackdrop(vec2 local) {
    vec4 col = tapLayer(local);
    if (col.a < 0.02) {
        col = tapLayer(clamp(local, vec2(0.5), in_size - 0.5));
    }
    if (col.a > 0.004) {
        col = vec4(col.rgb / col.a, 1.0);
    }
    float t = smoothstep(in_darker.x, in_darker.y, luma(col.rgb)) * in_darker.z;
    col.rgb = mix(col.rgb, kShadowTint, t);
    return col;
}

// Stands in for the second, far wider blur the source effect samples.
//
// The taps sit on a Vogel spiral — radius grows as the square root of the index, and each step
// turns by the golden angle — which covers the disc evenly instead of leaving the middle empty.
// That evenness is the whole point: a sparse ring makes each tap a hard threshold, and a bright
// object behind the surface crosses one tap at a time, painting the rectangles a ring pattern
// leaves behind. Twenty-five taps put neighbouring samples closer together than the blur already
// on the layer, so the result is smooth wherever it is read.
//
// Taps are averaged by coverage, not by count: the padded layer runs out before the widest taps
// do, and weighting by alpha lets a tap that lands past the recorded backdrop contribute nothing
// rather than pull the colour toward black.
vec4 sampleWide(vec2 local) {
    vec2 outer = in_edgePow.yz;
    if (outer.x <= 0.5 || outer.y <= 0.5) return sampleBackdrop(local);
    // The source effect's colour texture is blurred at a radius far larger than any surface it
    // sits on, so across a bar or a button it is very nearly one colour. `in_edgePow.w` says how
    // completely: at 1 the disc is centred on the surface and every pixel reads the same average,
    // which is what stops a photograph behind the glass from mottling it. Only a surface wider
    // than the blur reach keeps the sample under the pixel that reads it.
    vec2 origin = mix(local, in_size * 0.5, in_edgePow.w);
    vec3 sum = vec3(0.0);
    float coverage = 0.0;
    for (int i = 0; i < 25; i++) {
        float index = float(i);
        float radius = sqrt((index + 0.5) * 0.04);
        float angle = index * 2.39996323;
        vec4 tap = tapLayer(origin + vec2(cos(angle), sin(angle)) * radius * outer);
        sum += tap.rgb;
        coverage += tap.a;
    }
    if (coverage < 0.0001) return sampleBackdrop(local);
    vec3 color = sum / coverage;
    float t = smoothstep(in_darker.x, in_darker.y, luma(color)) * in_darker.z;
    return vec4(mix(color, kShadowTint, t), 1.0);
}

// ------------------------------------------------------------------- grading

vec4 adjustColor(vec4 color, float saturation, float brightness) {
    float l = dot(color.rgb, kCurveWeights);
    return vec4(mix(vec3(l), color.rgb, saturation) + vec3(brightness * color.a), color.a);
}

vec4 luminanceCurve(vec4 color) {
    float a = max(color.a, 0.0001);
    vec3 straight = color.rgb / a;
    float l = clamp(dot(straight, kCurveWeights), 0.0, 1.0);
    float adjusted = ((in_lumCurve.x * l + in_lumCurve.y) * l + in_lumCurve.z) * l + in_lumCurve.w;
    adjusted = clamp(adjusted, 0.0, 1.0);
    float scale = adjusted / max(l, 0.01) * smoothstep(0.0, 0.1, l);
    return vec4(mix(straight, straight * scale, in_lightAmt.z) * a, color.a);
}

vec4 processColor(vec4 color) {
    color = luminanceCurve(color);
    color.rgb = adjustColor(color, in_satBri.x, in_satBri.y).rgb;
    return color;
}

vec4 processGlassColor(vec4 material, vec2 local) {
    vec4 wide = adjustColor(sampleWide(local), in_whiteMixBg.z, in_whiteMixBg.w);
    wide.rgb = mix(wide.rgb, vec3(1.0), in_whiteMixBg.x);

    float lumin = clamp(luma(wide.rgb), 0.0, 1.0);
    float burn = pow(lumin, max(in_satBri.z, 0.5)) - 0.5;
    float colorRatio = 0.8 * mix(lumin, 1.0, (1.587 * burn * burn * burn) + 0.5);

    vec3 ratio = mix(vec3(1.0), wide.rgb, colorRatio);
    float mean = (ratio.r + ratio.g + ratio.b) * 0.33333333;
    // Pull near-grey backdrops all the way to grey so the glass never picks up a false cast.
    ratio = mix(vec3(mean), ratio, smoothstep(0.0, 0.4, distance(wide.rgb, vec3(mean))));
    ratio = mix(ratio, in_tint.rgb, in_tint.a);

    material.rgb *= ratio;
    material.rgb = mix(material.rgb, ratio, in_whiteMixBg.y * colorRatio);
    return material;
}

vec3 addLight(vec3 color, vec3 lightColor, float strength) {
    float toWhite = smoothstep(0.2, 1.0, distance(vec3(1.0), color));
    return color + lightColor * strength * mix(0.3, 1.0, toWhite);
}

// ---------------------------------------------------------------------- main

// The material at one point, given how deep into the rim it is and which way the rim faces.
//
// `d` is passed in rather than measured: the caller walks it across a pixel, and over that
// distance the distance field is a plane, so stepping the value is both exact and free.
vec4 shadeMaterial(vec2 local, float d, vec2 gradient, float edge) {
    float depth = clamp(-d / edge, 0.0, 1.0);
    float shaped = edgeCurve(depth, in_edgePow.x);
    // The reflection and the added light ride the same outer third of the band the rim light does.
    // Spread across the whole band they come out as a soft halo several times wider than the edge
    // the source draws, because this pass cannot resolve where the turn actually is.
    float nmlZ = edgeCurve(min(depth / kRimBandFraction, 1.0), 1.0);

    bool isFlat = shaped >= 1.0;
    vec3 normal = isFlat
        ? vec3(0.0, 0.0, 1.0)
        : normalize(vec3(gradient * edgeCurveSlope(depth, in_edgePow.x), 1.0));

    vec2 refractUv = local;
    if (!isFlat) {
        vec3 bent = refract(vec3(0.0, 0.0, -1.0), normal, 1.0 / max(in_iorRefl.x, 1.0));
        float thickness = in_alphaEdge.z;
        refractUv += bent.xy * mix((thickness - edge) * 2.0, thickness * 2.0, shaped);
    }
    vec4 material = sampleBackdrop(refractUv);

    float rimZ = 1.0 - nmlZ;
    vec4 mirrored = vec4(0.0);
    if (rimZ > 0.000001) {
        vec3 bounced = reflect(vec3(0.0, 0.0, -1.0), normal);
        mirrored = sampleBackdrop(local + bounced.xy * (in_alphaEdge.w * (1.0 - shaped)));
        material = mix(material, mirrored, clamp(rimZ * in_iorRefl.y, 0.0, 1.0));
    }
    material.rgb = addLight(material.rgb, mirrored.rgb, (1.0 - shaped) * in_iorRefl.z);

    material = processColor(material);
    material = processGlassColor(material, local);

    // Additive glow along the bottom edge.
    float bottom = smoothstep(1.0, 0.0, 1.0 - local.y / max(in_size.y, 1.0));
    material.rgb += bottom * bottom * in_darker.w;


    material = pow(max(material, vec4(0.0)), vec4(in_iorRefl.w));
    material.rgb = mix(clamp(material.rgb, 0.0, 1.0), in_tint.rgb, in_satBri.w);
    return material;
}

// ---------------------------------------------------------------------- main

vec4 shaderMain(vec2 coord) {
    vec2 local = coord - in_pad;
    float d = silhouetteSdf(local);
    // Overspill the silhouette: the mask pass trims the edge at full resolution, so this one only
    // has to reach past it.
    if (d >= in_lightAmt.w) return vec4(0.0);

    // A fully unshaded style is a flat tinted shape; skip the whole material.
    if ((1.0 - in_satBri.w) <= 0.000001) {
        float flatAlpha = in_alphaEdge.x;
        return vec4(vec3(in_tint.rgb * flatAlpha), float(flatAlpha));
    }

    float edge = max(in_alphaEdge.y, 1.0);
    vec2 gradient = sdfGradient(local);
    vec4 material;

    // Now that the normal is exact, the lit part of the rim is a few display pixels wide — less
    // than one pixel of this layer. Read once per pixel it would alias into a staircase, so inside
    // the band the material is integrated across the pixel instead. One dimension is enough: the
    // rim varies along the distance field's gradient and is constant across it.
    if (-d < edge && length(gradient) > 0.5) {
        material = shadeMaterial(local - gradient * 0.375, d - 0.375, gradient, edge) * 0.25;
        material += shadeMaterial(local, d, gradient, edge) * 0.5;
        material += shadeMaterial(local + gradient * 0.375, d + 0.375, gradient, edge) * 0.25;
    } else {
        material = shadeMaterial(local, d, gradient, edge);
    }

    float alpha = material.a * in_alphaEdge.x;
    return vec4(vec3(material.rgb * alpha), float(alpha));
}

out vec4 fragColor;
void main() { fragColor = shaderMain(FlutterFragCoord().xy); }
