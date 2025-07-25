//
//  VisionModelManager.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import Vision
import UIKit

// Vision framework detection result
struct VisionDetection {
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

    // Manages Vision framework for object detection as primary method
    class VisionModelManager: ObservableObject {
        private let objectConfidenceThreshold: Float = 0.4  // Higher threshold for object recognition
        private let classificationConfidenceThreshold: Float = 0.3  // Lower threshold for classification
        private let faceConfidenceThreshold: Float = 0.5  // Threshold for face detection
    
    
    // Generic labels to filter out
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
        print("Vision Model Manager initialized")
    }
    
    // Performs object detection using Vision framework only
    func performDetection(on pixelBuffer: CVPixelBuffer, returnAllDetections: Bool = false, completion: @escaping ([VisionDetection]) -> Void) {
        // Use Vision framework object recognition
        performVisionObjectRecognition(on: pixelBuffer, returnAllDetections: returnAllDetections) { visionDetections in
            // Return Vision detections (no fallback)
            completion(visionDetections)
        }
    }
    
    // Performs Vision framework object recognition
    private func performVisionObjectRecognition(on pixelBuffer: CVPixelBuffer, returnAllDetections: Bool, completion: @escaping ([VisionDetection]) -> Void) {
        var objectDetectionCompleted = false
        var classificationCompleted = false
        var faceDetectionCompleted = false
        var objectDetections: [VisionDetection] = []
        var classificationDetections: [VisionDetection] = []
        var faceDetections: [VisionDetection] = []
        
        print("🔍 Starting Vision recognition with returnAllDetections: \(returnAllDetections)")
        
        // Try animal detection first (provides bounding boxes)
        let animalDetectionRequest = VNRecognizeAnimalsRequest { [weak self] request, error in
            guard let self = self else { return }
            
            objectDetectionCompleted = true
            
            if let error = error {
                print("Vision animal detection error: \(error)")
            } else if let results = request.results as? [VNRecognizedObjectObservation] {
                print("🐾 Raw animal detection results: \(results.count) observations")
                for (index, obs) in results.enumerated() {
                    print("   \(index + 1). \(obs.labels.first?.identifier ?? "unknown") - confidence: \(obs.confidence)")
                }
                objectDetections = self.processVisionObjectResults(results, returnAllDetections: returnAllDetections)
                print("🐾 Processed animal detections: \(objectDetections.count) objects")
            }
            
            // If all requests are done, return the best result
            if classificationCompleted && faceDetectionCompleted {
                let finalDetections = self.getBestDetections(objectDetections: objectDetections, 
                                                           classificationDetections: classificationDetections, 
                                                           faceDetections: faceDetections,
                                                           returnAllDetections: returnAllDetections)
                print("🎯 Final detections to return: \(finalDetections.count) objects")
                completion(finalDetections)
            }
        }
        
        // Try classification as fallback (when object detection fails)
        let classificationRequest = VNClassifyImageRequest { [weak self] request, error in
            guard let self = self else { return }
            
            classificationCompleted = true
            
            if let error = error {
                print("Vision classification error: \(error)")
            } else if let results = request.results as? [VNClassificationObservation] {
                print("📋 Raw classification results: \(results.count) observations")
                for (index, obs) in results.prefix(5).enumerated() {
                    print("   \(index + 1). \(obs.identifier) - confidence: \(obs.confidence)")
                }
                classificationDetections = self.processVisionClassificationResults(results, returnAllDetections: returnAllDetections)
                print("📋 Processed classification detections: \(classificationDetections.count) objects")
            }
            
            // If all requests are done, return the best result
            if objectDetectionCompleted && faceDetectionCompleted {
                let finalDetections = self.getBestDetections(objectDetections: objectDetections, 
                                                           classificationDetections: classificationDetections, 
                                                           faceDetections: faceDetections,
                                                           returnAllDetections: returnAllDetections)
                print("🎯 Final detections to return: \(finalDetections.count) objects")
                completion(finalDetections)
            }
        }
        
        // Try face detection as additional fallback
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            faceDetectionCompleted = true
            
            if let error = error {
                print("Vision face detection error: \(error)")
            } else if let results = request.results as? [VNFaceObservation] {
                print("👤 Raw face detection results: \(results.count) observations")
                for (index, obs) in results.enumerated() {
                    print("   \(index + 1). Face - confidence: \(obs.confidence)")
                }
                faceDetections = self.processVisionFaceResults(results, returnAllDetections: returnAllDetections)
                print("👤 Processed face detections: \(faceDetections.count) objects")
            }
            
            // If all requests are done, return the best result
            if objectDetectionCompleted && classificationCompleted {
                let finalDetections = self.getBestDetections(objectDetections: objectDetections, 
                                                           classificationDetections: classificationDetections, 
                                                           faceDetections: faceDetections,
                                                           returnAllDetections: returnAllDetections)
                print("🎯 Final detections to return: \(finalDetections.count) objects")
                completion(finalDetections)
            }
        }
        
