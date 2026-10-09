//
//  PlaceParticles.swift
//  Respire
//
//  A Place's living air, simulated and drawn on the GPU with Metal, as in a game: a
//  compute pass moves every particle with physics each frame, then they're drawn as
//  instanced quads over the scene. The breath and the visit's progress are read every
//  frame, so wind gusts as you breathe in and fireflies gather as you go.
//
//  Also here: `placeLighting`, the scene's lighting pass (bloom, light shafts,
//  vignette, grain), applied to the drawing as a SwiftUI layer effect.
//

import MetalKit
import SwiftUI

/// What the particles need from the session each frame.
struct PlaceParticleInputs {
    /// Lung volume, 0…1.
    var breath: Double
    /// The step underway (0-based), for stage-by-stage density.
    var stage: Int
    /// The visit's progress, 0…1.
    var progress: Double
}

struct PlaceParticles: UIViewRepresentable {
    let particles: PlaceEnvironment.Particles
    var inputs: () -> PlaceParticleInputs

    func makeCoordinator() -> ParticleRenderer? {
        ParticleRenderer(particles: particles)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator?.device)
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.layer.isOpaque = false
        view.framebufferOnly = true
        view.preferredFramesPerSecond = 60
        view.isUserInteractionEnabled = false
        view.delegate = context.coordinator
        context.coordinator?.inputs = inputs
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator?.inputs = inputs
    }

    static func dismantleUIView(_ view: MTKView, coordinator: ParticleRenderer?) {
        view.isPaused = true
        view.delegate = nil
    }
}

/// Mirrors `ParticleUniforms` in PlaceEffects.metal, field for field.
private struct ParticleUniforms {
    var color: SIMD4<Float>
    var viewSize: SIMD2<Float>
    var regionMin: SIMD2<Float>
    var regionMax: SIMD2<Float>
    var time: Float
    var dt: Float
    var breath: Float
    var progress: Float
    var wind: Float
    var groundY: Float
    var gravity: Float
    var buoyancy: Float
    var drag: Float
    var turbulence: Float
    var sizeMin: Float
    var sizeMax: Float
    var lifeMin: Float
    var lifeMax: Float
    var streak: Float
    var glow: Float
    var kind: Float
    var attract: Float
    var density: Float
    var count: Float
}

/// Mirrors `Particle` in PlaceEffects.metal.
private struct GPUParticle {
    var pos: SIMD2<Float>
    var vel: SIMD2<Float>
    var life: Float
    var maxLife: Float
    var seed: Float
    var state: Float
}

