//
//  ImageFilter.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - ImageFilter Protocol

/// Protocol for all image filters. Each filter takes a CIImage and returns a modified CIImage.
/// The output is a lazy CIImage graph — no actual rendering happens until drawn.
protocol ImageFilter: Sendable {
    var id: String { get }
    var displayName: String { get }
    func apply(to image: CIImage) -> CIImage
}

// MARK: - FilterCategory

enum FilterCategory: String, CaseIterable, Sendable {
    case none = "None"
    case warm = "Warm"
    case cool = "Cool"
    case vintage = "Vintage"
    case dramatic = "Dramatic"
    case blackAndWhite = "B&W"
}

// MARK: - Built-in Filters

/// No filter — returns original image.
struct OriginalFilter: ImageFilter {
    let id = "original"
    let displayName = "Original"

    func apply(to image: CIImage) -> CIImage {
        image
    }
}

/// Clarendon: Boosts contrast, saturation, and adds cool shadows.
struct ClarendonFilter: ImageFilter {
    let id = "clarendon"
    let displayName = "Clarendon"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        // Boost contrast
        let contrast = CIFilter.colorControls()
        contrast.inputImage = output
        contrast.contrast = 1.2
        contrast.saturation = 1.3
        contrast.brightness = 0.02
        output = contrast.outputImage ?? output

        // Cool tone in shadows
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = output
        colorMatrix.biasVector = CIVector(x: 0, y: 0, z: 0.05, w: 0)
        output = colorMatrix.outputImage ?? output

        return output
    }
}

/// Gingham: Soft, faded vintage look with slightly warm tones.
struct GinghamFilter: ImageFilter {
    let id = "gingham"
    let displayName = "Gingham"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        // Reduce contrast + saturation for faded look
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.contrast = 0.9
        controls.saturation = 0.85
        controls.brightness = 0.05
        output = controls.outputImage ?? output

        // Warm tone
        let temperature = CIFilter.temperatureAndTint()
        temperature.inputImage = output
        temperature.neutral = CIVector(x: 6800, y: 0)
        output = temperature.outputImage ?? output

        // Fade blacks (lift shadows)
        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = output
        toneCurve.point0 = CIVector(x: 0, y: 0.08)
        toneCurve.point1 = CIVector(x: 0.25, y: 0.25)
        toneCurve.point2 = CIVector(x: 0.5, y: 0.5)
        toneCurve.point3 = CIVector(x: 0.75, y: 0.75)
        toneCurve.point4 = CIVector(x: 1, y: 0.95)
        output = toneCurve.outputImage ?? output

        return output
    }
}

/// Moon: High-contrast black & white with cool tones.
struct MoonFilter: ImageFilter {
    let id = "moon"
    let displayName = "Moon"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        // Desaturate
        let bw = CIFilter.colorControls()
        bw.inputImage = output
        bw.saturation = 0
        bw.contrast = 1.3
        bw.brightness = 0.02
        output = bw.outputImage ?? output

        // Cool tone overlay
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = output
        colorMatrix.biasVector = CIVector(x: -0.02, y: 0, z: 0.05, w: 0)
        output = colorMatrix.outputImage ?? output

        return output
    }
}

/// Lark: Bright, desaturated greens and boosted blues.
struct LarkFilter: ImageFilter {
    let id = "lark"
    let displayName = "Lark"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        // Bright + slightly desaturated
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.brightness = 0.06
        controls.contrast = 1.05
        controls.saturation = 0.9
        output = controls.outputImage ?? output

        // Desaturate greens, boost blues
        let hueAdjust = CIFilter.hueAdjust()
        hueAdjust.inputImage = output
        hueAdjust.angle = -0.1
        output = hueAdjust.outputImage ?? output

        // Lift shadows
        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = output
        toneCurve.point0 = CIVector(x: 0, y: 0.05)
        toneCurve.point1 = CIVector(x: 0.25, y: 0.28)
        toneCurve.point2 = CIVector(x: 0.5, y: 0.52)
        toneCurve.point3 = CIVector(x: 0.75, y: 0.76)
        toneCurve.point4 = CIVector(x: 1, y: 1)
        output = toneCurve.outputImage ?? output

        return output
    }
}

/// Juno: Warmer tones, boosted saturation, slight vignette.
struct JunoFilter: ImageFilter {
    let id = "juno"
    let displayName = "Juno"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        // Warm + saturated
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.saturation = 1.4
        controls.contrast = 1.1
        controls.brightness = 0.0
        output = controls.outputImage ?? output

        // Warm temperature
        let temperature = CIFilter.temperatureAndTint()
        temperature.inputImage = output
        temperature.neutral = CIVector(x: 7200, y: 0)
        output = temperature.outputImage ?? output

        // Subtle vignette
        output = applyVignette(to: output, intensity: 0.4)

        return output
    }
}

/// Valencia: Warm vintage with a slight fade.
struct ValenciaFilter: ImageFilter {
    let id = "valencia"
    let displayName = "Valencia"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        // Warm tone shift
        let temperature = CIFilter.temperatureAndTint()
        temperature.inputImage = output
        temperature.neutral = CIVector(x: 7500, y: 0)
        output = temperature.outputImage ?? output

