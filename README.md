# BatSight 🦇👁️

A sophisticated iOS app that provides real-time object detection, text recognition, and navigation assistance using computer vision. BatSight helps visually impaired users identify objects and read text in their environment with comprehensive audio feedback.

## Features

### 🎯 Object Detection
- **Real-time camera-based object detection** using Vision framework
- **YOLOv8 integration ready** for enhanced detection capabilities
- **Single object focus** for clear, uncluttered detection
- **Confidence-based filtering** to ensure accurate detections
- **Distance estimation** with 5 categories (very close to very far)

### 📖 Text Recognition (OCR)
- **Real-time text recognition** using Vision framework
- **Intelligent text filtering** to remove OCR artifacts
- **Autocorrect functionality** for common OCR errors
- **Position-aware text reading** (left, center, right)
- **Speech synthesis** for recognized text

### 📍 Position Detection
- **Three-zone positioning**: Left, Center, Right
- **Precise bounding box analysis** for accurate object location
- **Distance filtering** to focus on nearby objects
- **Real-time position updates** as objects move

### 🧠 Intelligent Location Detection
- **"Where Am I?" feature** that analyzes detected objects
- **Environment inference** (kitchen, bedroom, office, street, etc.)
- **Smart fallback responses** when location can't be determined
- **2-second environment scan** for comprehensive analysis

### 🔊 Audio Feedback
- **Speech synthesis** for hands-free operation
- **Intelligent announcements** that avoid repetition
- **Position-aware descriptions** (e.g., "Person on the left")
- **Confidence level reporting** for user awareness
- **Custom messages** for navigation and location detection

### 🎛️ User Controls
- **Dual-mode interface**: Object Detection and Text Reader
- **Speech toggle** to enable/disable audio feedback
- **Haptic feedback** for all interactions
- **Real-time detection display** with confidence percentages
- **Accessibility-focused design** for inclusive use

## Technology Stack

- **SwiftUI** - Modern iOS UI framework
- **Vision Framework** - Apple's computer vision framework for object and text detection
- **Core ML** - Machine learning integration (YOLOv8 ready)
- **AVFoundation** - Camera and audio handling
- **Speech Framework** - Text-to-speech capabilities

## Architecture

### Core Components

#### `DetectionState`
Central state manager that handles:
- Object detection updates
- Speech announcements
- UI state management
- Change detection to avoid duplicate announcements
- Manual scan coordination
- Location inference

#### `VisionModelManager`
Primary object detection with:
- Multi-method detection (animal, classification, face)
- Generic label filtering
- Confidence threshold management
- Fallback detection methods

#### `YOLOv8ModelManager`
Advanced object detection with:
- YOLOv8 model integration (when available)
- Fallback to Vision framework
- Non-maximum suppression (NMS)
- Distance estimation based on bounding box size
- Generic label filtering

#### `TextReaderManager`
Text recognition system with:
- Vision framework OCR integration
- Intelligent text filtering and autocorrect
- Position detection for recognized text
- Real-time text overlay

#### `DirectionCalculator`
Computer vision utility for:
- Pixel analysis for object positioning
- Distance estimation
- Edge detection and object density analysis
- Configurable filtering thresholds

#### `SpeechManager`
Audio feedback system with:
- Natural language object descriptions
- Position-aware announcements
- Confidence level reporting
- Voice control feedback
- Custom messages for location detection

#### `HapticManager`
Tactile feedback system with:
- Light, medium, and heavy impact levels
- Consistent haptic feedback for all interactions
- Accessibility-focused tactile response

## Installation

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Physical device with camera (for testing)

### Setup
1. Clone the repository
2. Open `BatSight.xcodeproj` in Xcode
3. Select your development team in project settings
4. Build and run on a physical device

### YOLOv8 Integration (Optional)
For enhanced object detection:
1. Follow the guide in `YOLOv8_INTEGRATION.md`
2. Add a YOLOv8 model to your project
3. The app will automatically use YOLOv8 when available

## Usage

### Basic Operation
1. **Launch the app** and grant camera permissions
2. **Choose your mode**: Object Detection or Text Reader
3. **Point your camera** at objects or text in your environment
4. **Listen for audio feedback** describing detected objects or text
5. **Use the speech toggle** to enable/disable audio

### Advanced Features
- **"Where Am I?" button**: Analyzes environment and announces location
- **Distance filtering**: Only nearby objects are detected
- **Position awareness**: Objects are described by location
- **Confidence reporting**: Detection accuracy is communicated
- **Haptic feedback**: Physical feedback for all interactions
- **Text recognition**: Read printed or displayed text aloud

## Development

### Project Structure
```
BatSight/
├── Models/
│   ├── DetectionModel.swift      # Core detection state
│   ├── VisionModelManager.swift  # Vision framework integration
│   └── YOLOv8Model.swift         # YOLOv8 integration
├── Views/
│   ├── ContentView.swift         # Main app interface
│   ├── CameraView.swift          # Camera and detection UI
│   ├── ObjectDetectionFrame.swift # Object detection interface
│   └── TextReaderFrame.swift     # Text recognition interface
├── Utilities/
│   ├── DirectionCalculator.swift # Position detection
│   ├── SpeechManager.swift       # Audio feedback
│   └── HapticManager.swift       # Haptic feedback
└── Assets/
    └── [App icons and resources]
```

### Key Design Patterns
- **MVVM Architecture** with SwiftUI
- **ObservableObject** for state management
- **Protocol-oriented programming** for extensibility
- **Dependency injection** for testability
- **Accessibility-first design** principles

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- **Apple Vision Framework** for computer vision capabilities
- **Ultralytics YOLOv8** for advanced object detection
- **iOS Accessibility** for inclusive design principles

## Support

For questions or issues:
1. Check the documentation in `YOLOv8_INTEGRATION.md`
2. Review the troubleshooting guide in `GET_YOLOV8_MODEL.md`
3. Open an issue on GitHub

---

**BatSight** - Making the world more accessible through computer vision 🦇👁️
