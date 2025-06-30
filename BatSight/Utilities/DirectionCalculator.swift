//
//  DirectionCalculator.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import Vision
import CoreImage

// Computer vision utility that analyzes camera frames to determine object positions and filter objects by distance
class DirectionCalculator {
    
    // MARK: - Configuration
    
    // Configurable thresholds for distance filtering with different presets for various use cases
    struct DistanceConfig {
        /// Minimum object density (percentage of significant pixels) to consider object close enough
        let minObjectDensity: Double
        /// Minimum edge strength to consider object close enough
        let minEdgeStrength: Double
        /// Minimum object size (as percentage of frame) to consider object close enough
        let minObjectSize: Double
        /// Whether to use aggressive filtering (stricter thresholds)
        let aggressiveFiltering: Bool
        
        static let `default` = DistanceConfig(
            minObjectDensity: 0.03,      // 3% of pixels need to be significant
            minEdgeStrength: 60.0,       // Higher edge strength threshold
            minObjectSize: 0.05,         // Object should take up at least 5% of frame
            aggressiveFiltering: false
        )
        
        static let aggressive = DistanceConfig(
            minObjectDensity: 0.05,      // 5% of pixels need to be significant
            minEdgeStrength: 80.0,       // Higher edge strength threshold
            minObjectSize: 0.08,         // Object should take up at least 8% of frame
            aggressiveFiltering: true
        )
        
        static let lenient = DistanceConfig(
            minObjectDensity: 0.015,     // Only 1.5% of pixels need to be significant
            minEdgeStrength: 40.0,       // Lower edge strength threshold
            minObjectSize: 0.02,         // Object should take up at least 2% of frame
            aggressiveFiltering: false
        )
        
        /// Very strict filtering for objects within a few feet only
        static let veryClose = DistanceConfig(
            minObjectDensity: 0.08,      // 8% of pixels need to be significant (very close objects)
            minEdgeStrength: 100.0,      // Very high edge strength (sharp, close objects)
            minObjectSize: 0.15,         // Object should take up at least 15% of frame (very close)
            aggressiveFiltering: true    // All criteria must be met
        )
        
        /// Ultra strict filtering for objects within 1-2 feet
        static let ultraClose = DistanceConfig(
            minObjectDensity: 0.12,      // 12% of pixels need to be significant (extremely close)
            minEdgeStrength: 120.0,      // Very high edge strength
            minObjectSize: 0.25,         // Object should take up at least 25% of frame (very close)
            aggressiveFiltering: true    // All criteria must be met
        )
    }
    
    // MARK: - Position Detection
    
    // Analyzes camera frame pixel data to determine which region (left, center, right) has the most object activity
    static func determineObjectPosition(from pixelBuffer: CVPixelBuffer) -> String {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Lock the pixel buffer for reading
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return "Center"
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Analyze different regions of the image to detect objects
        let leftRegion = analyzeImageRegion(buffer: buffer, bytesPerRow: bytesPerRow, width: width, height: height, region: .left)
        let centerRegion = analyzeImageRegion(buffer: buffer, bytesPerRow: bytesPerRow, width: width, height: height, region: .center)
        let rightRegion = analyzeImageRegion(buffer: buffer, bytesPerRow: bytesPerRow, width: width, height: height, region: .right)
        
        // Print debug info
        print("Region analysis - Left: \(leftRegion), Center: \(centerRegion), Right: \(rightRegion)")
        
        // Find the region with the highest activity
        // Fix the region mapping based on user feedback
        let regions = [
            ("Center", leftRegion),   // Left region maps to Center position
            ("Left", centerRegion),   // Center region maps to Left position  
            ("Right", rightRegion)    // Right region maps to Right position
        ]
        
        // Use a threshold to avoid false positives
        let maxActivity = regions.map { $0.1 }.max() ?? 0
        let threshold = maxActivity * 0.8 // Only consider regions with 80% of max activity
        
        let activeRegions = regions.filter { $0.1 >= threshold }
        
        if activeRegions.isEmpty {
            return "Center"
        } else if activeRegions.count == 1 {
            return activeRegions[0].0
        } else {
            // If multiple regions are active, return the one with highest activity
            return activeRegions.max { $0.1 < $1.1 }?.0 ?? "Center"
        }
    }
    
