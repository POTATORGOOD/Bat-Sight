# YOLOv8 Integration for BatSight

This guide explains how to integrate YOLOv8 object detection into your BatSight iOS app, replacing the current Vision framework implementation.

## What Changed

### Before (Vision Framework)
- Used `VNClassifyImageRequest` for object classification
- Only identified what objects were present
- Position detection relied on pixel analysis
- Limited to single object detection per frame

### After (YOLOv8)
- Uses `VNCoreMLRequest` with YOLOv8 model for object detection
- Provides precise bounding box coordinates
- Multiple object detection in a single frame
- More accurate position detection based on actual object bounds
- Better performance and accuracy

## Files Added/Modified

### New Files
- `BatSight/Models/YOLOv8Model.swift` - YOLOv8 model manager
- `download_yolov8_model.py` - Script to download and convert YOLOv8 model
- `YOLOv8_INTEGRATION.md` - This guide

### Modified Files
- `BatSight/Models/DetectionModel.swift` - Added YOLOv8Detection support
- `BatSight/Views/CameraView.swift` - Replaced Vision with YOLOv8 detection

## Setup Instructions

### 1. Download and Convert YOLOv8 Model

Run the provided Python script to download and convert the YOLOv8n model:

```bash
python3 download_yolov8_model.py
```

This script will:
- Install required Python packages (ultralytics, coremltools, etc.)
- Download the YOLOv8n (nano) model
- Convert it to Core ML format
- Move the model file to your BatSight directory

### 2. Add Model to Xcode Project

1. Open your BatSight.xcodeproj in Xcode
2. Drag `yolov8n.mlmodel` from the BatSight directory into your project navigator
3. Make sure "Add to target" is checked for your BatSight target
4. Build the project to verify the model is properly integrated

### 3. Build and Test

1. Clean build folder (Product → Clean Build Folder)
2. Build and run your app
3. Test object detection in camera mode

## How It Works

### YOLOv8ModelManager
- Manages the YOLOv8 Core ML model
- Handles model loading and error fallback
- Processes detection results with bounding boxes
- Applies non-maximum suppression (NMS) to remove overlapping detections
- Filters out generic labels and low-confidence detections

### Detection Pipeline
1. **Pre-filtering**: Uses `DirectionCalculator.hasSignificantObjects()` to avoid expensive processing
2. **YOLOv8 Detection**: Performs object detection with bounding boxes
3. **Distance Filtering**: Uses `DirectionCalculator.isObjectTooFarAway()` to filter distant objects
4. **Position Calculation**: Calculates position (Left/Center/Right) based on bounding box center
5. **Speech Feedback**: Converts detections to `DetectedObject` format for speech announcements

### Position Detection
The new system uses actual bounding box coordinates instead of pixel analysis:

```swift
// Calculate position based on bounding box center
let centerX = boundingBox.midX

if centerX < 0.33 {
    self.position = "Left"
} else if centerX > 0.67 {
    self.position = "Right"
} else {
    self.position = "Center"
}
```

## Model Options

The current implementation uses YOLOv8n (nano) for speed. You can use other YOLOv8 variants:

- **YOLOv8n** (nano) - Fastest, smallest (6.7M parameters)
- **YOLOv8s** (small) - Good balance (11.2M parameters)
- **YOLOv8m** (medium) - Better accuracy (25.9M parameters)
- **YOLOv8l** (large) - High accuracy (43.7M parameters)
- **YOLOv8x** (xlarge) - Best accuracy (68.2M parameters)

To use a different model, modify the `modelName` in `YOLOv8ModelManager`:

```swift
private let modelName = "yolov8s" // Change to desired model
```

## Fallback System

If the YOLOv8 model fails to load, the system automatically falls back to the original Vision framework implementation, ensuring your app continues to work.

## Performance Considerations

- **Model Size**: YOLOv8n is ~6MB, suitable for mobile devices
- **Processing Speed**: YOLOv8n processes ~640x640 images at ~10-20 FPS on modern devices
- **Memory Usage**: Core ML optimizes memory usage automatically
- **Battery Impact**: YOLOv8n is designed for efficient inference

## Troubleshooting

### Model Not Found Error
```
YOLOv8 model not found in bundle. Please add yolov8n.mlmodel to your project.
```
**Solution**: Make sure the model file is added to your Xcode project target.

### Build Errors
If you get build errors related to Core ML:
1. Clean build folder (Product → Clean Build Folder)
2. Delete derived data (Window → Projects → Click arrow next to derived data path)
3. Rebuild project

### Performance Issues
If detection is too slow:
1. Try a smaller model (YOLOv8n instead of YOLOv8s)
2. Reduce input image size in the model conversion
3. Increase confidence threshold to reduce detections

### Accuracy Issues
If detection accuracy is poor:
1. Try a larger model (YOLOv8s or YOLOv8m)
2. Adjust confidence threshold
3. Fine-tune the generic label filtering

## Benefits of YOLOv8

1. **Better Accuracy**: YOLOv8 outperforms traditional classification models
2. **Multiple Objects**: Detect multiple objects simultaneously
3. **Precise Localization**: Get exact bounding box coordinates
4. **Real-time Performance**: Optimized for mobile inference
5. **Active Development**: Regular updates and improvements from Ultralytics

## Future Enhancements

- **Custom Training**: Train YOLOv8 on your specific use cases
- **Object Tracking**: Add object tracking across frames
- **Distance Estimation**: Use bounding box size for distance estimation
- **Gesture Recognition**: Detect hand gestures and movements
- **Obstacle Avoidance**: Enhanced navigation with precise object locations

## Resources

- [YOLOv8 Documentation](https://yolov8.com/)
- [Ultralytics GitHub](https://github.com/ultralytics/ultralytics)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Vision Framework](https://developer.apple.com/documentation/vision) 