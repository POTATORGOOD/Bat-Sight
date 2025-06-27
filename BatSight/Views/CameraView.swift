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

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            DetectedObjectsOverlay(detectedObjects: cameraManager.detectedObjects)
        }
        .onAppear {
            cameraManager.requestCameraPermission()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

struct DetectedObjectsOverlay: View {
    let detectedObjects: [DetectedObject]
    var body: some View {
        VStack {
            Spacer()
            if !detectedObjects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Objects:")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(detectedObjects.enumerated()), id: \.offset) { index, detection in
                                HStack {
                                    Text("• \(detection.identifier)")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(detection.confidence * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
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
}

// Simple struct to hold detection results
struct DetectedObject {
    let identifier: String
    let confidence: Float
}

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var detectedObjects: [DetectedObject] = []
    
    private var captureSession: AVCaptureSession
    private var videoOutput: AVCaptureVideoDataOutput
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let visionQueue = DispatchQueue(label: "vision.queue")
    
    override init() {
        self.captureSession = AVCaptureSession()
        self.videoOutput = AVCaptureVideoDataOutput()
        super.init()
        setupCamera()
    }
    
    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.startSession()
                    }
                }
            }
        default:
            break
        }
    }
    
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
    
    func startSession() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                print("Starting camera session...")
                self.captureSession.startRunning()
                print("Camera session started: \(self.captureSession.isRunning)")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func getCaptureSession() -> AVCaptureSession {
        return captureSession
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Vision error: \(error)")
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            // Find the result with the highest confidence
            if let bestResult = results.max(by: { $0.confidence < $1.confidence }), bestResult.confidence > 0.3 {
                let detected = DetectedObject(identifier: bestResult.identifier, confidence: bestResult.confidence)
                DispatchQueue.main.async {
                    self.detectedObjects = [detected]
                }
            } else {
                DispatchQueue.main.async {
                    self.detectedObjects = []
                }
            }
        }
        
        visionQueue.async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform Vision request: \(error)")
            }
        }
    }
}

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

// Custom UIView subclass for camera preview
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
    CameraView()
}
