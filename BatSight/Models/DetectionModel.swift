//
//  DetectionModel.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import SwiftUI

// Shared state for detected objects across the app
class DetectionState: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var currentDetectionText: String = "No objects detected"
    
    func updateDetections(_ objects: [DetectedObject]) {
        detectedObjects = objects
        
        if objects.isEmpty {
            currentDetectionText = "No objects detected"
        } else {
            // Create a formatted string for display (without confidence percentage)
            let objectDescriptions = objects.map { object in
                "\(object.identifier) - \(object.position)"
            }
            currentDetectionText = objectDescriptions.joined(separator: "\n")
        }
    }
}

// Simple struct to hold detection results
struct DetectedObject {
    let identifier: String
    let confidence: Float
    let position: String
    let boundingBox: CGRect
    
    init(identifier: String, confidence: Float, boundingBox: CGRect) {
        self.identifier = identifier
        self.confidence = confidence
        self.boundingBox = boundingBox
        
        // Calculate relative position based on bounding box center
        // Larger left/right zones, smaller center zone
        let centerX = boundingBox.midX
        
        if centerX < 0.49 {
            self.position = "Left"
        } else if centerX > 0.51 {
            self.position = "Right"
        } else {
            self.position = "Center"
        }
    }
}
