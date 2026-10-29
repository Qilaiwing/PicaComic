#version 460 core
#include <flutter/runtime_effect.glsl>
// Generated from GLASS_STROKE_SHADER; upstream 3f7debbf.
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

uniform vec2 in_halfViewFloor; // float size, floored, so the fold lands on a pixel boundary
uniform vec2 in_strokeBand;    // stroke width, inner blur radius
uniform vec4 in_strokeColor;   // stroke rgb, stroke opacity
uniform float in_strokeAlpha;    // surface opacity
uniform vec4 in_light1;        // direction xyz, intensity
uniform vec4 in_light1Color;   // colour rgb, unused
uniform vec4 in_light2;        // direction xyz, intensity
uniform vec4 in_light2Color;   // colour rgb, unused

// The bevel normal. Folded into one quadrant, built there, then unfolded by the sign of the
// offset — the rim is symmetric, so only a quarter of it has to be reasoned about.
vec3 rimNormal(vec2 coord, vec2 half2d, float sdf, float radius, float inner) {
    vec2 offset = coord - in_halfViewFloor;
    vec2 folded = abs(offset);
    // Lift the point off the surface. Depth is measured in the rim band, height in pixels.
    float depth = smoothstep(-inner, 0.0, sdf);
    vec3 point = vec3(folded, -sqrt(max(inner * inner - depth * depth, 0.0)));

    float bevel = max(radius, inner);
    vec2 reference = half2d - bevel;
    reference.x = min(reference.x, folded.x);
    reference.y = min(reference.y, folded.y);
    vec2 toPoint = point.xy - reference;
    float len = length(toPoint);
    reference += ((len > 0.0001) ? toPoint / len : vec2(0.0, 1.0)) * (bevel - inner);

    // Inside the reference the surface is flat and faces straight away from the lights.
    if (folded.x < reference.x || folded.y < reference.y) return vec3(0.0, 0.0, -1.0);

    vec3 normal = normalize(point - vec3(reference, 0.0));
    normal.xy *= sign(offset);
    return normal;
}

// MiBloomStrokeFilter uses fixed vertical falloff axes, independent of the light positions.
// Keep the falloff signed: the native shader clamps the product, not either dot separately.
vec3 rimLight(vec3 normal, float axisY, vec4 light, vec3 color) {
    float falloff = axisY * normal.y;
    float lit = clamp(dot(normal, light.xyz) * falloff, 0.0, 1.0);
    return color * (lit * lit * light.w);
}

vec4 shaderMain(vec2 coord) {
    vec2 half2d = in_size * 0.5;
    vec2 folded = abs(coord - half2d);
    float radius = pickRadius(coord, half2d);
    float inner = max(in_strokeBand.y, 0.5);
    float bevel = max(radius, inner);

    // The interior has no rim to light, and it is most of the surface.
    if (folded.x < half2d.x - bevel && folded.y < half2d.y - bevel) return vec4(0.0);

    float sdf = silhouetteSdf(coord);
    // A near-step band hugging the outer edge, squared the way the source composites it twice.
    float width = max(in_strokeBand.x, 0.75);
    float band = smoothstep(-width, -width + 1.0, sdf);
    vec3 rgb = in_strokeColor.rgb * (in_strokeColor.a * band * band);

    vec3 normal = rimNormal(coord, half2d, sdf, radius, inner);
    rgb += rimLight(normal, -1.0, in_light1, in_light1Color.rgb);
    rgb += rimLight(normal, 1.0, in_light2, in_light2Color.rgb);

    // Light only: alpha stays at zero so a transparent surface never gains opacity from the rim.
    float coverage = clamp(0.5 - sdf, 0.0, 1.0);
    vec3 light = rgb * (in_strokeAlpha * coverage);
    // Premultiplied, so the alpha has to match the light — see the rim pass for why zero loses it.
    return vec4(vec3(light), float(clamp(max(max(light.r, light.g), light.b), 0.0, 1.0)));
}

out vec4 fragColor;
void main() { fragColor = shaderMain(FlutterFragCoord().xy); }
