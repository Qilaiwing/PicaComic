#version 460 core
#include <flutter/runtime_effect.glsl>
// Generated from GLASS_RIM_SHADER; upstream 3f7debbf.
// SPDX-License-Identifier: Apache-2.0


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

uniform vec4 in_rimEdge;      // edge width, edge pow, surface opacity, unused
uniform vec4 in_lightDir;     // direction xyz, angle range * pi
uniform vec4 in_lightAmt;     // intensity, opposite intensity, unused, unused
uniform vec4 in_surface;      // the material's own colour, standing in for what is underneath

vec4 shaderMain(vec2 coord) {
    float d = silhouetteSdf(coord);
    // The light rides the outer third of the rim, not all of it. The whole band is what bends the
    // refraction ray — sixty source pixels of it — but the source's own highlight is a hairline
    // two or three pixels wide, and a light spread over the full band comes out five times that
    // and reads as a bevel rather than an edge.
    float edge = max(in_rimEdge.x * kRimBandFraction, 1.0);
    // Past 85% of the band the surface is flat and faces away from both lights.
    if (d > 0.5 || -d >= edge * 0.85) return vec4(0.0);

    vec2 gradient = sdfGradient(coord);
    if (length(gradient) < 0.5) return vec4(0.0);

    float depth = clamp(-d / edge, 0.0, 1.0);
    float slope = min(edgeCurveSlope(depth, in_rimEdge.y), kMaxBevelSlope);
    vec3 normal = normalize(vec3(gradient * slope, 1.0));
    float lighten = rimLighten(normal, in_lightDir, in_lightAmt.xy, in_surface.rgb);
    vec3 added = max(liftToward(in_surface.rgb, lighten) - in_surface.rgb, vec3(0.0));

    float coverage = clamp(0.5 - d, 0.0, 1.0);
    vec3 light = added * (in_rimEdge.z * coverage);
    // Carry an alpha equal to the light, not zero. A shader returns a *premultiplied* colour, and
    // a colour whose channels sit above its own alpha is not one — it is clamped away, which is
    // exactly what silently happened to this pass and to the bloom stroke: both asked for light
    // with no opacity, and both drew nothing at all. Under Plus the alpha adds too, but the
    // surface under the rim is already opaque, so it has nowhere to go.
    return vec4(vec3(light), float(clamp(max(max(light.r, light.g), light.b), 0.0, 1.0)));
}

out vec4 fragColor;
void main() { fragColor = shaderMain(FlutterFragCoord().xy); }
