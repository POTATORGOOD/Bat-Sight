//
//  CameraView.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Vision
import CoreML

struct CameraView: View {
    @StateObject private var cameraManager: CameraManager
    @ObservedObject var detectionState: DetectionState
    
    init(detectionState: DetectionState) {
        self.detectionState = detectionState
        self._cameraManager = StateObject(wrappedValue: CameraManager(detectionState: detectionState))
    }
    
    var body: some View {
        ZStack {
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            // Overlay for detected objects
            VStack {
                Spacer()
                
                if !detectionState.detectedObjects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected Objects:")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(detectionState.detectedObjects.enumerated()), id: \.offset) { index, detection in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text("• \(detection.identifier)")
                                                .font(.body)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Text("\(Int(detection.confidence * 100))%")
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                        }
                                        
                                        HStack {
                                            Text("Position: \(detection.position)")
                                                .font(.caption)
                                                .foregroundColor(.cyan)
                                            
                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.7))
                            .shadow(radius: 10)
                    )
                    .padding()
                }
            }
        }
        .onAppear {
            cameraManager.requestCameraPermission()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var detectionState: DetectionState
    
    private var captureSession: AVCaptureSession
    private var videoOutput: AVCaptureVideoDataOutput
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let visionQueue = DispatchQueue(label: "vision.queue")
    
    // Position detection state
    private var lastDetectionTime: Date = Date()
    private var positionCounter: Int = 0
    
    // Generic labels to filter out (prefer more specific ones)
    private let genericLabels = Set([
        "structure", "material", "object", "thing", "item", "surface", "texture",
        "pattern", "design", "background", "foreground", "scene", "image", "photo",
        "picture", "view", "area", "space", "place", "location", "setting",
        "environment", "atmosphere", "lighting", "shadow", "reflection", "color",
        "shape", "form", "line", "edge", "corner", "side", "part", "piece",
        "section", "element", "component", "feature", "detail", "aspect", "machine", "appliance", "textile", "rectangle", "consumer_electronics", "music", "musical_instrument", "furniture", "wood_processed", "interior_room", "structure", "material", "conveyence", "conveyance", "vehicle", "transport", "portal"
    ])
    
    init(detectionState: DetectionState) {
        self.detectionState = detectionState
        self.captureSession = AVCaptureSession()
        self.videoOutput = AVCaptureVideoDataOutput()
        super.init()
        setupCamera()
    }
    
    private func setupCoreMLModel() {
        // Try to load a built-in object detection model
        // For now, we'll use a simple approach that works with the Vision framework
        // In a real app, you would bundle a Core ML model file (.mlmodel)
        print("Core ML model setup - using Vision framework fallback")
    }
    
    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.startSession()
                    }
                }
            }
        default:
            break
        }
    }
    
    private func setupCamera() {
        print("Setting up camera...")
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium
        
        // Add camera input
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to access back camera")
            captureSession.commitConfiguration()
            return
        }
        print("Back camera found")
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("Camera input added")
            }
        } catch {
            print("Error setting up camera input: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        // Add video output
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            print("Video output added")
        }
        
        captureSession.commitConfiguration()
        print("Camera setup completed")
    }
    
    func startSession() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                print("Starting camera session...")
                self.captureSession.startRunning()
                print("Camera session started: \(self.captureSession.isRunning)")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
    
    // Helper function to check if a label is too generic
    private func isGenericLabel(_ label: String) -> Bool {
        let lowercaseLabel = label.lowercased()
        return genericLabels.contains(lowercaseLabel) ||
               lowercaseLabel.contains("unknown") ||
               lowercaseLabel.contains("unidentified")
    }
    
    // Helper function to clean up and improve label readability
    private func cleanupLabel(_ label: String) -> String {
        // Remove common prefixes/suffixes that make labels verbose
        var cleaned = label
        
        // Remove technical prefixes
        if cleaned.hasPrefix("n") && cleaned.count > 10 {
            cleaned = String(cleaned.dropFirst(10)) // Remove common ImageNet prefixes
        }
        
        // Capitalize first letter and make more readable
        cleaned = cleaned.prefix(1).uppercased() + cleaned.dropFirst()
        
        // Replace underscores with spaces
        cleaned = cleaned.replacingOccurrences(of: "_", with: " ")
        
        return cleaned
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Use Core ML object detection for position data
        performCoreMLObjectDetection(pixelBuffer: pixelBuffer)
    }
    
    private func performCoreMLObjectDetection(pixelBuffer: CVPixelBuffer) {
        // Use classification with custom position detection
        let classificationRequest = VNClassifyImageRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Core ML detection error: \(error)")
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            // Debug: print all detected objects before filtering
            print("All detected objects:")
            for result in results.prefix(10) {
                print("- \(result.identifier) (\(Int(result.confidence * 100))%)")
            }
            
            // Filter out generic labels and low confidence results
            let filteredResults = results
                .filter { $0.confidence > 0.3 }
                .filter { !self.isGenericLabel($0.identifier) }
            
            // Debug: print filtered objects
            print("Filtered objects:")
            for result in filteredResults.prefix(5) {
                print("- \(result.identifier) (\(Int(result.confidence * 100))%)")
            }
            
            // Get the most confident detection
            let finalResults: [VNClassificationObservation]
            if let bestSpecific = filteredResults.first {
                finalResults = [bestSpecific]
            } else if let bestGeneric = results.filter({ $0.confidence > 0.5 }).first {
                finalResults = [bestGeneric]
            } else {
                finalResults = []
            }
            
            // Create detected objects with position based on image analysis
            let detectedObjects: [DetectedObject] = finalResults.compactMap { classification in
                // Get custom position from our detection method
                let customPosition = self.determineObjectPosition(from: pixelBuffer)
                
                // Check if object is too far away (too small in frame)
                if self.isObjectTooFarAway(pixelBuffer: pixelBuffer, position: customPosition) {
                    print("Object filtered out - too far away")
                    return nil
                }
                
                // Create bounding box based on the custom position
                let boundingBox: CGRect
                switch customPosition {
                case "Left":
                    boundingBox = CGRect(x: 0.2, y: 0.5, width: 0.2, height: 0.2)
                case "Right":
                    boundingBox = CGRect(x: 0.6, y: 0.5, width: 0.2, height: 0.2)
                default: // Center
                    boundingBox = CGRect(x: 0.4, y: 0.5, width: 0.2, height: 0.2)
                }
                
                return DetectedObject(
                    identifier: self.cleanupLabel(classification.identifier),
                    confidence: classification.confidence,
                    boundingBox: boundingBox
                )
            }
            
            DispatchQueue.main.async {
                self.detectionState.updateDetections(detectedObjects)
            }
        }
        
        visionQueue.async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([classificationRequest])
            } catch {
                print("Failed to perform Core ML request: \(error)")
            }
        }
    }
    
    private func determineObjectPosition(from pixelBuffer: CVPixelBuffer) -> String {
        // Real position detection based on image analysis
        // Analyze the image to determine where objects are actually located
        
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
    
    private enum ImageRegion {
        case left, center, right
    }
    
    private func analyzeImageRegion(buffer: UnsafePointer<UInt8>, bytesPerRow: Int, width: Int, height: Int, region: ImageRegion) -> Double {
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
    
    private func isObjectTooFarAway(pixelBuffer: CVPixelBuffer, position: String) -> Bool {
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
                    }
                }
            }
        }
        
        // Calculate the percentage of significant pixels (object density)
        let objectDensity = totalPixels > 0 ? Double(significantPixels) / Double(totalPixels) : 0.0
        
        print("Object density at \(position): \(objectDensity), max edge strength: \(maxEdgeStrength)")
        
        // Less aggressive distance filtering - only filter out very far objects
        let densityThreshold = 0.02 // Only 2% of pixels need to be significant
        let edgeStrengthThreshold = 50.0 // Lower edge strength threshold
        
        let isTooFarByDensity = objectDensity < densityThreshold
        let isTooFarByEdgeStrength = maxEdgeStrength < edgeStrengthThreshold
        
        let isTooFar = isTooFarByDensity && isTooFarByEdgeStrength // Use AND instead of OR
        
        if isTooFar {
            print("Object at \(position) filtered out - density: \(objectDensity) < \(densityThreshold) AND edge strength: \(maxEdgeStrength) < \(edgeStrengthThreshold)")
        }
        
        return isTooFar
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> PreviewView {
        let previewView = PreviewView()
        previewView.session = cameraManager.getCaptureSession()
        return previewView
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Updates handled automatically by PreviewView
    }
}

// Custom UIView subclass for camera preview
class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
            videoPreviewLayer.videoGravity = .resizeAspectFill
        }
    }
}

#Preview {
    CameraView(detectionState: DetectionState())
}
