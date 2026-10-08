//
//  PrismShaders.metal
//  Respire
//
//  SwiftUI color-effect shaders:
//
//  - frost:    ice crystals for the glass cards. A Voronoi pattern whose cell
//              edges read as frozen seams, creeping in from the rim and corners
//              and fading to clear glass in the middle, with a few tiny glints.
//  - prismOrb: the rainbow breath. A ring of spectrum light whose radius follows
//              the breath, with hue running around the circle and slow caustic
//              ripples flowing through it, like light through moving water.
//
//  - aurora:   the northern lights over Aurora Lake.
//  - cymatics: standing waves on water, the Cymatics world. Opaque, so it
//              paints the whole scene.
//
//  The others return premultiplied color, so they can be layered with plus-lighter.
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

/// A standing-wave figure on water: `folds` plane waves at evenly spread angles (a
/// quasi-crystal mandala), the bowl's own rings, and petals around the center. Every
/// term shares the same symmetry, so the figure is always a true mandala.
static float cymaticField(float2 p, float folds, float k) {
    float quasi = 0.0;
    for (int j = 0; j < 12; j++) {
        if (float(j) >= folds) { break; }
        float a = M_PI_F * float(j) / folds;
        quasi += cos(k * dot(p, float2(cos(a), sin(a))));
    }
    // Normalized so the lace is equally strong everywhere, brightest at the very center.
    quasi /= sqrt(folds);
    float r = length(p);
    float theta = atan2(p.y, p.x);
    // Rings and petals belong to the bowl's heart; the lace takes over toward the rim.
    float rings = cos(k * r) * (1.0 - 0.6 * r);
    float petals = cos(2.0 * folds * theta) * sin(k * 0.5 * r) * (1.0 - r);
    return quasi * 0.8 + rings * 0.3 + petals * 0.2;
}

/// Cymatics: a dark bowl of water seen from above, singing. The figure's symmetry
/// comes from the tone (`folds`, `scale`, `hue`); the breath unfolds it from the
/// center to the rim and makes it more intricate; `stillness` (1 at the turns of the
/// breath and in holds) draws its lines fine and crisp, while in motion the grains dance.
/// Faint echoes ripple out past the rim, into the dark.
[[ stitchable ]] half4 cymatics(float2 position, half4 color, float2 size, float breath, float time,
                                float folds, float scale, float stillness, float hue) {
    float2 center = size * 0.5;
    float unit = min(size.x, size.y) * 0.44;
    float2 q = (position - center) / unit;
    float r = length(q);

    // The whole figure turns, slow enough to notice only over a minute.
    float spin = time * 0.012;
    float2 p = float2(q.x * cos(spin) - q.y * sin(spin), q.x * sin(spin) + q.y * cos(spin));

    // Breathing in, more waves fit the bowl and the figure grows intricate.
    float k = mix(13.0, 34.0, breath) * scale;
    float f = cymaticField(p, folds, k);

    // The figure reaches out from the center with the breath, and fades at the rim.
    float reach = mix(0.45, 1.0, breath);
    float envelope = (1.0 - smoothstep(reach - 0.3, reach, r)) * (1.0 - smoothstep(0.9, 1.0, r));

    // A standing wave: the still lines never move, while the crests swell and sink between them.
    float swing = 0.55 + 0.45 * cos(time * 0.8);
    float width = mix(0.2, 0.05, stillness);
    float nodal = exp(-pow(f / width, 2.0));
    // A soft bloom around each line, so the figure glows rather than merely draws.
    float bloom = exp(-pow(f / (width * 3.5), 2.0)) * 0.3;
    float crest = min(pow(max(f, 0.0), 2.5), 1.5) * swing;
    // The water itself holds a faint pearly light, so the figure sits in something, not nothing.
    float surface = pow(0.5 + 0.5 * f, 2.0) * 0.16;

    // Grains: resting on the lines when still, dancing when the breath moves.
    float2 cell = floor(position / 2.0);
    float rest = hash21(cell) * 0.35;
    float dance = step(0.975, hash21(cell + floor(time * 18.0))) * (1.0 - stillness);
    float grain = (rest + dance * 2.0) * exp(-pow(f / 0.3, 2.0));
    // Rare glints on the crests, like light catching moving water.
    float glint = step(0.996, hash21(cell * 0.5 + floor(time * 3.0))) * crest;

    float light = (nodal * 1.25 + bloom + crest * 0.55 + surface + grain * 0.35 + glint * 1.5) * envelope;

    // Pearly light shading through the prism from the center out, tinted by the tone.
    float3 tint = spectrum(fract(hue + 0.12 * f + 0.22 * r));
    float3 pearl = mix(float3(1.0), tint, 0.62);

    // The bowl: deep blue-black water, a brass rim, a breath of glow at the heart.
    float3 water = float3(0.012, 0.018, 0.034) * (1.0 - 0.4 * r);
    float inside = 1.0 - smoothstep(0.995, 1.005, r);
    float rim = exp(-pow((r - 1.02) / 0.014, 2.0));
    float3 brass = float3(0.78, 0.6, 0.34) * (0.55 + 0.45 * (0.5 + 0.5 * q.y / max(r, 0.001)));
    float heart = exp(-r * r / 0.015) * (0.08 + 0.22 * breath);

    // Echoes radiating outward beyond the bowl, the sound carrying into the room.
    float outside = smoothstep(1.04, 1.12, r) * exp(-(r - 1.0) * 1.6);
    float echo = exp(-pow((fract(r * 1.6 - time * 0.06) - 0.5) / 0.03, 2.0)) * outside * (0.04 + 0.08 * breath);

    float3 rgb = water * inside
        + pearl * light * inside
        + tint * heart
        + brass * rim * 0.55
        + mix(float3(1.0), tint, 0.6) * echo;
    return half4(half3(rgb), 1.0);
}
