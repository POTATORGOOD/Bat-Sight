//
//  CameraView.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Vision
import CoreML

// Main camera interface that displays the camera feed with object detection overlay and manages camera hardware
struct CameraView: View {
    @StateObject private var cameraManager: CameraManager
    @ObservedObject var detectionState: DetectionState
    
    init(detectionState: DetectionState) {
        self.detectionState = detectionState
        self._cameraManager = StateObject(wrappedValue: CameraManager(detectionState: detectionState))
    }
    
    var body: some View {
        ZStack {
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            // Overlay for detected objects
            VStack {
                Spacer()
                
                if !detectionState.detectedObjects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected Object:")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(detectionState.detectedObjects.enumerated()), id: \.offset) { index, detection in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text("• \(detection.identifier)")
                                                .font(.body)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Text("\(Int(detection.confidence * 100))%")
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                        }
                                        
                                        HStack {
                                            Text("Position: \(detection.position)")
                                                .font(.caption)
                                                .foregroundColor(.cyan)
                                            
                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.7))
                            .shadow(radius: 10)
                    )
                    .padding()
                }
            }
        }
        .onAppear {
            cameraManager.requestCameraPermission()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

// Manages camera hardware setup, video processing, and YOLOv8 object detection pipeline
class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var detectionState: DetectionState
    private let yoloModelManager = YOLOv8ModelManager()
    
    private var captureSession: AVCaptureSession
    private var videoOutput: AVCaptureVideoDataOutput
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let detectionQueue = DispatchQueue(label: "yolo.detection.queue")
    
    // Position detection state
    private var lastDetectionTime: Date = Date()
    private var positionCounter: Int = 0
    

    
    init(detectionState: DetectionState) {
        self.detectionState = detectionState
        self.captureSession = AVCaptureSession()
        self.videoOutput = AVCaptureVideoDataOutput()
        super.init()
        setupCamera()
    }
    
    // Sets up YOLOv8 model for object detection
    private func setupCoreMLModel() {
        // YOLOv8 model is initialized in YOLOv8ModelManager
        print("YOLOv8 model setup completed")
    }
    
    // Always requests camera permission when entering camera mode, allowing users to change their mind
    func requestCameraPermission() {
        // Always request camera permission when entering camera mode
        // This allows users to change their mind even if they previously denied access
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.startSession()
                } else {
                    print("Camera access denied by user")
                    // Could add UI feedback here if needed
                }
            }
        }
    }
    
    // Configures camera hardware, input/output streams, and video processing settings
    private func setupCamera() {
        print("Setting up camera...")
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium
        
        // Add camera input
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to access back camera")
            captureSession.commitConfiguration()
            return
        }
        print("Back camera found")
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("Camera input added")
            }
        } catch {
            print("Error setting up camera input: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        // Add video output
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            print("Video output added")
        }
        
        captureSession.commitConfiguration()
        print("Camera setup completed")
    }
    
    // Starts the camera capture session on a background queue
    func startSession() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                print("Starting camera session...")
                self.captureSession.startRunning()
                print("Camera session started: \(self.captureSession.isRunning)")
            }
        }
    }
    
    // Stops the camera capture session on a background queue
    func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    // Returns the capture session for the camera preview
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
    

    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    // Receives camera frames and triggers object detection processing
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Use Core ML object detection for position data
        performCoreMLObjectDetection(pixelBuffer: pixelBuffer)
    }
    
    // Main object detection pipeline that processes camera frames using YOLOv8
    private func performCoreMLObjectDetection(pixelBuffer: CVPixelBuffer) {
        // Quick check for significant objects before doing expensive YOLOv8 processing
        guard DirectionCalculator.hasSignificantObjects(pixelBuffer: pixelBuffer) else {
            // No significant objects detected, clear detections
            DispatchQueue.main.async {
                self.detectionState.updateDetections([])
            }
            return
        }
        
        // Use YOLOv8 for object detection
        yoloModelManager.performDetection(on: pixelBuffer) { [weak self] yoloDetections in
            guard let self = self else { return }
            
            // Convert YOLOv8 detections to DetectedObject format
            let detectedObjects: [DetectedObject] = yoloDetections.compactMap { yoloDetection in
                // Check if object is too far away using DirectionCalculator with configurable filtering
                // Using veryClose filtering to only detect objects within a few feet
                if DirectionCalculator.isObjectTooFarAway(pixelBuffer: pixelBuffer, position: yoloDetection.position, config: .veryClose) {
                    print("Object filtered out - too far away")
                    return nil
                }
                
                // Create DetectedObject from YOLOv8Detection
                return DetectedObject(from: yoloDetection)
            }
            
            DispatchQueue.main.async {
                self.detectionState.updateDetections(detectedObjects)
            }
        }
    }
}

// SwiftUI wrapper that bridges the camera manager to the UIKit camera preview
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> PreviewView {
        let previewView = PreviewView()
        previewView.session = cameraManager.getCaptureSession()
        return previewView
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Updates handled automatically by PreviewView
    }
}

// Custom UIView subclass that displays the camera feed using AVCaptureVideoPreviewLayer
class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
            videoPreviewLayer.videoGravity = .resizeAspectFill
        }
    }
}

#Preview {
    CameraView(detectionState: DetectionState())
}
