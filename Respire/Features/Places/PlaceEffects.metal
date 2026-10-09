//
//  PlaceEffects.metal
//  Respire
//
//  The GPU half of a Place, as in a game engine:
//
//  - stepParticles     a compute pass that moves every particle each frame with real
//                      physics: gravity, drag, buoyancy, curl-noise air, wind that
//                      gusts with the breath, splashes and settling on the ground.
//  - particleVertex /  draws them: rain as soft streaks along its velocity, everything
//    particleFragment  else as soft round points; glowing kinds add light.
//  - placeLight        a SwiftUI layer effect over the drawing: bloom around bright
//                      things, light shafts from the scene's main light, and a painterly
//                      finish so the flat vector art reads as made by hand: soft edges
//                      that soften more toward the frame, paper grain, lifted blacks,
//                      gentler color, warm lights and cool shadows. The light swells a
//                      little as you breathe in.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Shared

struct Particle {
    float2 pos;     // fraction of the canvas, from the top-left
    float2 vel;     // canvas heights per second (x is scaled by the aspect when moving)
    float life;     // seconds left
    float maxLife;
    float seed;
    float state;    // 0 in flight; 1 splashing or settled
};

struct ParticleUniforms {
    float4 color;
    float2 viewSize;   // pixels
    float2 regionMin;
    float2 regionMax;
    float time;
    float dt;
    float breath;
    float progress;
    float wind;
    float groundY;
    float gravity;
    float buoyancy;
    float drag;
    float turbulence;
    float sizeMin;     // pixels
    float sizeMax;
    float lifeMin;
    float lifeMax;
    float streak;
    float glow;
    float kind;
    float attract;
    float density;
    float count;       // live particles; extra threads in the last group do nothing
};

enum Kind { rain = 0, snow, motes, fireflies, steam, bubbles, embers, spray };

static float rand(float2 co) {
    return fract(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
}

/// A smooth, slowly evolving field; its curl gives swirling, divergence-free air.
static float airField(float2 p, float t) {
    return sin(p.x * 1.7 + t) * cos(p.y * 1.3 - t * 0.7) + 0.5 * sin(p.x * 3.1 - p.y * 2.3 + t * 1.3);
}

static float2 curl(float2 p, float t) {
    const float e = 0.01;
    float dx = (airField(p + float2(e, 0), t) - airField(p - float2(e, 0), t)) / (2 * e);
    float dy = (airField(p + float2(0, e), t) - airField(p - float2(0, e), t)) / (2 * e);
    return float2(dy, -dx);
}

static void spawn(thread Particle &p, constant ParticleUniforms &u, uint id) {
    float r1 = rand(float2(float(id) * 0.731, u.time * 13.1 + p.seed));
    float r2 = rand(float2(p.seed * 7.3 + u.time, float(id) * 0.37));
    float r3 = rand(float2(r1 + 3.1, r2 + float(id) * 0.013));
    float2 mn = u.regionMin, mx = u.regionMax;
    int kind = int(u.kind);

    switch (kind) {
    case rain:
    case snow:
        p.pos = float2(mix(mn.x - 0.15, mx.x + 0.15, r1), mn.y - 0.05 * r2);
        p.vel = float2(0, kind == rain ? 0.35 + 0.15 * r3 : 0.03 + 0.03 * r3);
        break;
    case steam:
    case bubbles:
    case embers:
        p.pos = float2(mix(mn.x, mx.x, r1), mix(mn.y, mx.y, r2));
        p.vel = float2((r3 - 0.5) * 0.02, -0.02);
        break;
    case spray:
        p.pos = float2(mix(mn.x, mx.x, r1), mix(mn.y, mx.y, r2));
        p.vel = float2((r2 - 0.5) * 0.25, -(0.18 + 0.3 * r3));
        break;
    default:
        p.pos = mix(mn, mx, float2(r1, r2));
        p.vel = float2(0);
        break;
    }
    p.maxLife = mix(u.lifeMin, u.lifeMax, r3);
    p.life = p.maxLife;
    p.state = 0;
}

// MARK: - Physics

kernel void stepParticles(device Particle *particles [[buffer(0)]],
                          constant ParticleUniforms &u [[buffer(1)]],
                          uint id [[thread_position_in_grid]]) {
    if (id >= uint(u.count)) { return; }
    Particle p = particles[id];
    int kind = int(u.kind);
    float dt = u.dt;
    float aspect = u.viewSize.x / max(u.viewSize.y, 1.0);

    p.life -= dt;
    if (p.life <= 0) {
        spawn(p, u, id);
        particles[id] = p;
        return;
    }

    // Settled snow just melts away where it lies.
    if (kind == snow && p.state > 0.5) {
        particles[id] = p;
        return;
    }

    float2 acc = float2(0, u.gravity - u.buoyancy);
    // Drifting air: curl noise in an aspect-correct space, so swirls stay round.
    acc += curl(p.pos * float2(aspect, 1) * 2.5, u.time * 0.15) * u.turbulence * 0.3;
    // Wind that gusts on the in-breath.
    float gust = 0.4 + 1.2 * u.breath + 0.3 * sin(u.time * 0.3 + p.seed * 6.0);
    acc.x += u.wind * gust;
    // Fireflies gather toward the middle as the visit goes on.
    if (u.attract > 0) {
        float2 center = (u.regionMin + u.regionMax) * 0.5;
        acc += (center - p.pos) * u.attract * u.progress;
    }
    // Bubbles wobble side to side as they rise.
    if (kind == bubbles) {
        acc.x += sin(u.time * 3.0 + p.seed * 40.0) * 0.05;
    }

    p.vel += acc * dt;
    p.vel *= max(0.0, 1.0 - u.drag * dt);
    p.pos += float2(p.vel.x / aspect, p.vel.y) * dt;

    // The ground.
    if (p.pos.y >= u.groundY) {
        if (kind == rain && p.state < 0.5) {
            // A drop becomes a small splash that hops up and falls back.
            float r = rand(float2(p.seed, u.time));
            p.state = 1;
            p.pos.y = u.groundY;
            p.vel = float2((r - 0.5) * 0.12, -(0.08 + 0.12 * r));
            p.life = min(p.life, 0.35);
        } else if (kind == snow) {
            p.state = 1;
            p.pos.y = u.groundY + 0.02 * rand(float2(p.seed, 1.7));
            p.vel = float2(0);
            p.life = min(p.life, 2.5);
            p.maxLife = 2.5;
        } else {
            p.life = 0;
        }
    }
    // Bubbles pop at the top; anything far out of the canvas is reborn.
    if (kind == bubbles && p.pos.y < u.regionMin.y) { p.life = 0; }
    if (p.pos.y < -0.2 || p.pos.y > 1.2 || p.pos.x < -0.3 || p.pos.x > 1.3) { p.life = 0; }

    particles[id] = p;
}

// MARK: - Drawing

struct ParticleOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
    float streak;
};

