//
//  YOLOv8Model.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import CoreML
import Vision
import UIKit

// YOLOv8 detection result with bounding box and confidence
struct YOLOv8Detection {
    let identifier: String
    let confidence: Float
    let boundingBox: CGRect
    let position: String
    
    init(identifier: String, confidence: Float, boundingBox: CGRect) {
        self.identifier = identifier
        self.confidence = confidence
        self.boundingBox = boundingBox
        
        // Calculate position based on bounding box center
        let centerX = boundingBox.midX
        
        if centerX < 0.33 {
            self.position = "Left"
        } else if centerX > 0.67 {
            self.position = "Right"
        } else {
            self.position = "Center"
        }
    }
}

// Manages YOLOv8 model for object detection
class YOLOv8ModelManager: ObservableObject {
    private var model: VNCoreMLModel?
    private let modelName = "yolov8n" // Using nano model for speed
    private let modelExtension = "mlpackage" // Using mlpackage format
    private let confidenceThreshold: Float = 0.3  // Back to original threshold
    private let nmsThreshold: Float = 0.5
    
    // Generic labels to filter out (same as your current implementation)
    private let genericLabels = Set([
        "structure", "material", "object", "thing", "item", "surface", "texture",
        "pattern", "design", "background", "foreground", "scene", "image", "photo",
        "picture", "view", "area", "space", "place", "location", "setting",
        "environment", "atmosphere", "lighting", "shadow", "reflection", "color",
        "shape", "form", "line", "edge", "corner", "side", "part", "piece",
        "section", "element", "component", "feature", "detail", "aspect", "machine", 
        "appliance", "textile", "rectangle", "consumer_electronics", "music", 
        "musical_instrument", "furniture", "wood_processed", "interior_room", 
        "structure", "material", "conveyence", "conveyance", "vehicle", "transport", "portal", "cabinet"
    ])
    
    init() {
        setupModel()
    }
    
