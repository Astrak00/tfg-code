import Foundation
import Metal
import MetalKit

struct CameraParams {
    var aspectRatio: Float
    var imageWidth: UInt32
    var samplesPerPixel: UInt32
    var maxDepth: UInt32
    var vfov: Float
    var defocusAngle: Float
    var focusDist: Float
    var padding: Float
    var lookFrom: SIMD3<Float>
    var lookAt: SIMD3<Float>
    var vup: SIMD3<Float>
}

@main
struct App {
    static func main() throws {
        // Parse CLI args to match other implementations
        var inputPath: String? = nil
        var outputPath: String? = nil
        var cores: Int = 1
        var i = 1
        let args = CommandLine.arguments
        while i < args.count {
            switch args[i] {
            case "--path":
                if i + 1 < args.count { inputPath = args[i+1]; i += 2 } else { i += 1 }
            case "--output":
                if i + 1 < args.count { outputPath = args[i+1]; i += 2 } else { i += 1 }
            case "--cores":
                if i + 1 < args.count { cores = Int(args[i+1]) ?? 1; i += 2 } else { i += 1 }
            case "--help", "-h":
                print("Usage: metal-raytracer [--path <sphere_data_path>] [--output <output_ppm_path>] [--cores N]")
                return
            default:
                i += 1
            }
        }

        guard let device = MTLCreateSystemDefaultDevice() else {
            fputs("Error: No Metal device available. This app requires a Metal‑capable Mac.\n", stderr)
            exit(1)
        }
        guard let commandQueue = device.makeCommandQueue() else {
            fputs("Error: Failed to create Metal command queue.\n", stderr)
            exit(1)
        }
        let library: MTLLibrary
        if let defaultLib = try? device.makeDefaultLibrary(bundle: .main) {
            library = defaultLib
        } else {
            // Fallback to compiling the shader source embedded in bundle
            let shaderURL = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("raytracer.metal")
            let source = try String(contentsOf: shaderURL, encoding: .utf8)
            library = try device.makeLibrary(source: source, options: nil)
        }

        guard let kernel = library.makeFunction(name: "render_kernel") else {
            fatalError("Failed to load render_kernel")
        }
        let pipeline = try device.makeComputePipelineState(function: kernel)

        // Defaults to mirror python main
        var aspectRatio: Float = 16.0 / 9.0
        var imageWidth: Int = 800
        var vfov: Float = 20.0
        var samplesPerPixel: Int = 50
        var maxDepth: Int = 50
        var lookFrom = SIMD3<Float>(13.0, 2.0, 3.0)
        var lookAt = SIMD3<Float>(0.0, 0.0, 0.0)
        var vup = SIMD3<Float>(0.0, 1.0, 0.0)
        var defocusAngle: Float = 0.6
        var focusDist: Float = 10.0

        // Scene path
        let defaultSceneURL = URL(fileURLWithPath: "../sphere_data.txt")
        let sceneURL = URL(fileURLWithPath: inputPath ?? defaultSceneURL.path)
        let (spheres, materials) = try loadScene(from: sceneURL)

        // Apply camera overrides from file if present
        applyCameraOverrides(from: sceneURL, aspectRatio: &aspectRatio, imageWidth: &imageWidth, samplesPerPixel: &samplesPerPixel, maxDepth: &maxDepth, vfov: &vfov, lookFrom: &lookFrom, lookAt: &lookAt, vup: &vup, defocusAngle: &defocusAngle, focusDist: &focusDist)

        let imageHeight = max(1, Int(Float(imageWidth) / aspectRatio))
        let pixelCount = imageWidth * imageHeight

        // Build GPU buffers
        var camParams = CameraParams(
            aspectRatio: aspectRatio,
            imageWidth: UInt32(imageWidth),
            samplesPerPixel: UInt32(samplesPerPixel),
            maxDepth: UInt32(maxDepth),
            vfov: vfov,
            defocusAngle: defocusAngle,
            focusDist: focusDist,
            padding: 0,
            lookFrom: lookFrom,
            lookAt: lookAt,
            vup: vup
        )

        let camBuffer = device.makeBuffer(bytes: &camParams, length: MemoryLayout<CameraParams>.stride, options: .storageModeShared)!

        let sphereBuffer = device.makeBuffer(bytes: spheres, length: spheres.count * MemoryLayout<Sphere>.stride, options: .storageModeShared)!
        let materialBuffer = device.makeBuffer(bytes: materials, length: materials.count * MemoryLayout<MaterialGPU>.stride, options: .storageModeShared)!

        let outputBuffer = device.makeBuffer(length: pixelCount * MemoryLayout<SIMD3<Float>>.stride, options: .storageModeShared)!
        // Zero the accumulation buffer
        memset(outputBuffer.contents(), 0, pixelCount * MemoryLayout<SIMD3<Float>>.stride)

        // Threadgroup sizing
        let w = pipeline.threadExecutionWidth
        let h = max(1, pipeline.maxTotalThreadsPerThreadgroup / w)
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSize(width: imageWidth, height: imageHeight, depth: 1)

        // Dispatch in chunks (serialize with per-dispatch command buffer to avoid RMW hazards)
        let maxSamplesPerDispatch = 32
        var startSample: UInt32 = 0
        while startSample < UInt32(samplesPerPixel) {
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeComputeCommandEncoder()!
            encoder.setComputePipelineState(pipeline)
            encoder.setBuffer(camBuffer, offset: 0, index: 0)
            encoder.setBuffer(sphereBuffer, offset: 0, index: 1)
            encoder.setBuffer(materialBuffer, offset: 0, index: 2)
            var sphereCount = UInt32(spheres.count)
            encoder.setBytes(&sphereCount, length: MemoryLayout<UInt32>.stride, index: 3)
            encoder.setBuffer(outputBuffer, offset: 0, index: 4)
            var width = UInt32(imageWidth)
            var height = UInt32(imageHeight)
            encoder.setBytes(&width, length: MemoryLayout<UInt32>.stride, index: 5)
            encoder.setBytes(&height, length: MemoryLayout<UInt32>.stride, index: 6)

            let remaining = Int(UInt32(samplesPerPixel) - startSample)
            var samplesThisDispatch = UInt32(min(maxSamplesPerDispatch, remaining))
            encoder.setBytes(&startSample, length: MemoryLayout<UInt32>.stride, index: 7)
            encoder.setBytes(&samplesThisDispatch, length: MemoryLayout<UInt32>.stride, index: 8)

            encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            startSample += samplesThisDispatch
        }

        // Write PPM (stdout if no output path provided)
        if let outputPath = outputPath {
            let outputURL = URL(fileURLWithPath: outputPath)
            try writePPM(buffer: outputBuffer, width: imageWidth, height: imageHeight, url: outputURL, samples: samplesPerPixel)
            print("Wrote \(outputURL.path)")
        } else {
            // write to stdout
            let ptr = outputBuffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: pixelCount)
            var text = "P3\n\(imageWidth) \(imageHeight)\n255\n"
            for j in 0..<imageHeight {
                for i in 0..<imageWidth {
                    let c = ptr[j * imageWidth + i]
                    // normalize by samples and gamma-correct
                    let r = sqrt(max(0, min(0.999, Double(c.x) / Double(samplesPerPixel))))
                    let g = sqrt(max(0, min(0.999, Double(c.y) / Double(samplesPerPixel))))
                    let b = sqrt(max(0, min(0.999, Double(c.z) / Double(samplesPerPixel))))
                    let ir = Int(256 * r)
                    let ig = Int(256 * g)
                    let ib = Int(256 * b)
                    text += "\(ir) \(ig) \(ib)\n"
                }
            }
            FileHandle.standardOutput.write(text.data(using: .utf8)!)
        }
    }
}