        // Slight fade
        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = output
        toneCurve.point0 = CIVector(x: 0, y: 0.06)
        toneCurve.point1 = CIVector(x: 0.25, y: 0.26)
        toneCurve.point2 = CIVector(x: 0.5, y: 0.52)
        toneCurve.point3 = CIVector(x: 0.75, y: 0.74)
        toneCurve.point4 = CIVector(x: 1, y: 0.94)
        output = toneCurve.outputImage ?? output

        // Reduce saturation slightly
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.saturation = 0.9
        controls.contrast = 1.05
        output = controls.outputImage ?? output

        return output
    }
}

/// Aden: Soft, pastel with desaturation and light haze.
struct AdenFilter: ImageFilter {
    let id = "aden"
    let displayName = "Aden"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        // Desaturate + soft
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.saturation = 0.75
        controls.contrast = 0.9
        controls.brightness = 0.05
        output = controls.outputImage ?? output

        // Warm shift
        let temperature = CIFilter.temperatureAndTint()
        temperature.inputImage = output
        temperature.neutral = CIVector(x: 6900, y: 0)
        output = temperature.outputImage ?? output

        // Lift shadows heavily
        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = output
        toneCurve.point0 = CIVector(x: 0, y: 0.1)
        toneCurve.point1 = CIVector(x: 0.25, y: 0.3)
        toneCurve.point2 = CIVector(x: 0.5, y: 0.53)
        toneCurve.point3 = CIVector(x: 0.75, y: 0.75)
        toneCurve.point4 = CIVector(x: 1, y: 0.93)
        output = toneCurve.outputImage ?? output

        return output
    }
}

/// Nashville: Warm highlights, cool purple-ish shadows, high contrast.
struct NashvilleFilter: ImageFilter {
    let id = "nashville"
    let displayName = "Nashville"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        // Contrast boost
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.contrast = 1.25
        controls.saturation = 1.15
        controls.brightness = 0.03
        output = controls.outputImage ?? output

        // Warm highlights + purple shadows via color matrix
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = output
        colorMatrix.rVector = CIVector(x: 1.05, y: 0, z: 0, w: 0)
        colorMatrix.gVector = CIVector(x: 0, y: 0.95, z: 0, w: 0)
        colorMatrix.bVector = CIVector(x: 0, y: 0, z: 1.1, w: 0)
        colorMatrix.biasVector = CIVector(x: 0.04, y: -0.01, z: 0.06, w: 0)
        output = colorMatrix.outputImage ?? output

        // Vignette
        output = applyVignette(to: output, intensity: 0.6)

        return output
    }
}

/// Inkwell: Classic black & white with strong contrast.
struct InkwellFilter: ImageFilter {
    let id = "inkwell"
    let displayName = "Inkwell"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        let mono = CIFilter.photoEffectMono()
        mono.inputImage = output
        output = mono.outputImage ?? output

        // Boost contrast
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.contrast = 1.2
        output = controls.outputImage ?? output

        return output
    }
}

/// Lo-Fi: High saturation, high contrast, strong vignette.
struct LoFiFilter: ImageFilter {
    let id = "lofi"
    let displayName = "Lo-Fi"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.saturation = 1.5
        controls.contrast = 1.4
        controls.brightness = -0.02
        output = controls.outputImage ?? output

        // Sharpen
        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = output
        sharpen.sharpness = 0.5
        output = sharpen.outputImage ?? output

        // Strong vignette
        output = applyVignette(to: output, intensity: 0.9)

        return output
    }
}

/// Sierra: Soft, slightly desaturated, lifted shadows.
struct SierraFilter: ImageFilter {
    let id = "sierra"
    let displayName = "Sierra"

    func apply(to image: CIImage) -> CIImage {
        var output = image

        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.saturation = 0.85
        controls.contrast = 0.95
        controls.brightness = 0.04
        output = controls.outputImage ?? output

        // Slight warm
        let temperature = CIFilter.temperatureAndTint()
        temperature.inputImage = output
        temperature.neutral = CIVector(x: 6600, y: 0)
        output = temperature.outputImage ?? output

        // Soft vignette
        output = applyVignette(to: output, intensity: 0.3)

        return output
    }
}

// MARK: - Helper: Vignette

private func applyVignette(to image: CIImage, intensity: Float) -> CIImage {
    let vignette = CIFilter.vignette()
    vignette.inputImage = image
    vignette.intensity = intensity
    vignette.radius = 2.0
    return vignette.outputImage ?? image
}

// MARK: - FilterRegistry

/// Central registry of all available filters.
enum FilterRegistry {

    static let allFilters: [ImageFilter] = [
        OriginalFilter(),
        ClarendonFilter(),
        GinghamFilter(),
        JunoFilter(),
        LarkFilter(),
        ValenciaFilter(),
        AdenFilter(),
        NashvilleFilter(),
        MoonFilter(),
        InkwellFilter(),
        LoFiFilter(),
        SierraFilter()
    ]

    static func filter(byId id: String) -> ImageFilter? {
        allFilters.first { $0.id == id }
    }
}
