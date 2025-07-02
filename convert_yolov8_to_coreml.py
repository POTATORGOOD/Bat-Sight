#!/usr/bin/env python3
"""
YOLOv8 to Core ML Conversion Script
Uses official Ultralytics export functionality for reliable Core ML conversion
"""

import os
import sys
from pathlib import Path

def install_requirements():
    """Install required packages for YOLOv8 Core ML conversion"""
    print("Installing required packages...")
    
    # Install ultralytics and coremltools
    os.system("pip install ultralytics coremltools")
    
    print("✅ Requirements installed successfully")

def download_and_convert_yolov8():
    """Download YOLOv8 model and convert to Core ML format"""
    try:
        from ultralytics import YOLO
        
        print("🚀 Starting YOLOv8 to Core ML conversion...")
        
        # Download and load YOLOv8n model (nano version for speed)
        print("📥 Downloading YOLOv8n model...")
        model = YOLO('yolov8n.pt')
        
        # Export to Core ML format with optimized settings
        print("🔄 Converting to Core ML format...")
        model.export(
            format='coreml',
            imgsz=640,  # Input image size
            simplify=True,  # Simplify model for better performance
            nms=True,  # Include NMS in the model
            int8=True,  # Quantize to int8 for smaller size
            half=True,  # Use half precision
            device='cpu'  # Use CPU for conversion
        )
        
        print("✅ YOLOv8n Core ML model created successfully!")
        
        # Check if the model file was created
        model_path = Path("yolov8n.mlpackage")
        if model_path.exists():
            print(f"📁 Model saved as: {model_path.absolute()}")
            print(f"📊 Model size: {model_path.stat().st_size / (1024*1024):.1f} MB")
            
            # Instructions for adding to Xcode
            print("\n📱 To add to your BatSight project:")
            print("1. Drag yolov8n.mlpackage into your Xcode project")
            print("2. Make sure 'Add to target' is checked for BatSight")
            print("3. The app will automatically use YOLOv8 when available")
            
            return True
        else:
            print("❌ Model file not found after conversion")
            return False
            
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("Please run: pip install ultralytics coremltools")
        return False
    except Exception as e:
        print(f"❌ Conversion error: {e}")
        return False

def convert_different_sizes():
    """Convert different YOLOv8 model sizes"""
    models = {
        'yolov8n': 'Nano (fastest, smallest)',
        'yolov8s': 'Small (balanced)',
        'yolov8m': 'Medium (more accurate)',
        'yolov8l': 'Large (very accurate)',
        'yolov8x': 'Extra Large (most accurate)'
    }
    
    print("\n📋 Available YOLOv8 model sizes:")
    for model_name, description in models.items():
        print(f"  • {model_name}: {description}")
    
    choice = input("\nWhich model size would you like to convert? (n/s/m/l/x): ").lower()
    
    if choice in ['n', 's', 'm', 'l', 'x']:
        model_name = f"yolov8{choice}"
        try:
            from ultralytics import YOLO
            
            print(f"🔄 Converting {model_name}...")
            model = YOLO(f'{model_name}.pt')
            
            model.export(
                format='coreml',
                imgsz=640,
                simplify=True,
                nms=True,
                int8=True,
                half=True,
                device='cpu'
            )
            
            model_path = Path(f"{model_name}.mlpackage")
            if model_path.exists():
                print(f"✅ {model_name}.mlpackage created successfully!")
                print(f"📊 Size: {model_path.stat().st_size / (1024*1024):.1f} MB")
                return True
                
        except Exception as e:
            print(f"❌ Error converting {model_name}: {e}")
            return False
    else:
        print("❌ Invalid choice")
        return False

def main():
    """Main conversion function"""
    print("🦇 BatSight YOLOv8 Core ML Converter")
    print("=" * 40)
    
    # Check if we should install requirements
    try:
        import ultralytics
        print("✅ Ultralytics already installed")
    except ImportError:
        install_requirements()
    
    # Ask user what they want to do
    print("\nWhat would you like to do?")
    print("1. Convert YOLOv8n (recommended for mobile)")
    print("2. Choose a different model size")
    print("3. Exit")
    
    choice = input("\nEnter your choice (1-3): ")
    
    if choice == "1":
        success = download_and_convert_yolov8()
    elif choice == "2":
        success = convert_different_sizes()
    elif choice == "3":
        print("👋 Goodbye!")
        return
    else:
        print("❌ Invalid choice")
        return
    
    if success:
        print("\n🎉 Conversion completed successfully!")
        print("Your BatSight app is ready to use YOLOv8!")
    else:
        print("\n❌ Conversion failed. Check the error messages above.")

if __name__ == "__main__":
    main() 