// MARK: - Scene Types matching Metal structs

enum MaterialTypeGPU: UInt32 {
    case lambertian = 0
    case metal = 1
    case dielectric = 2
}

struct MaterialGPU {
    var type: UInt32
    var pad0: UInt32
    var pad1: UInt32
    var pad2: UInt32
    var albedo: SIMD3<Float>
    var fuzz: Float
    var ir: Float
    var pad3: Float
}

struct Sphere {
    var center: SIMD3<Float>
    var radius: Float
    var materialIndex: UInt32
    var pad: SIMD3<Float> = .zero
}

// MARK: - Loading scene from sphere_data.txt

func loadScene(from url: URL) throws -> ([Sphere], [MaterialGPU]) {
    let data = try String(contentsOf: url, encoding: .utf8)
    var spheres: [Sphere] = []
    var materials: [MaterialGPU] = []

    // Add ground sphere material first
    let groundMatIndex = UInt32(materials.count)
    materials.append(MaterialGPU(
        type: MaterialTypeGPU.lambertian.rawValue,
        pad0: 0, pad1: 0, pad2: 0,
        albedo: SIMD3<Float>(0.5, 0.5, 0.5),
        fuzz: 0, ir: 1.0, pad3: 0
    ))
    spheres.append(Sphere(center: SIMD3<Float>(0.0, -1000.0, 0.0), radius: 1000.0, materialIndex: groundMatIndex))

    func indexForMaterial(_ mat: MaterialGPU) -> UInt32 {
        materials.append(mat)
        return UInt32(materials.count - 1)
    }

    for line in data.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
        let parts = trimmed.split(separator: " ")
        if parts.first == "c" { continue }
        guard parts.count >= 5 else { continue }
        guard let x = Float(parts[0]), let y = Float(parts[1]), let z = Float(parts[2]), let radius = Float(parts[3]) else { continue }
        let type = parts[4]
        var material = MaterialGPU(type: 0, pad0: 0, pad1: 0, pad2: 0, albedo: SIMD3<Float>(0.5,0.5,0.5), fuzz: 0, ir: 1.0, pad3: 0)
        if type == "lambertian" {
            guard parts.count >= 8, let r = Float(parts[5]), let g = Float(parts[6]), let b = Float(parts[7]) else { continue }
            material.type = MaterialTypeGPU.lambertian.rawValue
            material.albedo = SIMD3<Float>(r, g, b)
        } else if type == "metal" {
            guard parts.count >= 9, let r = Float(parts[5]), let g = Float(parts[6]), let b = Float(parts[7]), let fuzz = Float(parts[8]) else { continue }
            material.type = MaterialTypeGPU.metal.rawValue
            material.albedo = SIMD3<Float>(r, g, b)
            material.fuzz = fuzz
        } else if type == "dielectric" {
            guard parts.count >= 6, let ir = Float(parts[5]) else { continue }
            material.type = MaterialTypeGPU.dielectric.rawValue
            material.ir = ir
        } else {
            continue
        }
        let matIndex = indexForMaterial(material)
        spheres.append(Sphere(center: SIMD3<Float>(x, y, z), radius: radius, materialIndex: matIndex))
    }

    return (spheres, materials)
}

