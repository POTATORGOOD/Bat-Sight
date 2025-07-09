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
import Combine // Added for Combine subscriptions

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
                                        if let distance = detection.distance, let category = detection.distanceCategory {
                                            HStack {
                                                Text(String(format: "Distance: %.1f m", distance))
                                                    .font(.caption2)
                                                    .foregroundColor(.green)
                                                Text("[\(category)]")
                                                    .font(.caption2)
                                                    .foregroundColor(.orange)
                                            }
                                        } else if let distance = detection.distance {
                                            Text(String(format: "Distance: %.1f m", distance))
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                        } else if let category = detection.distanceCategory {
                                            Text("[\(category)]")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
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

// Manages camera hardware setup, video processing, and Vision framework object detection pipeline
class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var detectionState: DetectionState
    private let visionModelManager = VisionModelManager()
    
    private var captureSession: AVCaptureSession
    private var videoOutput: AVCaptureVideoDataOutput
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let detectionQueue = DispatchQueue(label: "vision.detection.queue")
    
    // Position detection state
    private var lastDetectionTime: Date = Date()
    private var positionCounter: Int = 0
    
    // Add a property to track if a manual full scan is requested
    private var manualFullScanRequested: Bool = false
    // Add a cancellables set for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    
    init(detectionState: DetectionState) {
        self.detectionState = detectionState
        self.captureSession = AVCaptureSession()
        self.videoOutput = AVCaptureVideoDataOutput()
        super.init()
        setupCamera()
        // Observe the manual scan request
        detectionState.$requestManualFullScan.sink { [weak self] requested in
            guard let self = self else { return }
            if requested {
                self.manualFullScanRequested = true
            }
        }.store(in: &cancellables)
    }
    
    // Sets up Vision model for object detection
    private func setupCoreMLModel() {
        // Vision model is initialized in VisionModelManager
        print("Vision model setup completed")
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
    
    // Main object detection pipeline that uses Vision for detection and YOLO for distance estimation
    private func performCoreMLObjectDetection(pixelBuffer: CVPixelBuffer) {
        let useAllObjects = manualFullScanRequested
        print("🔍 Detection mode: \(useAllObjects ? "MANUAL SCAN (all objects)" : "REGULAR (top object only)")")
        print("🔍 manualFullScanRequested: \(manualFullScanRequested)")
        print("🔍 detectionState.requestManualFullScan: \(detectionState.requestManualFullScan)")
        
        visionModelManager.performDetection(on: pixelBuffer, returnAllDetections: useAllObjects) { [weak self] visionDetections in
            guard let self = self else { return }
            print("📊 Vision returned \(visionDetections.count) detections")
            
            // If no Vision detections, clear
            if visionDetections.isEmpty {
                DispatchQueue.main.async {
                    self.detectionState.updateDetections([])
                    // Reset manual scan flag if it was set
                    if self.manualFullScanRequested {
                        self.manualFullScanRequested = false
                        self.detectionState.requestManualFullScan = false
                    }
                }
                return
            }
            
            // If manual scan, use all objects; otherwise, use only the top detection
            let detectionsToProcess: [VisionDetection]
            if useAllObjects {
                detectionsToProcess = visionDetections
                print("🎯 Manual scan: Processing ALL \(detectionsToProcess.count) objects")
            } else {
                detectionsToProcess = [visionDetections.sorted(by: { $0.confidence > $1.confidence }).first!]
                print("🎯 Regular detection: Processing TOP 1 object")
            }
            
            // For each detection, estimate distance using YOLO (optional: could parallelize)
            let yoloModelManager = YOLOv8ModelManager()
            yoloModelManager.extractBoundingBoxesForDistance(on: pixelBuffer) { [weak self] yoloBoundingBoxes in
                guard let self = self else { return }
                var detectedObjects: [DetectedObject] = []
                
                for visionDetection in detectionsToProcess {
                    // Find the best matching YOLO bounding box for the Vision detection
                    let bestYOLOBox = yoloBoundingBoxes.max(by: { yoloBox1, yoloBox2 in
                        self.iou(yoloBox1, visionDetection.boundingBox) < self.iou(yoloBox2, visionDetection.boundingBox)
                    })
                    
                    // Estimate distance from YOLO bounding box size (if available)
                    var distance: Float? = nil
                    var distanceCategory: String? = nil
                    
                    if let yoloBox = bestYOLOBox {
                        let boxArea = yoloBox.width * yoloBox.height
                        if boxArea >= 0.15 {
                            distance = 0.5
                            distanceCategory = "very close"
                        } else if boxArea >= 0.08 {
                            distance = 1.0
                            distanceCategory = "close"
                        } else if boxArea >= 0.04 {
                            distance = 1.5
                            distanceCategory = "medium"
                        } else if boxArea >= 0.02 {
                            distance = 2.5
                            distanceCategory = "far"
                        } else if boxArea > 0 {
                            distance = 4.0
                            distanceCategory = "very far"
                        }
                    }
                    
                    // Create DetectedObject with Vision label, YOLO bounding box for direction, and YOLO distance
                    let boundingBoxForDirection = bestYOLOBox ?? visionDetection.boundingBox
                    let detectedObject = DetectedObject(
                        identifier: visionDetection.identifier,
                        confidence: visionDetection.confidence,
                        boundingBox: boundingBoxForDirection,
                        distance: distance,
                        distanceCategory: distanceCategory
                    )
                    detectedObjects.append(detectedObject)
                }
                
                print("✅ Final detected objects: \(detectedObjects.count)")
                for (index, obj) in detectedObjects.enumerated() {
                    print("   \(index + 1). \(obj.identifier) (\(Int(obj.confidence * 100))%) - \(obj.position)")
                }
                
                DispatchQueue.main.async {
                    self.detectionState.updateDetections(detectedObjects)
                    // Store objects for manual scan if in progress
                    if self.manualFullScanRequested {
                        self.detectionState.storeManualScanObjects(detectedObjects)
                        // Don't reset the flag here - let DetectionModel handle it
                    }
                    // Only reset the flag if it was set but we're not in manual scan mode
                    if self.manualFullScanRequested && !self.detectionState.isManualScanInProgress {
                        self.manualFullScanRequested = false
                        self.detectionState.requestManualFullScan = false
                    }
                }
            }
        }
    }
    
    // Helper function for IoU (Intersection over Union)
    private func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        let intersectionArea = intersection.width * intersection.height
        let unionArea = a.width * a.height + b.width * b.height - intersectionArea
        if unionArea <= 0 { return 0 }
        return intersectionArea / unionArea
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
