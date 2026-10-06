//
//  PrismShaders.metal
//  Respire
//
//  Two small SwiftUI color-effect shaders:
//
//  - frost:    ice crystals for the glass cards. A Voronoi pattern whose cell
//              edges read as frozen seams, creeping in from the rim and corners
//              and fading to clear glass in the middle, with a few tiny glints.
//  - prismOrb: the rainbow breath. A ring of spectrum light whose radius follows
//              the breath, with hue running around the circle and slow caustic
//              ripples flowing through it, like light through moving water.
//
//  Both return premultiplied color, so they can be layered with plus-lighter.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float2 hash22(float2 p) {
    float n = hash21(p);
    return float2(n, hash21(p + n + 17.17));
}

/// Hue (0...1) to a saturated RGB.
static float3 spectrum(float h) {
    float3 k = float3(0.0, 4.0, 2.0);
    float3 rgb = abs(fmod(h * 6.0 + k, 6.0) - 3.0) - 1.0;
    return clamp(rgb, 0.0, 1.0);
}

[[ stitchable ]] half4 frost(float2 position, half4 color, float2 size, float seed) {
    // Frost creeps in from the rim: strongest at the edges and corners, clear in
    // the middle where the text sits.
    float2 toEdge = min(position, size - position);
    float edgeDistance = min(toEdge.x, toEdge.y);
    float cornerDistance = length(max(float2(48.0) - toEdge, float2(0.0)));
    float rim = 1.0 - smoothstep(0.0, 34.0, edgeDistance);
    float corner = smoothstep(0.0, 48.0, cornerDistance);
    float amount = max(rim * 0.8, corner);
    if (amount < 0.01) { return half4(0.0); }

    // Crystals, larger near the corners.
    float2 uv = position / 34.0;
    float2 cell = floor(uv);
    float2 f = fract(uv);
    float d1 = 8.0;
    float d2 = 8.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 g = float2(float(x), float(y));
            float2 o = hash22(cell + g + seed);
            float d = length(g + o - f);
            if (d < d1) { d2 = d1; d1 = d; }
            else if (d < d2) { d2 = d; }
        }
    }
    float seam = 1.0 - smoothstep(0.0, 0.05, d2 - d1);
    // A soft frosted haze under the seams.
    float haze = 0.05 * amount;
    // Rare glints, only where there's frost.
    float glint = step(0.997, hash21(floor(position / 1.5) + seed * 3.1)) * amount;

    float a = haze + seam * 0.12 * amount + glint * 0.45;
    return half4(half(a), half(a), half(a), half(a));
}

[[ stitchable ]] half4 prismOrb(float2 position, half4 color, float2 size, float breath, float time) {
    float2 center = size * 0.5;
    float2 p = position - center;
    float unit = min(size.x, size.y) * 0.5;
    float r = length(p) / unit;          // 0 at the center, 1 at the edge
    float angle = atan2(p.y, p.x);

    float radius = mix(0.34, 0.82, breath);

    // Hue around the circle, turning slowly.
    float hue = fract(angle / (2.0 * M_PI_F) + time * 0.025);
    float3 rgb = mix(float3(1.0), spectrum(hue), 0.82);

    // Light flowing through the ring like water.
    float caustic = 0.5 + 0.5 * sin(r * 34.0 - time * 1.6 + sin(angle * 7.0 + time * 0.7) * 1.8);

    float ring = exp(-pow((r - radius) / 0.045, 2.0));
    float halo = exp(-pow((r - radius) / 0.2, 2.0)) * 0.5;
    float core = (1.0 - smoothstep(0.0, radius, r)) * 0.22;

    float a = clamp(ring * 0.9 + halo * (0.45 + 0.55 * caustic) + core * caustic, 0.0, 1.0);
    return half4(half3(rgb * a), half(a));
}

static float valueNoise(float x, float salt) {
    float i = floor(x);
    float f = fract(x);
    float a = hash21(float2(i, salt));
    float b = hash21(float2(i + 1.0, salt));
    float u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u);
}

/// Northern lights: three curtains of light hanging from slowly waving
/// baselines, streaked with fine vertical rays, green at the hem shading to
/// violet as they rise. `strength` scales the whole effect (dim it behind text).
[[ stitchable ]] half4 aurora(float2 position, half4 color, float2 size, float time, float strength) {
    float2 uv = position / max(size, float2(1.0));
    float3 rgb = float3(0.0);
    float alpha = 0.0;

    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float base = 0.22 + 0.09 * fi
            + 0.07 * sin(uv.x * (3.0 + fi) + time * (0.10 + 0.04 * fi) + fi * 2.1)
            + 0.03 * sin(uv.x * 11.0 - time * 0.18 + fi * 1.7);
        float above = base - uv.y;
        float height = 0.16 + 0.12 * valueNoise(uv.x * 5.0 + time * 0.08 + fi * 9.0, 7.0 + fi);
        float hem = smoothstep(-0.015, 0.012, above);
        float rise = exp(-max(above, 0.0) / height * 2.0);
        float rays = 0.45 + 0.55 * valueNoise(uv.x * 70.0 + time * 0.5 + fi * 31.0, 13.0 + fi);
        float edges = smoothstep(0.0, 0.12, uv.x) * smoothstep(1.0, 0.88, uv.x);
        float k = hem * rise * rays * edges * (0.55 - 0.12 * fi);
        float t = clamp(max(above, 0.0) / height + fi * 0.2, 0.0, 1.0);
        float3 c = mix(float3(0.22, 1.0, 0.58), float3(0.58, 0.36, 1.0), t);
        rgb += c * k;
        alpha += k;
    }

    alpha = clamp(alpha * strength, 0.0, 1.0);
    rgb = min(rgb * strength, float3(alpha));
    return half4(half3(rgb), half(alpha));
}