        // Configure the requests for better accuracy
        // Note: usesCPUOnly is deprecated in iOS 17.0+ and no longer needed
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([animalDetectionRequest, classificationRequest, faceDetectionRequest])
        } catch {
            print("Failed to perform Vision requests: \(error)")
            completion([])
        }
    }
    

    
    // Processes Vision object detection results (provides bounding boxes)
    private func processVisionObjectResults(_ results: [VNRecognizedObjectObservation], returnAllDetections: Bool) -> [VisionDetection] {
        var detections: [VisionDetection] = []
        print("🔍 Vision: Processing \(results.count) raw observations")
        
        // Use lower threshold for manual scans to get more objects
        let effectiveThreshold = returnAllDetections ? 0.2 : objectConfidenceThreshold
        print("🎯 Using confidence threshold: \(effectiveThreshold) (\(returnAllDetections ? "MANUAL SCAN" : "REGULAR"))")
        
        for observation in results {
            // Filter by confidence
            guard observation.confidence >= effectiveThreshold else { 
                print("❌ Filtered out \(observation.labels.first?.identifier ?? "unknown") - confidence \(observation.confidence) < threshold \(effectiveThreshold)")
                continue 
            }
            
            // Get the top label
            guard let topLabelObservation = observation.labels.first else { continue }
            
            let identifier = topLabelObservation.identifier
            let confidence = topLabelObservation.confidence
            
            // Filter out generic labels (but not during manual scans)
            if !returnAllDetections && isGenericLabel(identifier) { 
                print("❌ Filtered out generic label: \(identifier)")
                continue 
            }
            
            // Create detection with actual bounding box
            let boundingBox = observation.boundingBox
            let detection = VisionDetection(
                identifier: cleanupLabel(identifier),
                confidence: confidence,
                boundingBox: boundingBox
            )
            
            detections.append(detection)
            print("✅ Added detection: \(cleanupLabel(identifier)) (\(Int(confidence * 100))%)")
        }
        
        // Sort by confidence and return only the most confident detection
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        print("📊 Vision: \(detections.count) valid detections, returning \(returnAllDetections ? "ALL" : "TOP 1")")
        
        // Return only the top detection (most confident)
        return returnAllDetections ? sortedDetections : sortedDetections.prefix(1).map { $0 }
    }
    
    // Processes Vision face detection results
    private func processVisionFaceResults(_ results: [VNFaceObservation], returnAllDetections: Bool) -> [VisionDetection] {
        var detections: [VisionDetection] = []
        
        for observation in results {
            // Filter by confidence
            guard observation.confidence >= faceConfidenceThreshold else { continue }
            
            // Create detection with face bounding box
            let boundingBox = observation.boundingBox
            let detection = VisionDetection(
                identifier: "Person",
                confidence: observation.confidence,
                boundingBox: boundingBox
            )
            
            detections.append(detection)
        }
        
        // Sort by confidence and return only the most confident detection
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        
        // Return only the top detection (most confident)
        return returnAllDetections ? sortedDetections : sortedDetections.prefix(1).map { $0 }
    }
    
    // Processes Vision classification results (fallback when object recognition fails)
    private func processVisionClassificationResults(_ results: [VNClassificationObservation], returnAllDetections: Bool) -> [VisionDetection] {
        var detections: [VisionDetection] = []
        
        for observation in results {
            // Filter by confidence (lower threshold for classification)
            guard observation.confidence >= classificationConfidenceThreshold else { continue }
            
            let identifier = observation.identifier
            let confidence = observation.confidence
            
            // Filter out generic labels (but not during manual scans)
            if !returnAllDetections && isGenericLabel(identifier) { continue }
            
            // Create detection with estimated bounding box (center of frame)
            let boundingBox = CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)
            let detection = VisionDetection(
                identifier: cleanupLabel(identifier),
                confidence: confidence,
                boundingBox: boundingBox
            )
            
            detections.append(detection)
        }
        
        // Sort by confidence and return only the most confident detection
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        
        // Return only the top detection (most confident)
        return returnAllDetections ? sortedDetections : sortedDetections.prefix(1).map { $0 }
    }
    
    // Gets the best detection from all available methods
    private func getBestDetections(objectDetections: [VisionDetection], 
                                 classificationDetections: [VisionDetection], 
                                 faceDetections: [VisionDetection],
                                 returnAllDetections: Bool) -> [VisionDetection] {
        // Priority order: object detection > face detection > classification
        if !objectDetections.isEmpty {
            print("Vision: Using object detection (\(objectDetections.count) objects)")
            return returnAllDetections ? objectDetections : [objectDetections.first!]
        } else if !faceDetections.isEmpty {
            print("Vision: Using face detection (\(faceDetections.count) objects)")
            return returnAllDetections ? faceDetections : [faceDetections.first!]
        } else if !classificationDetections.isEmpty {
            print("Vision: Using classification detection (\(classificationDetections.count) objects)")
            return returnAllDetections ? classificationDetections : [classificationDetections.first!]
        } else {
            print("Vision: No objects detected")
            return []
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
    
    // Classifies a cropped region using Vision classification
    func classifyRegion(pixelBuffer: CVPixelBuffer, completion: @escaping (String?, Float?) -> Void) {
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let self = self else { completion(nil, nil); return }
            if let error = error {
                print("Vision region classification error: \(error)")
                completion(nil, nil)
                return
            }
            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first else {
                completion(nil, nil)
                return
            }
            // Filter out generic labels
            if self.isGenericLabel(top.identifier) {
                completion(nil, nil)
                return
            }
            completion(self.cleanupLabel(top.identifier), top.confidence)
        }
        // Note: usesCPUOnly is deprecated in iOS 17.0+ and no longer needed
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform Vision region classification: \(error)")
            completion(nil, nil)
        }
    }
} 