vertex ParticleOut particleVertex(uint vid [[vertex_id]],
                                  uint iid [[instance_id]],
                                  const device Particle *particles [[buffer(0)]],
                                  constant ParticleUniforms &u [[buffer(1)]]) {
    Particle p = particles[iid];
    int kind = int(u.kind);
    float2 corner = float2((vid & 1) ? 1.0 : -1.0, (vid & 2) ? 1.0 : -1.0);
    float t = clamp(p.life / max(p.maxLife, 0.001), 0.0, 1.0);   // 1 at birth, 0 at death

    float size = mix(u.sizeMin, u.sizeMax, fract(p.seed * 91.7));
    float2 pixel = p.pos * u.viewSize;
    float2 velocity = p.vel * u.viewSize.y;

    bool isStreak = u.streak > 0 && p.state < 0.5;
    float2 dir = float2(1, 0);
    float2 half_ = float2(size);
    if (isStreak) {
        float speed = length(velocity);
        dir = speed > 0.001 ? velocity / speed : float2(0, 1);
        half_ = float2(clamp(speed * u.streak, size * 2.0, size * 18.0) * 0.5, size * 0.5);
    } else if (kind == steam) {
        half_ = float2(size * (1.0 + 1.5 * (1.0 - t)));   // steam spreads as it rises
    }
    float2 perp = float2(-dir.y, dir.x);
    pixel += dir * corner.x * half_.x + perp * corner.y * half_.y;

    ParticleOut out;
    out.position = float4(pixel.x / u.viewSize.x * 2.0 - 1.0, 1.0 - pixel.y / u.viewSize.y * 2.0, 0, 1);
    out.uv = corner;
    out.streak = isStreak ? 1.0 : 0.0;

    // Fade in and out over each life, and respect the stage's density.
    float alpha = u.color.a * smoothstep(0.0, 0.2, t) * smoothstep(1.0, 0.9, t);
    if (kind == rain && p.state < 0.5) { alpha = u.color.a * smoothstep(0.0, 0.1, t); }
    if (kind == rain && p.state > 0.5) { alpha = u.color.a * 1.4 * t; }
    if (kind == fireflies) {
        float blink = pow(0.5 + 0.5 * sin(u.time * (0.8 + fract(p.seed * 13.0)) + p.seed * 40.0), 3.0);
        alpha *= 0.15 + 0.85 * blink * (0.75 + 0.25 * u.breath);
    }
    if (fract(p.seed * 53.1) > u.density) { alpha = 0; }
    out.color = float4(u.color.rgb, alpha);
    return out;
}

