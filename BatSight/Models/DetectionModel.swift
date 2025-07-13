//
//  DetectionModel.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import SwiftUI

// Central state manager that handles object detection updates, speech announcements, and UI state
@MainActor
class DetectionState: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var currentDetectionText: String = "No objects detected"
    @Published var speechEnabled: Bool = true
    
    // Add a published property to request a manual scan with all objects
    @Published var requestManualFullScan: Bool = false
    
    // Speech manager for audio feedback
    private let speechManager = SpeechManager()
    
    // Track previous state to avoid duplicate announcements
    private var previousObjects: [DetectedObject] = []
    
    // Track manual scan state
    private var _isManualScanInProgress: Bool = false
    
    // Public getter for manual scan state
    var isManualScanInProgress: Bool {
        return _isManualScanInProgress
    }
    
    // Speech delay mechanism
    private var lastAnnouncementTime: Date = Date.distantPast
    private let minimumAnnouncementInterval: TimeInterval = 4.0 // 4 seconds between announcements
    
    // Add a property to store objects from manual scan
    private var manualScanObjects: [DetectedObject] = []
    
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
        
        // Check if enough time has passed since the last announcement
        let timeSinceLastAnnouncement = Date().timeIntervalSince(lastAnnouncementTime)
        if timeSinceLastAnnouncement < minimumAnnouncementInterval {
            print("Skipping announcement - too soon since last one (\(timeSinceLastAnnouncement)s)")
            return
        }
        
        // If this is the first detection or objects have changed significantly
        if previousObjects.isEmpty || hasSignificantChange(objects) {
            // Always announce single object with details (since we only detect one now)
            if let object = objects.first {
                lastAnnouncementTime = Date()
                speechManager.announceObject(object.identifier, position: object.position, confidence: object.confidence, distance: object.distance, distanceCategory: object.distanceCategory)
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
    
    // Announces text reader mode activation (always announces navigation events, regardless of speech enabled setting)
    func announceTextReaderModeActivated() {
        // Always announce navigation events, regardless of speech enabled setting
        speechManager.announceTextReaderModeActivated()
    }
    
    // Announces text reader mode deactivation (always announces navigation events, regardless of speech enabled setting)
    func announceTextReaderModeDeactivated() {
        // Always announce navigation events, regardless of speech enabled setting
        speechManager.announceTextReaderModeDeactivated()
    }
    
    // Announces a custom message (bypasses cooldown for immediate feedback)
    func announceCustomMessage(_ message: String) {
        // Always announce custom messages, regardless of speech enabled setting
        speechManager.announceCustomMessage(message)
    }
    
    // Performs a manual scan and announces the current environment
    func performManualScan() {
        // Stop any current speech
        stopSpeech()
        
        // Set manual scan in progress
        _isManualScanInProgress = true
        
        // Clear previous manual scan objects
        manualScanObjects = []
        
        // Request a full scan for the next frame
        requestManualFullScan = true
        
        print("🔍 Manual scan started - requestManualFullScan set to true")
        
        // Announce that we're scanning the environment
        speechManager.announceCustomMessage("Scanning environment")
        
        // Wait exactly 2 seconds for detection to complete, then analyze
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // End manual scan
            self._isManualScanInProgress = false
            
            // Reset the manual scan request
            self.requestManualFullScan = false
            
            print("🔍 Manual scan ended - requestManualFullScan set to false")
            print("🔍 Manual scan objects collected: \(self.manualScanObjects.count)")
            
            // Use the objects that were detected during manual scan
            let objectsToAnalyze = self.manualScanObjects.isEmpty ? self.detectedObjects : self.manualScanObjects
            
            if objectsToAnalyze.isEmpty {
                self.speechManager.announceCustomMessage("No objects detected. Try looking around.")
            } else {
                // Analyze objects to infer location
                let locationContext = self.inferLocationFromObjects(objectsToAnalyze)
                
                // Create a descriptive announcement
                let environmentDescription: String
                if locationContext == "unknown location" {
                    environmentDescription = "Objects detected, but location unknown."
                } else {
                    environmentDescription = "You appear to be in a \(locationContext)."
                }
                self.speechManager.announceCustomMessage(environmentDescription)
            }
        }
    }
    
    // Method to store objects from manual scan
    func storeManualScanObjects(_ objects: [DetectedObject]) {
        if _isManualScanInProgress {
            manualScanObjects = objects
            print("🔍 Stored \(objects.count) objects for manual scan")
        }
    }
    
    // Analyzes detected objects to infer the user's location context
    private func inferLocationFromObjects(_ objects: [DetectedObject]) -> String {
        let objectTypes = Set(objects.map { $0.identifier.lowercased() })
        
        // Bedroom indicators
        let bedroomObjects = ["bed", "pillow", "mattress", "nightstand", "lamp", "dresser", "wardrobe", "closet", "blanket", "sheet", "bedding", "curtain", "clothing", "electric fan", "interior room"]
        let bedroomMatches = objectTypes.intersection(bedroomObjects)
        
        // Kitchen indicators
        let kitchenObjects = ["refrigerator", "fridge", "stove", "oven", "microwave", "sink", "dishwasher", "counter", "table", "chair", "spoon", "fork", "knife", "plate", "bowl", "cup", "mug", "pot", "pan", "kettle", "coffee maker", "blender", "toaster"]
        let kitchenMatches = objectTypes.intersection(kitchenObjects)
        
        // Living room indicators
        let livingRoomObjects = ["sofa", "couch", "tv", "television", "coffee table", "lamp", "chair", "carpet", "rug", "bookshelf", "fireplace", "remote", "cushion", "throw pillow"]
        let livingRoomMatches = objectTypes.intersection(livingRoomObjects)
        
        // Bathroom indicators
        let bathroomObjects = ["toilet", "sink", "shower", "bathtub", "mirror", "towel", "soap", "toothbrush", "toilet paper", "shampoo", "conditioner"]
        let bathroomMatches = objectTypes.intersection(bathroomObjects)
        
        // Office indicators
        let officeObjects = ["desk", "computer", "laptop", "monitor", "keyboard", "mouse", "chair", "bookshelf", "printer", "paper", "pen", "pencil", "notebook", "file", "folder", "consumer electronics"]
        let officeMatches = objectTypes.intersection(officeObjects)
        
        // Street/outdoor indicators
        let streetObjects = ["car", "vehicle", "tree", "building", "road", "sidewalk", "street", "traffic light", "sign", "bench", "park", "grass", "flower", "bush", "sky", "cloud"]
        let streetMatches = objectTypes.intersection(streetObjects)
        
        // Dining room indicators
        let diningRoomObjects = ["table", "chair", "plate", "bowl", "cup", "glass", "napkin", "placemat", "centerpiece"]
        let diningRoomMatches = objectTypes.intersection(diningRoomObjects)
        
        // Garage indicators
        let garageObjects = ["car", "vehicle", "tool", "toolbox", "workbench", "shelf", "storage", "bicycle", "motorcycle"]
        let garageMatches = objectTypes.intersection(garageObjects)
        
        // Count matches for each location type
        let locationScores = [
            "bedroom": bedroomMatches.count,
            "kitchen": kitchenMatches.count,
            "living room": livingRoomMatches.count,
            "bathroom": bathroomMatches.count,
            "office": officeMatches.count,
            "street": streetMatches.count,
            "dining room": diningRoomMatches.count,
            "garage": garageMatches.count
        ]
        
        // Find the location with the highest score
        let bestLocation = locationScores.max { $0.value < $1.value }
        
        if let location = bestLocation, location.value > 0 {
            return location.key
        } else {
            // If no specific location detected, try to infer from general objects
            if objectTypes.contains("person") {
                return "room with people"
            } else if objectTypes.contains("chair") || objectTypes.contains("table") {
                return "indoor space"
            } else if objectTypes.contains("wall") || objectTypes.contains("door") {
                return "indoor area"
            } else {
                return "unknown location"
            }
        }
    }
}

