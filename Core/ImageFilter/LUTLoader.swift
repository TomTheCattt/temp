//
//  LUTLoader.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import CoreImage
import UIKit

// MARK: - LUTLoader

/// Loads 3D LUT (Look-Up Table) files and creates CIColorCube filter data.
/// Supports:
/// - .png LUT images (64x64 grid = 512x512 image for 64-size cube)
/// - .cube files (industry standard text format)
///
/// Usage:
/// ```swift
/// let lutData = try LUTLoader.loadLUT(named: "warm_vintage", dimension: 64)
/// let filter = LUTFilter(id: "warm_vintage", displayName: "Warm Vintage", lutData: lutData, dimension: 64)
/// ```
enum LUTLoader {

    // MARK: - Cache

    /// Cache parsed LUT data to avoid reloading from disk.
    private static let cache = NSCache<NSString, NSData>()

    // MARK: - Load from PNG Image

    /// Load a LUT from a PNG image in the app bundle.
    /// The image should be a square grid (e.g., 512x512 for a 64-size cube).
    /// Grid layout: 8x8 tiles, each tile is 64x64 pixels.
    static func loadFromPNG(named name: String, dimension: Int = 64) throws -> Data {
        let cacheKey = NSString(string: "lut_png_\(name)_\(dimension)")
        if let cached = cache.object(forKey: cacheKey) {
            return cached as Data
        }

        guard let image = UIImage(named: name),
              let cgImage = image.cgImage else {
            throw LUTError.fileNotFound(name)
        }

        let data = try extractLUTData(from: cgImage, dimension: dimension)

        cache.setObject(data as NSData, forKey: cacheKey)
        return data
    }

    /// Load a LUT from a PNG image at a file URL.
    static func loadFromPNG(url: URL, dimension: Int = 64) throws -> Data {
        let cacheKey = NSString(string: "lut_png_\(url.lastPathComponent)_\(dimension)")
        if let cached = cache.object(forKey: cacheKey) {
            return cached as Data
        }

        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            throw LUTError.fileNotFound(url.lastPathComponent)
        }

