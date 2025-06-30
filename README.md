# BatSight 🦇👁️

A sophisticated iOS app that provides real-time object detection and navigation assistance using computer vision. BatSight helps users identify objects in their environment and provides audio feedback about their location and type.

## Features

### 🎯 Object Detection
- **Real-time camera-based object detection** using Vision framework
- **YOLOv8 integration ready** for enhanced detection capabilities
- **Single object focus** for clear, uncluttered detection
- **Confidence-based filtering** to ensure accurate detections

### 📍 Position Detection
- **Three-zone positioning**: Left, Center, Right
- **Precise bounding box analysis** for accurate object location
- **Distance filtering** to focus on nearby objects
- **Real-time position updates** as objects move

### 🔊 Audio Feedback
- **Speech synthesis** for hands-free operation
- **Intelligent announcements** that avoid repetition
- **Position-aware descriptions** (e.g., "Person on the left")
- **Confidence level reporting** for user awareness

### 🎛️ User Controls
- **Speech toggle** to enable/disable audio feedback
- **Camera mode activation** with haptic feedback
- **Real-time detection display** with confidence percentages
- **Accessibility-focused design** for inclusive use

## Technology Stack

- **SwiftUI** - Modern iOS UI framework
- **Vision Framework** - Apple's computer vision framework
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

#### `YOLOv8ModelManager`
Advanced object detection with:
- YOLOv8 model integration (when available)
- Fallback to Vision framework
- Non-maximum suppression (NMS)
- Generic label filtering
- Confidence threshold management

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
2. **Point your camera** at objects in your environment
3. **Listen for audio feedback** describing detected objects
4. **Use the speech toggle** to enable/disable audio

### Advanced Features
- **Distance filtering**: Only nearby objects are detected
- **Position awareness**: Objects are described by location
- **Confidence reporting**: Detection accuracy is communicated
- **Haptic feedback**: Physical feedback for mode changes

## Development

### Project Structure
```
BatSight/
├── Models/
│   ├── DetectionModel.swift      # Core detection state
│   └── YOLOv8Model.swift         # YOLOv8 integration
├── Views/
│   ├── ContentView.swift         # Main app interface
│   ├── CameraView.swift          # Camera and detection UI
│   ├── CameraFrame.swift         # Camera preview
│   └── ModeSelector.swift        # Mode selection
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