    // Sets up the YOLOv8 model
    private func setupModel() {
        do {
            // Try to load the model from the app bundle
            print("Looking for model: \(modelName).\(modelExtension)")
            
            // First try to find the compiled model (.mlmodelc)
            if let compiledModelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
                print("Found compiled model at: \(compiledModelURL)")
                model = try VNCoreMLModel(for: MLModel(contentsOf: compiledModelURL))
                print("YOLOv8 model loaded successfully from compiled model")
            }
            // If not found, try to find the original .mlpackage and compile it
            else if let modelURL = Bundle.main.url(forResource: modelName, withExtension: modelExtension) {
                print("Found model at: \(modelURL)")
                let compiledModelURL = try MLModel.compileModel(at: modelURL)
                print("Compiled model at: \(compiledModelURL)")
                model = try VNCoreMLModel(for: MLModel(contentsOf: compiledModelURL))
                print("YOLOv8 model loaded successfully")
            } else {
                print("YOLOv8 model not found in bundle. Using Vision framework fallback.")
                print("Available resources in bundle:")
                if let resources = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) {
                    for resource in resources.prefix(10) {
                        print("  - \(resource.lastPathComponent)")
                    }
                }
                // Fallback to Vision framework for now
                setupVisionFallback()
            }
        } catch {
            print("Error loading YOLOv8 model: \(error). Using Vision framework fallback.")
            setupVisionFallback()
        }
    }
    
    // Fallback to Vision framework if YOLOv8 model is not available
    private func setupVisionFallback() {
        print("Using Vision framework fallback")
        // This will be handled in the detection method
    }
    
    // Performs object detection using YOLOv8
    func performDetection(on pixelBuffer: CVPixelBuffer, completion: @escaping ([YOLOv8Detection]) -> Void) {
        guard let model = model else {
            // Fallback to Vision framework
            performVisionFallback(on: pixelBuffer, completion: completion)
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("YOLOv8 detection error: \(error)")
                completion([])
                return
            }
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }
            
            let detections = self.processYOLOv8Results(results)
            completion(detections)
        }
        
        // Configure the request
        request.imageCropAndScaleOption = .scaleFill
        
        // Perform the request
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform YOLOv8 request: \(error)")
            completion([])
        }
    }
    
    // Extracts only bounding boxes from YOLO for distance estimation (no object classification)
    func extractBoundingBoxesForDistance(on pixelBuffer: CVPixelBuffer, completion: @escaping ([CGRect]) -> Void) {
        guard let model = model else {
            // If no YOLO model, return empty array
            completion([])
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("YOLO bounding box extraction error: \(error)")
                completion([])
                return
            }
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }
            
            // Extract only bounding boxes, no object classification
            let boundingBoxes = results
                .filter { $0.confidence >= self.confidenceThreshold }
                .map { $0.boundingBox }
            
            completion(boundingBoxes)
        }
        
        // Configure the request
        request.imageCropAndScaleOption = .scaleFill
        
        // Perform the request
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform YOLO bounding box extraction: \(error)")
            completion([])
        }
    }
    
    // Processes YOLOv8 detection results - returns only the most confident detection
    private func processYOLOv8Results(_ results: [VNRecognizedObjectObservation]) -> [YOLOv8Detection] {
        var detections: [YOLOv8Detection] = []
        
        for observation in results {
            // Filter by confidence
            guard observation.confidence >= confidenceThreshold else { continue }
            
            // Get the top label
            guard let topLabelObservation = observation.labels.first else { continue }
            
            let identifier = topLabelObservation.identifier
            let confidence = topLabelObservation.confidence
            
            // Filter out generic labels
            guard !isGenericLabel(identifier) else { continue }
            
            // Create detection with bounding box
            let boundingBox = observation.boundingBox
            let detection = YOLOv8Detection(
                identifier: cleanupLabel(identifier),
                confidence: confidence,
                boundingBox: boundingBox
            )
            
            detections.append(detection)
        }
        
        // Apply non-maximum suppression to remove overlapping detections
        let filteredDetections = applyNMS(detections)
        
        // Sort by confidence and return only the most confident detection
        let sortedDetections = filteredDetections.sorted { $0.confidence > $1.confidence }
        
        // Return only the top detection (most confident)
        return sortedDetections.prefix(1).map { $0 }
    }
    
    // Applies non-maximum suppression to remove overlapping detections
    private func applyNMS(_ detections: [YOLOv8Detection]) -> [YOLOv8Detection] {
        var filteredDetections: [YOLOv8Detection] = []
        var used = Set<Int>()
        
        for i in 0..<detections.count {
            if used.contains(i) { continue }
            
            filteredDetections.append(detections[i])
            used.insert(i)
            
            for j in (i+1)..<detections.count {
                if used.contains(j) { continue }
                
                let iou = calculateIoU(detections[i].boundingBox, detections[j].boundingBox)
                if iou > nmsThreshold {
                    used.insert(j)
                }
            }
        }
        
        return filteredDetections
    }
    
    // Calculates Intersection over Union (IoU) between two bounding boxes
    private func calculateIoU(_ box1: CGRect, _ box2: CGRect) -> Float {
        let intersection = box1.intersection(box2)
        let union = box1.union(box2)
        
        if union.width * union.height == 0 {
            return 0
        }
        
        return Float((intersection.width * intersection.height) / (union.width * union.height))
    }
    
    // Fallback to Vision framework classification
    private func performVisionFallback(on pixelBuffer: CVPixelBuffer, completion: @escaping ([YOLOv8Detection]) -> Void) {
        let classificationRequest = VNClassifyImageRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Vision fallback error: \(error)")
                completion([])
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else {
                completion([])
                return
            }
            
            // Filter and process results similar to your current implementation
            let filteredResults = results
                .filter { $0.confidence > 0.3 }
                .filter { !self.isGenericLabel($0.identifier) }
            
            // Get only the most confident detection
            let detections = filteredResults.prefix(1).compactMap { classification in
                // Use DirectionCalculator for position as fallback
                let position = DirectionCalculator.determineObjectPosition(from: pixelBuffer)
                
                // Create bounding box based on position
                let boundingBox: CGRect
                switch position {
                case "Left":
                    boundingBox = CGRect(x: 0.1, y: 0.4, width: 0.2, height: 0.2)
                case "Right":
                    boundingBox = CGRect(x: 0.7, y: 0.4, width: 0.2, height: 0.2)
                default: // Center
                    boundingBox = CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)
                }
                
                return YOLOv8Detection(
                    identifier: self.cleanupLabel(classification.identifier),
                    confidence: classification.confidence,
                    boundingBox: boundingBox
                )
            }
            
            completion(Array(detections))
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([classificationRequest])
        } catch {
            print("Failed to perform Vision fallback: \(error)")
            completion([])
        }
    }
    
    // Checks if a detected label is too generic
    private func isGenericLabel(_ label: String) -> Bool {
        let lowercaseLabel = label.lowercased()
        return genericLabels.contains(lowercaseLabel) ||
               lowercaseLabel.contains("unknown") ||
               lowercaseLabel.contains("unidentified")
    }
    
    // Cleans up object labels
    private func cleanupLabel(_ label: String) -> String {
        var cleaned = label
        
        // Remove technical prefixes
        if cleaned.hasPrefix("n") && cleaned.count > 10 {
            cleaned = String(cleaned.dropFirst(10))
        }
        
        // Capitalize first letter
        cleaned = cleaned.prefix(1).uppercased() + cleaned.dropFirst()
        
        // Replace underscores with spaces
        cleaned = cleaned.replacingOccurrences(of: "_", with: " ")
        
        return cleaned
    }
} 