// MARK: - Write PPM

func writePPM(buffer: MTLBuffer, width: Int, height: Int, url: URL, samples: Int) throws {
    let ptr = buffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: width * height)
    var text = "P3\n\(width) \(height)\n255\n"
    for j in 0..<height {
        for i in 0..<width {
            let c = ptr[j * width + i]
            // Normalize by samples and gamma-correct 2.0
            let r = sqrt(max(0, min(0.999, Double(c.x) / Double(samples))))
            let g = sqrt(max(0, min(0.999, Double(c.y) / Double(samples))))
            let b = sqrt(max(0, min(0.999, Double(c.z) / Double(samples))))
            let ir = Int(256 * r)
            let ig = Int(256 * g)
            let ib = Int(256 * b)
            text += "\(ir) \(ig) \(ib)\n"
        }
    }
    try text.write(to: url, atomically: true, encoding: .utf8)
}

// MARK: - Camera overrides parsing (like python create_world_from_file)

func applyCameraOverrides(from url: URL,
                          aspectRatio: inout Float,
                          imageWidth: inout Int,
                          samplesPerPixel: inout Int,
                          maxDepth: inout Int,
                          vfov: inout Float,
                          lookFrom: inout SIMD3<Float>,
                          lookAt: inout SIMD3<Float>,
                          vup: inout SIMD3<Float>,
                          defocusAngle: inout Float,
                          focusDist: inout Float) {
    guard let data = try? String(contentsOf: url, encoding: .utf8) else { return }
    for raw in data.split(separator: "\n") {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if line.isEmpty || !line.hasPrefix("c ") { continue }
        let parts = line.split(separator: " ")
        if parts.count < 3 { continue }
        let name = parts[1]
        switch name {
        case "ratio":
            if parts.count >= 4, let w = Float(parts[2]), let h = Float(parts[3]), h != 0 { aspectRatio = w / h }
        case "width":
            if parts.count >= 3, let w = Int(parts[2]) { imageWidth = w }
        case "samplesPerPixel":
            if parts.count >= 3, let s = Int(parts[2]) { samplesPerPixel = s }
        case "maxDepth", "maxDepths":
            if parts.count >= 3, let d = Int(parts[2]) { maxDepth = d }
        case "vfov":
            if parts.count >= 3, let v = Float(parts[2]) { vfov = v }
        case "lookFrom":
            if parts.count >= 5, let x = Float(parts[2]), let y = Float(parts[3]), let z = Float(parts[4]) { lookFrom = SIMD3<Float>(x,y,z) }
        case "lookAt":
            if parts.count >= 5, let x = Float(parts[2]), let y = Float(parts[3]), let z = Float(parts[4]) { lookAt = SIMD3<Float>(x,y,z) }
        case "vup":
            if parts.count >= 5, let x = Float(parts[2]), let y = Float(parts[3]), let z = Float(parts[4]) { vup = SIMD3<Float>(x,y,z) }
        case "defocusAngle":
            if parts.count >= 3, let a = Float(parts[2]) { defocusAngle = a }
        case "focusDist":
            if parts.count >= 3, let f = Float(parts[2]) { focusDist = f }
        default:
            continue
        }
    }
}


