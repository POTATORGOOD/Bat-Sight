# BatSight iOS App - Complete Code Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Components](#core-components)
4. [Detection Pipeline](#detection-pipeline)
5. [User Interface](#user-interface)
6. [Audio Feedback](#audio-feedback)
7. [Technical Implementation](#technical-implementation)
8. [Configuration](#configuration)
9. [Text Recognition](#text-recognition)
10. [Manual Scan Feature](#manual-scan-feature)

---

## Overview

**BatSight** is an iOS application designed to assist visually impaired users in navigating their environment through real-time object detection and audio feedback. The app combines Apple's Vision framework with YOLOv8 machine learning models to provide accurate object detection, distance estimation, and directional guidance.

### Key Features
- **Real-time Object Detection**: Uses Vision framework for primary detection with YOLOv8 integration
- **Distance Estimation**: YOLOv8-based distance calculation with 5 categories
- **Directional Guidance**: 40%-20%-40% zone mapping (Left-Center-Right)
- **Audio Feedback**: Text-to-speech announcements with intelligent timing controls
- **Single Object Focus**: Processes only the most confident detection per frame
- **Text Recognition**: OCR capabilities using Vision framework with intelligent filtering
- **Manual Environment Scan**: "Where Am I?" feature that analyzes objects to infer location
- **Accessibility-First Design**: Optimized for visually impaired users with haptic feedback
- **Haptic Feedback**: Tactile response for all user interactions
- **Intelligent Location Detection**: Analyzes detected objects to infer environment (kitchen, bedroom, street, etc.)

---

## Architecture

### Hybrid Detection System
The app employs a sophisticated hybrid approach combining multiple computer vision technologies:

```
Camera Feed → Vision Framework → Object Detection & Classification
                ↓
            YOLOv8 Model → Distance Estimation & Precise Bounding Boxes
                ↓
            Custom Analysis → Direction Calculation & Distance Filtering
                ↓
            Speech Synthesis → Audio Feedback
```

### State Management
- **DetectionState**: Central state manager using SwiftUI's `@ObservableObject`
- **Published Properties**: Automatic UI updates when detection state changes
- **Speech Management**: Integrated audio feedback with cooldown controls
- **Change Detection**: Prevents duplicate announcements
- **Manual Scan Coordination**: Handles environment analysis requests

---

## Core Components

### 1. App Entry Point (`BatSightApp.swift`)
```swift
@main
struct BatSightApp: App {
    @StateObject private var detectionState = DetectionState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(detectionState)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        detectionState.announceCustomMessage("Welcome to BatSight. Your visual assistant is ready.")
                    }
                }
        }
    }
}
```

**Purpose**: Initializes the shared detection state, sets up the root view hierarchy, and provides welcome message.

### 2. Main Menu (`ContentView.swift`)
- **Dual Mode Interface**: Camera mode and Text Reader mode
- **Logo Interface**: Large, tappable Bat Sight logo for navigation
- **Visual Design**: Purple background (RGB: 45, 5, 102)
- **Accessibility**: Hidden back button for cleaner navigation
- **Haptic Feedback**: Light tactile response for all interactions
- **Navigation**: Seamless transition to both camera and text reader modes

### 3. Object Detection Frame (`ObjectDetectionFrame.swift`)
- **Header Bar**: Logo, detection text, and speech toggle
- **Detection Display**: Real-time object information with confidence and distance
- **Speech Controls**: Visual feedback for audio settings
- **Camera Preview**: Rounded frame with white border and shadow
- **Navigation Events**: Audio announcements for mode changes
- **Haptic Feedback**: Light feedback for navigation and toggles, medium feedback for main actions
- **"Where Am I?" Button**: Analyzes all detected objects during a manual scan and infers the user's environment

### 4. Text Reader Frame (`TextReaderFrame.swift`)
- **Header Bar**: Logo, detected text display, and speech toggle
- **Text Recognition**: OCR capabilities with intelligent filtering
- **Camera Preview**: Rounded frame with text overlay
- **"Read Text" Button**: Activates text recognition with haptic feedback
- **Text Display**: Shows recognized text with position information
- **Navigation Events**: Audio announcements for mode changes

### 5. Camera Management (`CameraView.swift`)

#### CameraView Struct
- **Live Preview**: Real-time camera feed display
- **Detection Overlay**: Object information with color-coded details
- **Visual Styling**: White text, yellow confidence, cyan position, green distance

#### CameraManager Class
- **AVCaptureSession**: Manages camera hardware
- **Background Processing**: Separate queues for camera and detection
- **Vision Integration**: Seamless framework integration
- **Error Handling**: Graceful fallbacks and error recovery
- **Manual Scan Support**: Handles full environment scanning

---

## Detection Pipeline

### 1. Vision Framework Detection
```swift
// Primary detection method with multiple fallbacks
visionModelManager.performDetection(on: pixelBuffer, returnAllDetections: useAllObjects) { visionDetections in
    // Process Vision results
}
```

**Detection Methods**:
- **Animal Detection**: Primary method with bounding boxes
- **Classification**: General object recognition fallback
- **Face Detection**: Human detection support

**Processing Steps**:
1. Confidence filtering (threshold: 0.4 for objects, 0.2 for manual scans)
2. Generic label removal
3. Label cleanup and formatting
4. Top detection selection (or all for manual scans)

### 2. YOLOv8 Distance Estimation
```swift
// Distance estimation using bounding box area
yoloModelManager.extractBoundingBoxesForDistance(on: pixelBuffer) { yoloBoundingBoxes in
    let boxArea = yoloBox.width * yoloBox.height
    if boxArea >= 0.15 {
        distance = 0.5
        distanceCategory = "very close"
    } else if boxArea >= 0.08 {
        distance = 1.0
        distanceCategory = "close"
    }
    // ... additional distance categories
}
```

**Distance Categories**:
- **Very Close**: ≥15% area (0.5m)
- **Close**: ≥8% area (1.0m)
- **Medium**: ≥4% area (1.5m)
- **Far**: ≥2% area (2.5m)
- **Very Far**: >0% area (4.0m)

### 3. Direction Calculation
```swift
// 40%-20%-40% zone mapping
let centerX = boundingBox.midX
if centerX < 0.4 {
    position = "Left"
} else if centerX > 0.6 {
    position = "Right"
} else {
    position = "Center"
}
```

**Zone Distribution**:
- **Left Zone**: 0-40% of frame width
- **Center Zone**: 40-60% of frame width
- **Right Zone**: 60-100% of frame width

### 4. IoU Matching
```swift
// Find best matching YOLO box for Vision detection
let bestYOLOBox = yoloBoundingBoxes.max(by: { yoloBox1, yoloBox2 in
    self.iou(yoloBox1, visionDetection.boundingBox) < 
    self.iou(yoloBox2, visionDetection.boundingBox)
})
```

**Purpose**: Matches Vision detections with YOLO bounding boxes for accurate distance estimation.

---

## User Interface

### Visual Design Elements
- **Color Scheme**: Purple background (RGB: 45, 5, 102)
- **Text Colors**: White primary, yellow confidence, cyan position, green distance
- **Rounded Corners**: 20px radius for camera frame
- **Shadows**: White glow effect for camera preview
- **Typography**: Custom Times font for detection text
- **Haptic Feedback**: All buttons and navigation elements provide tactile feedback

### Accessibility Features
- **Large Touch Targets**: 75x75px logo buttons, 185x185px mode buttons
- **High Contrast**: White text on dark background
- **Clear Navigation**: Hidden back buttons for simplicity
- **Audio Feedback**: Comprehensive speech announcements
- **Haptic Feedback**: Consistent tactile response for all interactions
- **Intelligent Location Detection**: Environment inference with spoken feedback

### Detection Display
```
Detected Object:
• Person - Left
Position: Left
Distance: 1.0 m [close]
```

**Information Hierarchy**:
1. Object identifier
2. Confidence percentage
3. Position (Left/Center/Right)
4. Distance and category

---

## Audio Feedback

### SpeechManager Class
```swift
@MainActor
class SpeechManager: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let speechRate: Float = 0.5
    private let speechPitch: Float = 1.0
    private let speechVolume: Float = 0.8
    private let speechCooldown: TimeInterval = 2.0
}
```

### Audio Configuration
- **Speech Rate**: 0.5 (slower for clarity)
- **Pitch**: 1.0 (natural pitch)
- **Volume**: 0.8 (80% volume)
- **Cooldown**: 2 seconds between announcements
- **Audio Session**: `.playback` mode with `.spokenAudio`

### Announcement Types

#### Object Detection
```
"Person detected Left, close, 1.0 meters"
```

#### Navigation Events
```
"Object Detection Activated"
"Object Detection Deactivated"
"Text Reader Activated"
"Text Reader Deactivated"
"Voice muted"
"Voice unmuted"
```

#### Custom Messages
```
"Welcome to BatSight. Your visual assistant is ready."
"Scanning environment"
"You appear to be in a kitchen."
"No objects detected. Try looking around."
```

#### Timing Controls
- **4-second minimum interval** between detection announcements
- **Immediate playback** for navigation events and custom messages
- **Automatic interruption** of previous announcements
- **Cooldown bypass** for critical feedback

---

## Technical Implementation

### 1. State Management (`DetectionModel.swift`)

#### DetectionState Class
```swift
@MainActor
class DetectionState: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var currentDetectionText: String = "No objects detected"
    @Published var speechEnabled: Bool = true
    @Published var requestManualFullScan: Bool = false
    
    private let speechManager = SpeechManager()
    private var previousObjects: [DetectedObject] = []
    private let minimumAnnouncementInterval: TimeInterval = 4.0
    private var _isManualScanInProgress: Bool = false
    private var manualScanObjects: [DetectedObject] = []
}
```

**Key Features**:
- **Published Properties**: Automatic UI updates
- **Change Detection**: Tracks previous state
- **Speech Integration**: Direct speech manager access
- **Timing Control**: 4-second announcement intervals
- **Manual Scan Support**: Environment analysis coordination

#### DetectedObject Struct
```swift
struct DetectedObject {
    let identifier: String
    let confidence: Float
    let position: String
    let boundingBox: CGRect
    var distance: Float?
    var distanceCategory: String?
    
    init(identifier: String, confidence: Float, boundingBox: CGRect, distance: Float? = nil, distanceCategory: String? = nil) {
        // Position calculation based on bounding box center
        let centerX = boundingBox.midX
        if centerX < 0.4 {
            self.position = "Left"
        } else if centerX > 0.6 {
            self.position = "Right"
        } else {
            self.position = "Center"
        }
    }
}
```

### 2. Vision Integration (`VisionModelManager.swift`)

#### Multi-Method Detection
```swift
private func performVisionObjectRecognition(on pixelBuffer: CVPixelBuffer, returnAllDetections: Bool, completion: @escaping ([VisionDetection]) -> Void) {
    let animalDetectionRequest = VNRecognizeAnimalsRequest { ... }
    let classificationRequest = VNClassifyImageRequest { ... }
    let faceDetectionRequest = VNDetectFaceRectanglesRequest { ... }
    
    try handler.perform([animalDetectionRequest, classificationRequest, faceDetectionRequest])
}
```

#### Generic Label Filtering
```swift
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
```

### 3. YOLOv8 Integration (`YOLOv8Model.swift`)

#### Model Loading Strategy
```swift
private func setupModel() {
    do {
        // 1. Try compiled model (.mlmodelc)
        if let compiledModelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
            model = try VNCoreMLModel(for: MLModel(contentsOf: compiledModelURL))
        }
        // 2. Try source model (.mlpackage)
        else if let modelURL = Bundle.main.url(forResource: modelName, withExtension: modelExtension) {
            let compiledModelURL = try MLModel.compileModel(at: modelURL)
            model = try VNCoreMLModel(for: MLModel(contentsOf: compiledModelURL))
        }
        // 3. Fallback to Vision framework
        else {
            setupVisionFallback()
        }
    } catch {
        setupVisionFallback()
    }
}
```

#### Non-Maximum Suppression
```swift
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
```

### 4. Direction Calculation (`DirectionCalculator.swift`)

#### Pixel Analysis
```swift
static func determineObjectPosition(from pixelBuffer: CVPixelBuffer) -> String {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }
    
    let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
    
    let leftRegion = analyzeImageRegion(buffer: buffer, bytesPerRow: bytesPerRow, width: width, height: height, region: .left)
    let centerRegion = analyzeImageRegion(buffer: buffer, bytesPerRow: bytesPerRow, width: width, height: height, region: .center)
    let rightRegion = analyzeImageRegion(buffer: buffer, bytesPerRow: bytesPerRow, width: width, height: height, region: .right)
    
    // Return region with highest activity
}
```

#### Distance Filtering
```swift
static func isObjectTooFarAway(pixelBuffer: CVPixelBuffer, position: String, config: DistanceConfig = .default) -> Bool {
    // Analyze pixel density, edge strength, and object size
    let objectDensity = Double(significantPixels) / Double(totalPixels)
    let objectSizePercentage = objectBounds.getSizePercentage()
    
    let isTooFarByDensity = objectDensity < config.minObjectDensity
    let isTooFarByEdgeStrength = maxEdgeStrength < config.minEdgeStrength
    let isTooFarBySize = objectSizePercentage < config.minObjectSize
    
    if config.aggressiveFiltering {
        return isTooFarByDensity || isTooFarByEdgeStrength || isTooFarBySize
    } else {
        let failedCriteria = [isTooFarByDensity, isTooFarByEdgeStrength, isTooFarBySize].filter { $0 }.count
        return failedCriteria >= 2
    }
}
```

### 5. Haptic Feedback (`HapticManager.swift`)
```swift
class HapticManager {
    static let shared = HapticManager()
    
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}
```

---

## Text Recognition

### TextReaderManager Class
```swift
class TextReaderManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var textRecognitionRequest: VNRecognizeTextRequest?
    private var completionHandler: ((String, [TextRegion]) -> Void)?
    var overlayView: TextOverlayView?
}
```

### OCR Features
- **Vision Framework Integration**: Uses VNRecognizeTextRequest
- **Intelligent Filtering**: Removes OCR artifacts and non-words
- **Autocorrect**: Fixes common OCR errors
- **Position Detection**: Calculates text position (Left/Center/Right)
- **Real-time Overlay**: Visual bounding boxes for detected text
- **Natural Reading Order**: Sorts text from left to right

### Text Processing
```swift
private func correctText(_ text: String) -> String {
    var correctedText = text
    
    // Common OCR corrections
    let corrections: [String: String] = [
        "1": "l", "8": "b", "l0": "lo", "1l": "ll", "8o": "bo",
        "rn": "m", "cl": "d", "vv": "w", "nn": "m"
    ]
    
    // Apply corrections and formatting
    for (incorrect, correct) in corrections {
        correctedText = correctedText.replacingOccurrences(of: incorrect, with: correct)
    }
    
    return correctedText.trimmingCharacters(in: .whitespacesAndNewlines)
}
```

### TextRegion Struct
```swift
struct TextRegion {
    let text: String
    let confidence: Float
    let position: String
    let boundingBox: CGRect
    
    init(text: String, confidence: Float, boundingBox: CGRect) {
        // Position calculation based on bounding box center
        let centerX = boundingBox.midX
        if centerX < 0.4 {
            self.position = "Left"
        } else if centerX > 0.6 {
            self.position = "Right"
        } else {
            self.position = "Center"
        }
    }
}
```

---

## Manual Scan Feature

### Environment Analysis
The "Where Am I?" feature performs intelligent environment analysis:

```swift
func performManualScan() {
    // Stop any current speech
    stopSpeech()
    
    // Set manual scan in progress
    _isManualScanInProgress = true
    
    // Request a full scan for the next frame
    requestManualFullScan = true
    
    // Announce that we're scanning the environment
    speechManager.announceCustomMessage("Scanning environment")
    
    // Wait exactly 2 seconds for detection to complete, then analyze
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        // Analyze objects to infer location
        let locationContext = self.inferLocationFromObjects(objectsToAnalyze)
        
        // Create a descriptive announcement
        let environmentDescription = "You appear to be in a \(locationContext)."
        self.speechManager.announceCustomMessage(environmentDescription)
    }
}
```

### Location Inference
```swift
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
    
    // Additional room types: bathroom, office, street, dining room, garage
    
    // Find the location with the highest score
    let locationScores = [
        "bedroom": bedroomMatches.count,
        "kitchen": kitchenMatches.count,
        "living room": livingRoomMatches.count,
        // ... additional locations
    ]
    
    let bestLocation = locationScores.max { $0.value < $1.value }
    
    if let location = bestLocation, location.value > 0 {
        return location.key
    } else {
        return "unknown location"
    }
}
```

### Supported Locations
- **Bedroom**: bed, pillow, mattress, nightstand, lamp, dresser, etc.
- **Kitchen**: refrigerator, stove, oven, microwave, sink, etc.
- **Living Room**: sofa, couch, tv, coffee table, lamp, etc.
- **Bathroom**: toilet, sink, shower, bathtub, mirror, etc.
- **Office**: desk, computer, laptop, monitor, keyboard, etc.
- **Street**: car, vehicle, tree, building, road, sidewalk, etc.
- **Dining Room**: table, chair, plate, bowl, cup, etc.
- **Garage**: car, vehicle, tool, toolbox, workbench, etc.

---

## Configuration

### Distance Configurations
```swift
struct DistanceConfig {
    static let `default` = DistanceConfig(
        minObjectDensity: 0.03,      // 3% of pixels
        minEdgeStrength: 60.0,       // Edge strength threshold
        minObjectSize: 0.05,         // 5% of frame
        aggressiveFiltering: false
    )
    
    static let aggressive = DistanceConfig(
        minObjectDensity: 0.05,      // 5% of pixels
        minEdgeStrength: 80.0,       // Higher threshold
        minObjectSize: 0.08,         // 8% of frame
        aggressiveFiltering: true
    )
    
    static let lenient = DistanceConfig(
        minObjectDensity: 0.015,     // 1.5% of pixels
        minEdgeStrength: 40.0,       // Lower threshold
        minObjectSize: 0.02,         // 2% of frame
        aggressiveFiltering: false
    )
    
    static let veryClose = DistanceConfig(
        minObjectDensity: 0.08,      // 8% of pixels (very close objects)
        minEdgeStrength: 100.0,      // Very high edge strength
        minObjectSize: 0.15,         // 15% of frame (very close)
        aggressiveFiltering: true
    )
    
    static let ultraClose = DistanceConfig(
        minObjectDensity: 0.12,      // 12% of pixels (extremely close)
        minEdgeStrength: 120.0,      // Very high edge strength
        minObjectSize: 0.25,         // 25% of frame (very close)
        aggressiveFiltering: true
    )
}
```

### Confidence Thresholds
- **Vision Object Detection**: 0.4 (regular), 0.2 (manual scan)
- **Vision Classification**: 0.3
- **Vision Face Detection**: 0.5
- **YOLOv8 Detection**: 0.3
- **YOLOv8 NMS**: 0.5
- **Text Recognition**: Variable based on confidence

### Speech Configuration
- **Speech Rate**: 0.5 (slower for clarity)
- **Speech Pitch**: 1.0 (natural pitch)
- **Speech Volume**: 0.8 (80% volume)
- **Cooldown Period**: 2.0 seconds
- **Minimum Announcement Interval**: 4.0 seconds

### Direction Zones
- **Left Zone**: 0-40% of frame width
- **Center Zone**: 40-60% of frame width
- **Right Zone**: 60-100% of frame width

---

## Performance Considerations

### Memory Management
- **Pixel Buffer Locking**: Proper locking/unlocking for thread safety
- **Background Queues**: Separate queues for camera and detection processing
- **Weak References**: Prevents retain cycles in closures
- **Automatic Cleanup**: Proper resource deallocation

### Processing Optimization
- **Single Object Focus**: Processes only the most confident detection (except manual scans)
- **Efficient Pixel Sampling**: Strided sampling for performance
- **Early Termination**: Stops processing when sufficient data is collected
- **Caching**: Reuses model instances and configurations

### Battery Optimization
- **CPU-Only Processing**: Configurable for Vision requests
- **Efficient Queuing**: Minimizes background processing
- **Smart Timing**: Reduces unnecessary speech announcements
- **Adaptive Sampling**: Adjusts processing frequency based on activity

---

*This documentation provides a comprehensive overview of the BatSight iOS application's architecture, implementation details, and technical specifications. The app represents a sophisticated integration of multiple computer vision technologies optimized for accessibility and real-time performance, with advanced features like text recognition and intelligent environment analysis.* 