fragment half4 particleFragment(ParticleOut in [[stage_in]],
                                constant ParticleUniforms &u [[buffer(1)]]) {
    float shape;
    if (in.streak > 0.5) {
        shape = (1.0 - smoothstep(0.2, 1.0, abs(in.uv.y))) * (1.0 - smoothstep(0.5, 1.0, abs(in.uv.x)));
    } else {
        float d = length(in.uv);
        if (d > 1.0) { discard_fragment(); }
        shape = exp(-d * d * 3.5);
    }
    float a = in.color.a * shape;
    // Premultiplied; glowing kinds keep no coverage, so they add light instead of covering.
    return half4(half3(in.color.rgb * a), half(a * (1.0 - u.glow)));
}

// MARK: - Lighting

/// Smooth value noise, for paper grain.
static float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = rand(i), b = rand(i + float2(1, 0)), c = rand(i + float2(0, 1)), d = rand(i + float2(1, 1));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

[[ stitchable ]] half4 placeLight(float2 position, SwiftUI::Layer layer, float2 size, float2 light,
                                  half4 lightColor, float rays, float bloom, float threshold,
                                  float breath, float time) {
    half4 base = layer.sample(position);
    float3 color = float3(base.rgb);

    // Bloom: the bright parts of the scene spread softly into their surroundings.
    // Samples sit on a golden-angle spiral, weighted down with distance, so the glow
    // falls off smoothly instead of showing rings or copies of bright edges.
    float3 glow = float3(0);
    float3 nearby = float3(0);
    float nearbyTotal = 0;
    float total = 0;
    const int taps = 16;
    for (int i = 0; i < taps; i++) {
        float t = (float(i) + 0.5) / float(taps);
        float radius = 16.0 * sqrt(t);
        float angle = float(i) * 2.3999632;
        float weight = 1.0 - t * 0.75;
        float3 s = float3(layer.sample(position + float2(cos(angle), sin(angle)) * radius).rgb);
        glow += max(s - threshold, 0.0) * weight;
        // Only the closest few samples soften edges; farther ones would show as copies.
        if (i < 6) {
            nearby += s;
            nearbyTotal += 1;
        }
        total += weight;
    }

    // Soft edges: a little of the surrounding color everywhere, more toward the frame,
    // like a lens focused on the middle of the scene. Hard vector edges melt slightly.
    float2 uv = position / max(size, float2(1)) - 0.5;
    float edge = smoothstep(0.2, 0.75, length(uv * float2(1.0, 0.85)));
    color = mix(color, nearby / max(nearbyTotal, 1.0), 0.12 + 0.3 * edge);
    color += glow / total * bloom * (0.85 + 0.3 * breath) * 1.4;

    // Light shafts: march toward the light and gather what's bright on the way.
    if (rays > 0.001) {
        float2 source = light * size;
        float2 toLight = source - position;
        float distance = length(toLight);
        float2 dir = toLight / max(distance, 1.0);
        float reach = min(distance, 150.0);
        float gathered = 0;
        float weight = 1;
        const int steps = 14;
        for (int i = 1; i <= steps; i++) {
            float2 q = position + dir * reach * (float(i) / float(steps));
            float3 s = float3(layer.sample(q).rgb);
            float luma = dot(s, float3(0.299, 0.587, 0.114));
            gathered += max(luma - threshold, 0.0) * weight;
            weight *= 0.9;
        }
        float falloff = 1.0 / (1.0 + distance / (0.55 * max(size.x, size.y)));
        color += float3(lightColor.rgb) * gathered / float(steps) * rays * falloff * (0.7 + 0.6 * breath) * 2.2;
    }

    // Paper: fine tooth and broad, uneven washes, as if painted on cold-pressed paper.
    // The tooth is kept fine and faint so it never reads as pixels, even on a bright glow.
    float tooth = valueNoise(position * 1.3);
    float wash = valueNoise(position * 0.012 + 7.3) * 0.65 + valueNoise(position * 0.004 + 2.1) * 0.35;
    color *= 1.0 + (tooth - 0.5) * 0.025 + (wash - 0.5) * 0.08;

    // Gentler color: lifted blacks, softer saturation, warm lights and cool shadows.
    float luma = dot(color, float3(0.299, 0.587, 0.114));
    color = mix(float3(luma), color, 0.86);
    color = color * 0.92 + 0.035;
    color += float3(0.018, 0.008, -0.012) * luma + float3(-0.008, 0.0, 0.016) * (1.0 - luma);

    // A soft vignette, and a breath of film grain so gradients never band.
    color *= 1.0 - 0.3 * smoothstep(0.35, 0.85, length(uv * float2(1.0, 0.85)));
    float grain = rand(floor(position) + fract(time * 13.0) * 91.0) - 0.5;
    color += grain * 0.02;

    // `color` is still premultiplied (it began as the layer's sample).
    return half4(half3(clamp(color, 0.0, float(base.a))), base.a);
}
