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

---

## Overview

**BatSight** is an iOS application designed to assist visually impaired users in navigating their environment through real-time object detection and audio feedback. The app combines Apple's Vision framework with YOLOv8 machine learning models to provide accurate object detection, distance estimation, and directional guidance.

### Key Features
- **Real-time Object Detection**: Uses Vision framework for primary detection
- **Distance Estimation**: YOLOv8-based distance calculation
- **Directional Guidance**: 40%-20%-40% zone mapping (Left-Center-Right)
- **Audio Feedback**: Text-to-speech announcements with timing controls
- **Single Object Focus**: Processes only the most confident detection per frame
- **Accessibility-First Design**: Optimized for visually impaired users

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
        }
    }
}
```

**Purpose**: Initializes the shared detection state and sets up the root view hierarchy.

### 2. Main Menu (`ContentView.swift`)
- **Logo Interface**: Large, tappable Bat Sight logo
- **Navigation**: Seamless transition to camera mode
- **Visual Design**: Purple background (RGB: 45, 5, 102)
- **Accessibility**: Hidden back button for cleaner navigation

### 3. Camera Interface (`CameraFrame.swift`)
- **Header Bar**: Logo, detection text, and speech toggle
- **Detection Display**: Real-time object information
- **Speech Controls**: Visual feedback for audio settings
- **Camera Preview**: Rounded frame with white border
- **Navigation Events**: Audio announcements for mode changes

### 4. Camera Management (`CameraView.swift`)

#### CameraView Struct
- **Live Preview**: Real-time camera feed display
- **Detection Overlay**: Object information with color-coded details
- **Visual Styling**: White text, yellow confidence, cyan position, green distance

#### CameraManager Class
- **AVCaptureSession**: Manages camera hardware
- **Background Processing**: Separate queues for camera and detection
- **Vision Integration**: Seamless framework integration
- **Error Handling**: Graceful fallbacks and error recovery

---

## Detection Pipeline

### 1. Vision Framework Detection
```swift
// Primary detection method
visionModelManager.performDetection(on: pixelBuffer) { visionDetections in
    // Process Vision results
}
```

**Detection Methods**:
- **Animal Detection**: Primary method with bounding boxes
- **Classification**: General object recognition fallback
- **Face Detection**: Human detection support

**Processing Steps**:
1. Confidence filtering (threshold: 0.4)
2. Generic label removal
3. Label cleanup and formatting
4. Top detection selection

### 2. YOLOv8 Distance Estimation
```swift
// Distance estimation using bounding box area
yoloModelManager.extractBoundingBoxesForDistance(on: pixelBuffer) { yoloBoundingBoxes in
    let boxArea = yoloBox.width * yoloBox.height
    // Distance calculation based on area
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
    self.iou(yoloBox1, topVisionDetection.boundingBox) < 
    self.iou(yoloBox2, topVisionDetection.boundingBox)
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

### Accessibility Features
- **Large Touch Targets**: 75x75px logo buttons
- **High Contrast**: White text on dark background
- **Clear Navigation**: Hidden back buttons for simplicity
- **Audio Feedback**: Comprehensive speech announcements

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
"Camera Mode Activated"
"Camera Mode Deactivated"
"Voice muted"
"Voice unmuted"
```

#### Timing Controls
- **4-second minimum interval** between detection announcements
- **Immediate playback** for navigation events
- **Automatic interruption** of previous announcements
- **Cooldown bypass** for critical feedback

---

## Technical Implementation

### 1. State Management (`DetectionModel.swift`)

#### DetectionState Class
```swift
class DetectionState: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var currentDetectionText: String = "No objects detected"
    @Published var speechEnabled: Bool = true
    
    private let speechManager = SpeechManager()
    private var previousObjects: [DetectedObject] = []
    private let minimumAnnouncementInterval: TimeInterval = 4.0
}
```

**Key Features**:
- **Published Properties**: Automatic UI updates
- **Change Detection**: Tracks previous state
- **Speech Integration**: Direct speech manager access
- **Timing Control**: 4-second announcement intervals

#### DetectedObject Struct
```swift
struct DetectedObject {
    let identifier: String
    let confidence: Float
    let position: String
    let boundingBox: CGRect
    var distance: Float?
    var distanceCategory: String?
}
```

### 2. Vision Integration (`VisionModelManager.swift`)

#### Multi-Method Detection
```swift
private func performVisionObjectRecognition(on pixelBuffer: CVPixelBuffer, completion: @escaping ([VisionDetection]) -> Void) {
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
    // ... additional generic labels
])
```

### 3. YOLOv8 Integration (`YOLOv8Model.swift`)

#### Model Loading Strategy
```swift
private func setupModel() {
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
}
```

### Confidence Thresholds
- **Vision Object Detection**: 0.4
- **Vision Classification**: 0.3
- **Vision Face Detection**: 0.5
- **YOLOv8 Detection**: 0.3
- **YOLOv8 NMS**: 0.5

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
- **Single Object Focus**: Processes only the most confident detection
- **Efficient Pixel Sampling**: Strided sampling for performance
- **Early Termination**: Stops processing when sufficient data is collected
- **Caching**: Reuses model instances and configurations

### Battery Optimization
- **CPU-Only Processing**: Configurable for Vision requests
- **Efficient Queuing**: Minimizes background processing
- **Smart Timing**: Reduces unnecessary speech announcements
- **Adaptive Sampling**: Adjusts processing frequency based on activity

---

## Future Enhancements

### Potential Improvements
1. **Haptic Feedback**: Integration with HapticManager for tactile feedback
2. **Multiple Object Support**: Processing multiple objects simultaneously
3. **Custom Model Training**: Domain-specific object detection models
4. **Offline Processing**: Local processing without cloud dependencies
5. **User Preferences**: Customizable detection sensitivity and speech settings

### Accessibility Enhancements
1. **VoiceOver Integration**: Native iOS accessibility support
2. **Custom Gestures**: Swipe-based navigation controls
3. **Audio Profiles**: Different speech styles and speeds
4. **Haptic Patterns**: Distinct vibration patterns for different events
5. **External Device Support**: Integration with assistive devices

---

*This documentation provides a comprehensive overview of the BatSight iOS application's architecture, implementation details, and technical specifications. The app represents a sophisticated integration of multiple computer vision technologies optimized for accessibility and real-time performance.* 