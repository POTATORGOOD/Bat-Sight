# YOLOv8 Integration Guide for BatSight

This guide explains how to integrate YOLOv8 object detection into your BatSight iOS app using the official Ultralytics framework.

## Overview

YOLOv8 provides superior object detection capabilities compared to Apple's Vision framework:
- **Multiple object detection** with precise bounding boxes
- **Higher accuracy** for complex scenes
- **Real-time performance** optimized for mobile devices
- **80+ object classes** including people, animals, vehicles, and everyday objects

## Quick Start (Recommended)

### 1. Run the Conversion Script

Use the provided conversion script for the easiest setup:

```bash
python3 convert_yolov8_to_coreml.py
```

This script will:
- Install required dependencies
- Download YOLOv8n (nano) model
- Convert to Core ML format with optimizations
- Provide instructions for adding to Xcode

### 2. Add Model to Xcode

1. **Drag the generated `.mlpackage` file** into your Xcode project
2. **Ensure "Add to target"** is checked for BatSight
3. **Build and run** - the app will automatically use YOLOv8

## Manual Setup (Advanced)

### Prerequisites

```bash
# Install Python 3.8-3.11 (Core ML tools compatibility)
brew install python@3.11

# Create virtual environment
python3.11 -m venv yolov8_env
source yolov8_env/bin/activate

# Install packages
pip install ultralytics coremltools
```

### Model Conversion

```python
from ultralytics import YOLO

# Load YOLOv8 model
model = YOLO('yolov8n.pt')  # or yolov8s.pt, yolov8m.pt, etc.

# Export to Core ML with optimizations
model.export(
    format='coreml',
    imgsz=640,        # Input image size
    simplify=True,    # Simplify model for better performance
    nms=True,         # Include NMS in the model
    int8=True,        # Quantize to int8 for smaller size
    half=True,        # Use half precision
    dynamic=True,     # Enable dynamic shapes
    device='cpu'      # Use CPU for conversion
)
```

## Model Size Comparison

| Model | Size | Speed | Accuracy | Use Case |
|-------|------|-------|----------|----------|
| YOLOv8n | ~6MB | Fastest | Good | Mobile apps, real-time |
| YOLOv8s | ~22MB | Fast | Better | Balanced performance |
| YOLOv8m | ~52MB | Medium | High | High accuracy needed |
| YOLOv8l | ~87MB | Slow | Very High | Maximum accuracy |
| YOLOv8x | ~136MB | Slowest | Highest | Research/offline |

**Recommendation**: Start with YOLOv8n for BatSight - it provides excellent performance for mobile use.

## Integration Details

### Swift Implementation

The `YOLOv8ModelManager` class handles:
- **Model loading** from app bundle
- **Object detection** using Vision framework wrapper
- **Result processing** with confidence filtering
- **Fallback to Vision** if YOLOv8 model unavailable

### Key Features

1. **Automatic Fallback**: If YOLOv8 model isn't available, the app uses Vision framework
2. **Single Object Focus**: Returns only the most confident detection for clarity
3. **Position Detection**: Calculates left/center/right positioning
4. **Generic Label Filtering**: Removes non-descriptive labels
5. **Non-Maximum Suppression**: Eliminates overlapping detections

### Performance Optimizations

- **Int8 quantization** for smaller model size
- **Half precision** for faster inference
- **Model simplification** for mobile optimization
- **Dynamic shapes** for flexible input sizes

## Troubleshooting

### Common Issues

1. **"Model not found" error**
   - Ensure `.mlpackage` file is added to Xcode project
   - Check that "Add to target" is selected
   - Verify file name matches `yolov8n.mlpackage`

2. **Conversion fails**
   - Use Python 3.8-3.11 (Core ML tools compatibility)
   - Install latest ultralytics: `pip install --upgrade ultralytics`
   - Try different model size (YOLOv8n is most reliable)

3. **App crashes on model load**
   - Check device compatibility (iOS 17.0+)
   - Verify model file integrity
   - Test with Vision framework fallback

### Debug Information

The app logs detailed information about model loading:
```
Looking for model: yolov8n.mlpackage
Found model at: /path/to/model
Compiled model at: /path/to/compiled/model
YOLOv8 model loaded successfully
```

## Advanced Configuration

### Custom Model Training

For domain-specific detection (e.g., accessibility objects):

1. **Collect dataset** of relevant objects
2. **Train custom YOLOv8 model** using Ultralytics
3. **Export to Core ML** using the same process
4. **Replace model file** in Xcode project

### Performance Tuning

Adjust these parameters in `YOLOv8ModelManager`:

```swift
private let confidenceThreshold: Float = 0.3  // Detection confidence
private let nmsThreshold: Float = 0.5         // Overlap suppression
```

## Resources

- [Ultralytics YOLOv8 Documentation](https://docs.ultralytics.com/)
- [Core ML Framework Guide](https://developer.apple.com/documentation/coreml)
- [Vision Framework Reference](https://developer.apple.com/documentation/vision)
- [BatSight GitHub Repository](https://github.com/your-repo/batsight)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review the conversion script output
3. Test with Vision framework fallback
4. Open an issue with detailed error information

---

**Note**: The app gracefully falls back to Vision framework if YOLOv8 is unavailable, ensuring it always works regardless of model status. 