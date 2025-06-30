//
//  DetectionModel.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import SwiftUI

// Central state manager that handles object detection updates, speech announcements, and UI state
class DetectionState: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var currentDetectionText: String = "No objects detected"
    @Published var speechEnabled: Bool = true
    
    // Speech manager for audio feedback
    private let speechManager = SpeechManager()
    
    // Track previous state to avoid duplicate announcements
    private var previousObjects: [DetectedObject] = []
    
    // Updates the current detection state and triggers speech announcements if objects change significantly
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
    
    // Announces new detections with speech feedback, but only when there are meaningful changes
    private func announceNewDetections(_ objects: [DetectedObject]) {
        // Don't announce anything if no objects are detected
        if objects.isEmpty {
            return
        }
        
                    // If this is the first detection or objects have changed significantly
            if previousObjects.isEmpty || hasSignificantChange(objects) {
                // Always announce single object with details (since we only detect one now)
                if let object = objects.first {
                    speechManager.announceObject(object.identifier, position: object.position, confidence: object.confidence)
                }
            }
    }
    
    // Checks if the detection has changed significantly enough to warrant a new announcement
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
    
    // Stops any current speech
    func stopSpeech() {
        speechManager.stopSpeaking()
    }
    
    // Checks if speech is currently playing
    var isSpeaking: Bool {
        return speechManager.isCurrentlySpeaking
    }
    
    // Toggles speech on/off and announces the change
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
    
    // Announces camera mode activation (always announces navigation events, regardless of speech enabled setting)
    func announceCameraModeActivated() {
        // Always announce navigation events, regardless of speech enabled setting
        speechManager.announceCameraModeActivated()
    }
    
    // Announces camera mode deactivation (always announces navigation events, regardless of speech enabled setting)
    func announceCameraModeDeactivated() {
        // Always announce navigation events, regardless of speech enabled setting
        speechManager.announceCameraModeDeactivated()
    }
}

// Data structure that holds information about a detected object including its type, confidence, position, and location
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
        // Using YOLOv8-style positioning with 33% zones
        let centerX = boundingBox.midX
        
        if centerX < 0.33 {
            self.position = "Left"
        } else if centerX > 0.67 {
            self.position = "Right"
        } else {
            self.position = "Center"
        }
    }
    
    // Convenience initializer from YOLOv8Detection
    init(from yoloDetection: YOLOv8Detection) {
        self.identifier = yoloDetection.identifier
        self.confidence = yoloDetection.confidence
        self.position = yoloDetection.position
        self.boundingBox = yoloDetection.boundingBox
    }
}
