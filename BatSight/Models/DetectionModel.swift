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
    @Published var speechEnabled: Bool = true
    
    // Speech manager for audio feedback
    private let speechManager = SpeechManager()
    
    // Track previous state to avoid duplicate announcements
    private var previousObjects: [DetectedObject] = []
    
    func updateDetections(_ objects: [DetectedObject]) {
        detectedObjects = objects
        
        if objects.isEmpty {
            currentDetectionText = "No objects detected"
            // Don't announce anything when no objects are detected
        } else {
            // Create a formatted string for display (without confidence percentage)
            let objectDescriptions = objects.map { object in
                "\(object.identifier) - \(object.position)"
            }
            currentDetectionText = objectDescriptions.joined(separator: "\n")
            
            // Announce new detections only if speech is enabled
            if speechEnabled {
                announceNewDetections(objects)
            }
        }
        
        previousObjects = objects
    }
    
    /// Announces new detections with speech feedback
    private func announceNewDetections(_ objects: [DetectedObject]) {
        // Don't announce anything if no objects are detected
        if objects.isEmpty {
            return
        }
        
        // If this is the first detection or objects have changed significantly
        if previousObjects.isEmpty || hasSignificantChange(objects) {
            if objects.count == 1 {
                // Single object - announce with details
                let object = objects[0]
                speechManager.announceObject(object.identifier, position: object.position, confidence: object.confidence)
            } else {
                // Multiple objects - announce summary
                speechManager.announceMultipleObjects(objects)
            }
        }
    }
    
    /// Checks if the detection has changed significantly enough to warrant a new announcement
    private func hasSignificantChange(_ newObjects: [DetectedObject]) -> Bool {
        // If number of objects changed
        if newObjects.count != previousObjects.count {
            return true
        }
        
        // Check for position changes first (most important for navigation)
        for (index, newObject) in newObjects.enumerated() {
            if index < previousObjects.count {
                let previousObject = previousObjects[index]
                // If position changed, always announce (even if same object)
                if newObject.position != previousObject.position {
                    return true
                }
            }
        }
        
        // Check for object type changes
        for (index, newObject) in newObjects.enumerated() {
            if index < previousObjects.count {
                let previousObject = previousObjects[index]
                if newObject.identifier != previousObject.identifier {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Stops any current speech
    func stopSpeech() {
        speechManager.stopSpeaking()
    }
    
    /// Checks if speech is currently playing
    var isSpeaking: Bool {
        return speechManager.isCurrentlySpeaking
    }
    
    /// Toggles speech on/off
    func toggleSpeech() {
        speechEnabled.toggle()
        if !speechEnabled {
            stopSpeech()
            // Announce voice muted (bypass speech enabled setting)
            speechManager.announceVoiceMuted()
        } else {
            // Announce voice unmuted (bypass speech enabled setting)
            speechManager.announceVoiceUnmuted()
        }
    }
    
    /// Announces camera mode activation
    func announceCameraModeActivated() {
        // Always announce navigation events, regardless of speech enabled setting
        speechManager.announceCameraModeActivated()
    }
    
    /// Announces camera mode deactivation
    func announceCameraModeDeactivated() {
        // Always announce navigation events, regardless of speech enabled setting
        speechManager.announceCameraModeDeactivated()
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