    // Checks if detected objects are too far away by analyzing pixel density, edge strength, and object size in the specified region
    static func isObjectTooFarAway(pixelBuffer: CVPixelBuffer, position: String, config: DistanceConfig = .default) -> Bool {
        // Lock the pixel buffer for reading
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return true // Assume too far if we can't access the buffer
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Define the region to analyze based on position
        let regionWidth = width / 3
        let startX: Int
        let endX: Int
        
        switch position {
        case "Left":
            startX = 0
            endX = regionWidth
        case "Center":
            startX = regionWidth
            endX = regionWidth * 2
        case "Right":
            startX = regionWidth * 2
            endX = width
        default:
            return true
        }
        
        // Calculate object size by counting significant pixels in the region
        var significantPixels = 0
        var totalPixels = 0
        var maxEdgeStrength = 0.0
        var objectBounds = ObjectBounds()
        
        // Sample pixels in the region - use smaller step for more detailed analysis
        for y in stride(from: height / 4, to: height * 3 / 4, by: 4) {
            for x in stride(from: startX, to: endX, by: 4) {
                let pixelIndex = y * bytesPerRow + x * 4
                
                if pixelIndex + 2 < bytesPerRow * height {
                    let red = Double(buffer[pixelIndex + 2])
                    let green = Double(buffer[pixelIndex + 1])
                    let blue = Double(buffer[pixelIndex])
                    
                    // Calculate edge strength
                    let edgeStrength = abs(red - green) + abs(green - blue) + abs(blue - red)
                    maxEdgeStrength = max(maxEdgeStrength, edgeStrength)
                    
                    totalPixels += 1
                    if edgeStrength > 30 { // Lower threshold for significant edges
                        significantPixels += 1
                        objectBounds.updateBounds(x: x, y: y, width: width, height: height)
                    }
                }
            }
        }
        
        // Calculate the percentage of significant pixels (object density)
        let objectDensity = totalPixels > 0 ? Double(significantPixels) / Double(totalPixels) : 0.0
        
        // Calculate object size as percentage of frame
        let objectSizePercentage = objectBounds.getSizePercentage()
        
        print("Object analysis at \(position):")
        print("  - Density: \(String(format: "%.3f", objectDensity)) (threshold: \(config.minObjectDensity))")
        print("  - Edge strength: \(String(format: "%.1f", maxEdgeStrength)) (threshold: \(config.minEdgeStrength))")
        print("  - Size: \(String(format: "%.1f", objectSizePercentage * 100))% (threshold: \(config.minObjectSize * 100)%)")
        
        // Check all distance criteria
        let isTooFarByDensity = objectDensity < config.minObjectDensity
        let isTooFarByEdgeStrength = maxEdgeStrength < config.minEdgeStrength
        let isTooFarBySize = objectSizePercentage < config.minObjectSize
        
        // Use different logic based on filtering aggressiveness
        let isTooFar: Bool
        if config.aggressiveFiltering {
            // Aggressive: ALL criteria must be met (AND logic)
            isTooFar = isTooFarByDensity || isTooFarByEdgeStrength || isTooFarBySize
        } else {
            // Default: At least 2 out of 3 criteria must be met
            let failedCriteria = [isTooFarByDensity, isTooFarByEdgeStrength, isTooFarBySize].filter { $0 }.count
            isTooFar = failedCriteria >= 2
        }
        
        if isTooFar {
            print("  - RESULT: Object filtered out (too far away)")
        } else {
            print("  - RESULT: Object detected (close enough)")
        }
        
        return isTooFar
    }
    