final class ParticleRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    private let queue: MTLCommandQueue
    private let stepPipeline: MTLComputePipelineState
    private let drawPipeline: MTLRenderPipelineState
    private let buffer: MTLBuffer
    private let particles: PlaceEnvironment.Particles
    private let color: SIMD4<Float>
    private var lastTime: CFTimeInterval?
    private let startTime = CACurrentMediaTime()

    var inputs: () -> PlaceParticleInputs = { PlaceParticleInputs(breath: 0.4, stage: 0, progress: 0) }

    init?(particles: PlaceEnvironment.Particles) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let step = library.makeFunction(name: "stepParticles"),
              let vertex = library.makeFunction(name: "particleVertex"),
              let fragment = library.makeFunction(name: "particleFragment"),
              let stepPipeline = try? device.makeComputePipelineState(function: step) else { return nil }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        let attachment = descriptor.colorAttachments[0]
        attachment?.pixelFormat = .bgra8Unorm
        // Premultiplied "over"; glowing particles carry no coverage, so they add light.
        attachment?.isBlendingEnabled = true
        attachment?.sourceRGBBlendFactor = .one
        attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment?.sourceAlphaBlendFactor = .one
        attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        guard let drawPipeline = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }

        // Begin mid-life and spread through the region, so the air is already alive.
        let count = max(particles.count, 1)
        var rng = SeededGenerator(seed: UInt64(particles.kind.rawValue + 1) * 7919)
        let region = particles.region
        let seeded = (0..<count).map { _ -> GPUParticle in
            let life = Float.random(in: Float(particles.life.lowerBound)...Float(particles.life.upperBound), using: &rng)
            let y = particles.kind == .rain || particles.kind == .snow
                ? Float.random(in: Float(region.minY)...Float(min(region.maxY, particles.groundY)), using: &rng)
                : Float.random(in: Float(region.minY)...Float(region.maxY), using: &rng)
            return GPUParticle(
                pos: SIMD2(Float.random(in: Float(region.minX)...Float(region.maxX), using: &rng), y),
                vel: SIMD2(0, particles.kind == .rain ? 0.4 : 0),
                life: Float.random(in: 0...life, using: &rng),
                maxLife: life,
                seed: Float.random(in: 0...1, using: &rng),
                state: 0
            )
        }
        guard let buffer = seeded.withUnsafeBytes({ bytes -> MTLBuffer? in
            guard let base = bytes.baseAddress else { return nil }
            return device.makeBuffer(bytes: base, length: bytes.count, options: .storageModeShared)
        }) else { return nil }

        self.device = device
        self.queue = queue
        self.stepPipeline = stepPipeline
        self.drawPipeline = drawPipeline
        self.buffer = buffer
        self.particles = particles
        let resolved = UIColor(particles.color).cgColor.components ?? [1, 1, 1, 1]
        let rgba = resolved.count >= 4 ? resolved : [resolved[0], resolved[0], resolved[0], resolved.last ?? 1]
        color = SIMD4(Float(rgba[0]), Float(rgba[1]), Float(rgba[2]), Float(rgba[3]))
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        // A steady step, even after a hitch, so the physics never jumps.
        let dt = Float(min(max(now - (lastTime ?? now - 1.0 / 60), 1.0 / 240), 1.0 / 30))
        lastTime = now

        guard let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commands = queue.makeCommandBuffer() else { return }

        let input = inputs()
        let scale = Float(view.contentScaleFactor)
        let p = particles
        var uniforms = ParticleUniforms(
            color: color,
            viewSize: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            regionMin: SIMD2(Float(p.region.minX), Float(p.region.minY)),
            regionMax: SIMD2(Float(p.region.maxX), Float(p.region.maxY)),
            time: Float(now - startTime),
            dt: dt,
            breath: Float(input.breath),
            progress: Float(input.progress),
            wind: Float(p.wind),
            groundY: Float(p.groundY),
            gravity: Float(p.gravity),
            buoyancy: Float(p.buoyancy),
            drag: Float(p.drag),
            turbulence: Float(p.turbulence),
            sizeMin: Float(p.size.lowerBound) * scale,
            sizeMax: Float(p.size.upperBound) * scale,
            lifeMin: Float(p.life.lowerBound),
            lifeMax: Float(p.life.upperBound),
            streak: Float(p.streak),
            glow: p.glow ? 1 : 0,
            kind: Float(p.kind.rawValue),
            attract: Float(p.attract),
            density: Float(min(max(p.density(input.stage), 0), 1)),
            count: Float(p.count)
        )
        let length = MemoryLayout<ParticleUniforms>.stride

        if let compute = commands.makeComputeCommandEncoder() {
            compute.setComputePipelineState(stepPipeline)
            compute.setBuffer(buffer, offset: 0, index: 0)
            compute.setBytes(&uniforms, length: length, index: 1)
            // Whole threadgroups work on every GPU (not all support partial ones);
            // the kernel skips the extra threads in the last group.
            let width = min(stepPipeline.maxTotalThreadsPerThreadgroup, 64)
            let groups = (p.count + width - 1) / width
            compute.dispatchThreadgroups(MTLSize(width: groups, height: 1, depth: 1),
                                         threadsPerThreadgroup: MTLSize(width: width, height: 1, depth: 1))
            compute.endEncoding()
        }

        if let render = commands.makeRenderCommandEncoder(descriptor: pass) {
            render.setRenderPipelineState(drawPipeline)
            render.setVertexBuffer(buffer, offset: 0, index: 0)
            render.setVertexBytes(&uniforms, length: length, index: 1)
            render.setFragmentBytes(&uniforms, length: length, index: 1)
            render.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: p.count)
            render.endEncoding()
        }

        commands.present(drawable)
        commands.commit()
    }
}

// MARK: - Lighting

extension View {
    /// The scene's lighting pass: bloom around bright things, shafts from its main light,
    /// a soft vignette, and fine grain. The light swells a little with the breath.
    func placeLighting(_ light: PlaceEnvironment.Light?, breath: Double, time: Double) -> some View {
        visualEffect { content, proxy in
            let light = light ?? PlaceEnvironment.Light(point: CGPoint(x: 0.5, y: 0.3), color: .white, rays: 0, bloom: 0.4)
            return content.layerEffect(
                ShaderLibrary.placeLight(
                    .float2(proxy.size),
                    .float2(light.point),
                    .color(light.color),
                    .float(light.rays),
                    .float(light.bloom),
                    .float(light.threshold),
                    .float(breath),
                    .float(time)
                ),
                maxSampleOffset: CGSize(width: 150, height: 150)
            )
        }
    }
}