// Data structure that holds information about a detected object including its type, confidence, position, and location
struct DetectedObject {
    let identifier: String
    let confidence: Float
    let position: String
    let boundingBox: CGRect
    var distance: Float? // in meters
    var distanceCategory: String? // e.g., "very close", "close", "far"
    
    init(identifier: String, confidence: Float, boundingBox: CGRect, distance: Float? = nil, distanceCategory: String? = nil) {
        self.identifier = identifier
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.distance = distance
        self.distanceCategory = distanceCategory
        
        // Calculate relative position based on bounding box center
        // Using 2/5-1/5-2/5 zones: Left (0-0.4), Center (0.4-0.6), Right (0.6-1.0)
        let centerX = boundingBox.midX
        
        if centerX < 0.4 {
            self.position = "Left"
        } else if centerX > 0.6 {
            self.position = "Right"
        } else {
            self.position = "Center"
        }
    }
    
    // Convenience initializer from YOLOv8Detection
    init(from yoloDetection: YOLOv8Detection, distance: Float? = nil, distanceCategory: String? = nil) {
        self.identifier = yoloDetection.identifier
        self.confidence = yoloDetection.confidence
        self.position = yoloDetection.position
        self.boundingBox = yoloDetection.boundingBox
        self.distance = distance
        self.distanceCategory = distanceCategory
    }
    
    // Convenience initializer from VisionDetection
    init(from visionDetection: VisionDetection, distance: Float? = nil, distanceCategory: String? = nil) {
        self.identifier = visionDetection.identifier
        self.confidence = visionDetection.confidence
        self.position = visionDetection.position
        self.boundingBox = visionDetection.boundingBox
        self.distance = distance
        self.distanceCategory = distanceCategory
    }
}