        let lutData = try extractLUTData(from: cgImage, dimension: dimension)
        cache.setObject(lutData as NSData, forKey: cacheKey)
        return lutData
    }

    // MARK: - Load from .cube File

    /// Load a LUT from a .cube file in the app bundle.
    static func loadFromCubeFile(named name: String) throws -> (data: Data, dimension: Int) {
        let cacheKey = NSString(string: "lut_cube_\(name)")
        if let cached = cache.object(forKey: cacheKey) {
            // Dimension encoded in first 4 bytes
            let dimBytes = cached.subdata(with: NSRange(location: 0, length: 4))
            let dimension = dimBytes.withUnsafeBytes { $0.load(as: Int32.self) }
            let lutData = cached.subdata(with: NSRange(location: 4, length: cached.length - 4))
            return (lutData as Data, Int(dimension))
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: "cube") else {
            throw LUTError.fileNotFound("\(name).cube")
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        let result = try parseCubeFile(content)

        // Cache with dimension prefix
        var cacheData = Data()
        var dim = Int32(result.dimension)
        cacheData.append(Data(bytes: &dim, count: 4))
        cacheData.append(result.data)
        cache.setObject(cacheData as NSData, forKey: cacheKey)

        return result
    }

    // MARK: - Clear Cache

    static func clearCache() {
        cache.removeAllObjects()
    }

    // MARK: - Private: Extract from PNG

    private static func extractLUTData(from cgImage: CGImage, dimension: Int) throws -> Data {
        let width = cgImage.width
        let height = cgImage.height

        // Determine grid layout
        let tilesPerRow = width / dimension
        let tilesPerCol = height / dimension

        guard tilesPerRow * tilesPerCol >= dimension else {
            throw LUTError.invalidDimension(expected: dimension, imageSize: CGSize(width: width, height: height))
        }

        // Get pixel data
        guard let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else {
            throw LUTError.invalidImageData
        }

        let data = pixelData as Data
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        // Build color cube data (RGBA float array)
        let cubeSize = dimension * dimension * dimension * 4
        var cubeData = [Float](repeating: 0, count: cubeSize)

        for z in 0..<dimension {
            let tileRow = z / tilesPerRow
            let tileCol = z % tilesPerRow

            for y in 0..<dimension {
                for x in 0..<dimension {
                    let pixelX = tileCol * dimension + x
                    let pixelY = tileRow * dimension + y

                    let offset = pixelY * bytesPerRow + pixelX * bytesPerPixel
                    guard offset + 2 < data.count else { continue }

                    let r = Float(data[offset]) / 255.0
                    let g = Float(data[offset + 1]) / 255.0
                    let b = Float(data[offset + 2]) / 255.0
                    let a: Float = bytesPerPixel >= 4 ? Float(data[offset + 3]) / 255.0 : 1.0

                    let index = (z * dimension * dimension + y * dimension + x) * 4
                    cubeData[index] = r
                    cubeData[index + 1] = g
                    cubeData[index + 2] = b
                    cubeData[index + 3] = a
                }
            }
        }

        return Data(bytes: cubeData, count: cubeSize * MemoryLayout<Float>.size)
    }

    // MARK: - Private: Parse .cube File

    private static func parseCubeFile(_ content: String) throws -> (data: Data, dimension: Int) {
        let lines = content.components(separatedBy: .newlines)
        var dimension = 0
        var colors: [(Float, Float, Float)] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            // Parse LUT_3D_SIZE
            if trimmed.hasPrefix("LUT_3D_SIZE") {
                let parts = trimmed.components(separatedBy: .whitespaces)
                if let last = parts.last, let size = Int(last) {
                    dimension = size
                }
                continue
            }

            // Skip other metadata lines
            if trimmed.hasPrefix("TITLE") || trimmed.hasPrefix("DOMAIN_") { continue }

            // Parse color values (R G B)
            let components = trimmed.components(separatedBy: .whitespaces)
                .compactMap { Float($0) }

            if components.count >= 3 {
                colors.append((components[0], components[1], components[2]))
            }
        }

        guard dimension > 0 else {
            throw LUTError.invalidCubeFile("Missing LUT_3D_SIZE")
        }

        let expectedCount = dimension * dimension * dimension
        guard colors.count >= expectedCount else {
            throw LUTError.invalidCubeFile("Expected \(expectedCount) colors, got \(colors.count)")
        }

        // Build float RGBA array
        var cubeData = [Float]()
        cubeData.reserveCapacity(expectedCount * 4)

        for i in 0..<expectedCount {
            let (r, g, b) = colors[i]
            cubeData.append(r)
            cubeData.append(g)
            cubeData.append(b)
            cubeData.append(1.0)
        }

        let data = Data(bytes: cubeData, count: cubeData.count * MemoryLayout<Float>.size)
        return (data, dimension)
    }
}

// MARK: - LUTFilter

/// A filter backed by a 3D LUT (color cube).
/// This is the most performant approach for Instagram-style color grading.
struct LUTFilter: ImageFilter {
    let id: String
    let displayName: String
    let lutData: Data
    let dimension: Int

    func apply(to image: CIImage) -> CIImage {
        let filter = CIFilter.colorCubeWithColorSpace()
        filter.inputImage = image
        filter.cubeDimension = Float(dimension)
        filter.cubeData = lutData
        filter.colorSpace = CGColorSpaceCreateDeviceRGB()
        return filter.outputImage ?? image
    }
}

// MARK: - LUTError

enum LUTError: LocalizedError {
    case fileNotFound(String)
    case invalidDimension(expected: Int, imageSize: CGSize)
    case invalidImageData
    case invalidCubeFile(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "LUT file not found: \(name)"
        case .invalidDimension(let expected, let size):
            return "Invalid LUT dimensions. Expected \(expected)³ from image \(Int(size.width))x\(Int(size.height))"
        case .invalidImageData:
            return "Failed to read pixel data from LUT image."
        case .invalidCubeFile(let reason):
            return "Invalid .cube file: \(reason)"
        }
    }
}