    // Performs a quick scan of the entire frame to determine if any significant objects are present before expensive Core ML processing
    static func hasSignificantObjects(pixelBuffer: CVPixelBuffer) -> Bool {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return false
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        var significantPixels = 0
        var totalPixels = 0
        var maxEdgeStrength = 0.0
        
        // Quick scan of the entire frame - more thorough for close object detection
        for y in stride(from: 0, to: height, by: 8) {
            for x in stride(from: 0, to: width, by: 8) {
                let pixelIndex = y * bytesPerRow + x * 4
                
                if pixelIndex + 2 < bytesPerRow * height {
                    let red = Double(buffer[pixelIndex + 2])
                    let green = Double(buffer[pixelIndex + 1])
                    let blue = Double(buffer[pixelIndex])
                    
                    let edgeStrength = abs(red - green) + abs(green - blue) + abs(blue - red)
                    maxEdgeStrength = max(maxEdgeStrength, edgeStrength)
                    
                    totalPixels += 1
                    if edgeStrength > 60 { // Higher threshold for significant edges
                        significantPixels += 1
                    }
                }
            }
        }
        
        let density = totalPixels > 0 ? Double(significantPixels) / Double(totalPixels) : 0.0
        
        // Much stricter criteria for detecting significant objects
        let hasHighDensity = density > 0.03 // At least 3% of frame has significant activity
        let hasHighEdgeStrength = maxEdgeStrength > 80 // High edge strength indicates close objects
        
        print("Quick object check - Density: \(String(format: "%.3f", density)), Max Edge: \(String(format: "%.1f", maxEdgeStrength))")
        
        return hasHighDensity && hasHighEdgeStrength // Both criteria must be met
    }
    
    // MARK: - Private Helper Methods
    
    private enum ImageRegion {
        case left, center, right
    }
    
    // Analyzes a specific region of the image to calculate the average activity level based on edge detection
    private static func analyzeImageRegion(buffer: UnsafePointer<UInt8>, bytesPerRow: Int, width: Int, height: Int, region: ImageRegion) -> Double {
        // Calculate region boundaries - ensure proper mapping
        let regionWidth = width / 3
        let startX: Int
        let endX: Int
        
        switch region {
        case .left:
            startX = 0
            endX = regionWidth
        case .center:
            startX = regionWidth
            endX = regionWidth * 2
        case .right:
            startX = regionWidth * 2
            endX = width
        }
        
        // Debug: print region boundaries
        print("\(region) region: x=\(startX) to x=\(endX) (width=\(width))")
        
        var totalActivity = 0.0
        var pixelCount = 0
        
        // Sample pixels in the region to detect activity
        for y in stride(from: height / 4, to: height * 3 / 4, by: 8) { // Focus on center area, sample every 8th pixel
            for x in stride(from: startX, to: endX, by: 8) {
                let pixelIndex = y * bytesPerRow + x * 4 // BGRA format
                
                if pixelIndex + 2 < bytesPerRow * height {
                    let red = Double(buffer[pixelIndex + 2])
                    let green = Double(buffer[pixelIndex + 1])
                    let blue = Double(buffer[pixelIndex])
                    
                    // Calculate edge detection (more sensitive to object boundaries)
                    let edgeStrength = abs(red - green) + abs(green - blue) + abs(blue - red)
                    
                    // Only count pixels with significant edge strength
                    if edgeStrength > 30 {
                        totalActivity += edgeStrength
                        pixelCount += 1
                    }
                }
            }
        }
        
        return pixelCount > 0 ? totalActivity / Double(pixelCount) : 0.0
    }
}

// MARK: - Helper Structs

// Tracks the bounding box coordinates of detected objects to calculate their size as a percentage of the frame
private struct ObjectBounds {
    private var minX: Int = Int.max
    private var maxX: Int = Int.min
    private var minY: Int = Int.max
    private var maxY: Int = Int.min
    private var hasBounds = false
    
    mutating func updateBounds(x: Int, y: Int, width: Int, height: Int) {
        minX = min(minX, x)
        maxX = max(maxX, x)
        minY = min(minY, y)
        maxY = max(maxY, y)
        hasBounds = true
    }
    
    func getSizePercentage() -> Double {
        guard hasBounds else { return 0.0 }
        
        let objectWidth = maxX - minX
        let objectHeight = maxY - minY
        let objectArea = Double(objectWidth * objectHeight)
        let frameArea = Double((maxX - minX + 1) * (maxY - minY + 1))
        
        return objectArea / frameArea
    }
}
