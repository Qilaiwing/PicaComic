#version 460 core
#include <flutter/runtime_effect.glsl>
// Generated from GLASS_SHADOW_SHADER; upstream 3f7debbf.
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

uniform vec2 in_shadowOffset;  // displacement in pixels
uniform vec2 in_shadowShape;   // reach, dispersion
uniform vec4 in_shadowColor;   // rgb, strength

vec4 shaderMain(vec2 coord) {
    float d = silhouetteSdf(coord - in_shadowOffset);
    float reach = max(in_shadowShape.x, 0.5);
    float t = clamp(1.0 - d / reach, 0.0, 1.0);
    // Dispersion reshapes the falloff: below a float it hugs the edge, above it spreads and thins.
    float falloff = pow(t, 1.0 / max(in_shadowShape.y, 0.05));
    float a = falloff * in_shadowColor.a;
    return vec4(vec3(in_shadowColor.rgb * a), float(a));
}

out vec4 fragColor;
void main() { fragColor = shaderMain(FlutterFragCoord().xy); }
