//
//  TextReaderFrame.swift
//  BatSight
//
//  Created by Arnav Nair on 6/23/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Vision

// Text reader interface wrapper that provides navigation controls, text display, and speech toggle with audio feedback
struct TextReaderFrame: View {
    @EnvironmentObject var detectionState: DetectionState
    @State private var navigateToMain = false
    @State private var detectedText: String = "No text detected"
    @State private var isReadingText: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack (alignment:.center){
                    Button(action: {
                        // Provide haptic feedback
                        HapticManager.shared.lightImpact()
                        // Trigger navigation
                        navigateToMain = true
                    }) {
                        Image("Bat Sight")
                            .resizable()
                            .frame(width: 75, height: 75)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                    
                    VStack {
                        Text(detectedText)
                            .font(.custom("times", size: 30))
                            .foregroundStyle(Color(red: (241/255), green: (246/255), blue: (255/255)))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                    
                    // Speech toggle button
                    Button(action: {
                        // Provide haptic feedback
                        HapticManager.shared.lightImpact()
                        
                        detectionState.toggleSpeech()
                    }) {
                        Image(systemName: detectionState.speechEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundColor(detectionState.speechEnabled ? .green : .red)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 10)
                }
                .frame(maxWidth: .infinity , maxHeight: 75)
                .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
                .padding(.bottom, -10)
                ZStack {
                    // Background
                    Color(red: (45/255), green: (5/255), blue: (102/255))
                        .ignoresSafeArea()
                    
                    // Text reader view with frame
                    VStack {
                        TextReaderView(detectionState: detectionState, detectedText: $detectedText, isReadingText: $isReadingText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                    }
                    .padding()
                }
                
                Button(action: {
                    // Provide haptic feedback
                    HapticManager.shared.mediumImpact()
                    
                    // Check if speech is enabled before starting text reading
                    if !detectionState.speechEnabled {
                        // Remind user that voice is muted
                        detectionState.announceCustomMessage("Voice is muted")
                        return
                    }
                    
                    // Trigger text reading scan
                    isReadingText = true
                }) {
                    Text("Read Text")
                        .font(.custom("times", size: 50))
                        .foregroundStyle(Color(red: (241/255), green: (246/255), blue: (255/255)))
                        .frame(maxWidth: .infinity , maxHeight: 75)
                        .background(Color(red: (85/255), green: (5/255), blue: (200/255)))
                        .opacity(0.8)
                        .clipShape(Capsule())
                }
                .padding(.leading, 30)
                .padding(.trailing, 30)
                Spacer()
            }
        .frame(maxWidth: .infinity , maxHeight: .infinity)
        .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
        .navigationDestination(isPresented: $navigateToMain) {
            ContentView()
        }
    }
    .navigationBarBackButtonHidden(true)
    .onAppear {
        // Announce text reader mode activation
        detectionState.announceTextReaderModeActivated()
    }
    .onDisappear {
        // Announce text reader mode deactivation
        detectionState.announceTextReaderModeDeactivated()
    }
    }
}

// Text reader view that handles text recognition using Vision framework
struct TextReaderView: View {
    @ObservedObject var detectionState: DetectionState
    @Binding var detectedText: String
    @Binding var isReadingText: Bool
    @StateObject private var textReaderManager = TextReaderManager()
    @State private var detectedTextRegions: [TextRegion] = []
    
    var body: some View {
        ZStack {
            // Camera preview for text recognition
            TextReaderCameraView(textReaderManager: textReaderManager)
                .ignoresSafeArea()
            
            // Overlay for text recognition status
            VStack {
                Spacer()
                
                if isReadingText {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Reading text...")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
            }
            .padding(.bottom, 50)
            
            // Text detection results overlay
            if !detectedTextRegions.isEmpty {
                VStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected Text:")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(detectedTextRegions.enumerated()), id: \.offset) { index, region in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("• \(region.text)")
                                            .font(.body)
                                            .foregroundColor(.white)
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
                    
                    Spacer()
                }
            }
        }
        .onChange(of: isReadingText) { oldValue, newValue in
            if newValue {
                // Start text recognition
                textReaderManager.startTextRecognition { recognizedText, regions in
                    DispatchQueue.main.async {
                        if !recognizedText.isEmpty {
                            detectedText = recognizedText
                            detectedTextRegions = regions
                            // Announce the detected text if speech is enabled
                            if detectionState.speechEnabled {
                                detectionState.announceCustomMessage("Detected text: \(recognizedText)")
                            }
                        } else {
                            detectedText = "No text detected"
                            detectedTextRegions = []
                            if detectionState.speechEnabled {
                                detectionState.announceCustomMessage("No text found")
                            }
                        }
                        isReadingText = false
                    }
                }
            }
        }
    }
}

// Data structure for text regions
struct TextRegion {
    let text: String
    let confidence: Float
    let position: String
    let boundingBox: CGRect
    
    init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
        
        // Calculate relative position based on bounding box center
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

// Camera view for text recognition
struct TextReaderCameraView: UIViewRepresentable {
    let textReaderManager: TextReaderManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        textReaderManager.setupCamera(on: view)
        
        // Add text overlay view
        let overlayView = TextOverlayView()
        overlayView.frame = view.bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlayView)
        
        // Store reference to overlay view in manager
        textReaderManager.overlayView = overlayView
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Updates handled by TextReaderManager
    }
}

// Overlay view for displaying detected text regions
class TextOverlayView: UIView {
    private var textRegions: [CGRect] = []
    private var recognizedTexts: [String] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    func updateTextRegions(_ regions: [CGRect], texts: [String]) {
        textRegions = regions
        recognizedTexts = texts
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw bounding boxes and text for each detected text region
        for (index, region) in textRegions.enumerated() {
            let text = index < recognizedTexts.count ? recognizedTexts[index] : ""
            
            // Convert normalized coordinates to view coordinates
            let viewRect = CGRect(
                x: region.minX * bounds.width,
                y: region.minY * bounds.height,
                width: region.width * bounds.width,
                height: region.height * bounds.height
            )
            
            // Draw bounding box
            context.setStrokeColor(UIColor.green.cgColor)
            context.setLineWidth(2.0)
            context.stroke(viewRect)
            
            // Draw text label
            if !text.isEmpty {
                let labelRect = CGRect(
                    x: viewRect.minX,
                    y: viewRect.minY - 20,
                    width: viewRect.width,
                    height: 20
                )
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: UIColor.green,
                    .backgroundColor: UIColor.black.withAlphaComponent(0.7)
                ]
                
                let attributedString = NSAttributedString(string: text, attributes: attributes)
                attributedString.draw(in: labelRect)
            }
        }
    }
}

// Manager for text recognition using Vision framework
class TextReaderManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "text.reader.session.queue")
    private let recognitionQueue = DispatchQueue(label: "text.recognition.queue")
    
    private var textRecognitionRequest: VNRecognizeTextRequest?
    private var completionHandler: ((String, [TextRegion]) -> Void)?
    
    var overlayView: TextOverlayView? // Added to store the overlay view
    
    override init() {
        super.init()
        setupTextRecognition()
    }
    
    // Sets up Vision text recognition
    private func setupTextRecognition() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Text recognition error: \(error)")
                self.completionHandler?("", [])
                self.completionHandler = nil  // Clear the handler after use
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.completionHandler?("", [])
                self.completionHandler = nil  // Clear the handler after use
                return
            }
            
            // Extract recognized text and bounding boxes
            var recognizedStrings: [String] = []
            var boundingBoxes: [CGRect] = []
            var textRegions: [TextRegion] = []
            
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first {
                    let text = topCandidate.string
                    let confidence = topCandidate.confidence
                    let boundingBox = observation.boundingBox
                    
                    // Apply autocorrect to the text
                    let correctedText = self.correctText(text)
                    
                    // Filter this text region individually
                    let filteredText = self.filterRealWords(correctedText)
                    
                    if !filteredText.isEmpty {
                        recognizedStrings.append(filteredText)
                        boundingBoxes.append(boundingBox)
                        
                        // Create TextRegion object with corrected text
                        let textRegion = TextRegion(text: filteredText, confidence: confidence, boundingBox: boundingBox)
                        textRegions.append(textRegion)
                    }
                }
            }
            
            // Sort text regions from left to right for natural reading order
            let sortedIndices = textRegions.enumerated().sorted { first, second in
                first.element.boundingBox.minX < second.element.boundingBox.minX
            }.map { $0.offset }
            
            let sortedRecognizedStrings = sortedIndices.map { recognizedStrings[$0] }
            let sortedBoundingBoxes = sortedIndices.map { boundingBoxes[$0] }
            let sortedTextRegions = sortedIndices.map { textRegions[$0] }
            
            // Join text regions with periods for longer pauses between bullets
            let finalText = sortedRecognizedStrings.joined(separator: ". ")
            
            // Update overlay view with detected text regions
            DispatchQueue.main.async {
                self.overlayView?.updateTextRegions(sortedBoundingBoxes, texts: sortedRecognizedStrings)
            }
            
            self.completionHandler?(finalText, sortedTextRegions)
            self.completionHandler = nil  // Clear the handler after use
        }
        
        // Configure text recognition with enhanced language correction
        textRecognitionRequest?.recognitionLevel = .accurate
        textRecognitionRequest?.usesLanguageCorrection = true
        textRecognitionRequest?.minimumTextHeight = 0.01
        textRecognitionRequest?.recognitionLanguages = ["en-US"]
    }
    
    // Applies autocorrect to fix common OCR errors
    private func correctText(_ text: String) -> String {
        var correctedText = text
        
        // Common OCR corrections (but preserve currency amounts)
        let corrections: [String: String] = [
            "1": "l", "8": "b",
            "l0": "lo", "1l": "ll", "8o": "bo",
            "rn": "m", "cl": "d", "vv": "w", "nn": "m",
            "I0": "Io", "1I": "ll", "8I": "bl"
        ]
        
        // Apply corrections
        for (incorrect, correct) in corrections {
            correctedText = correctedText.replacingOccurrences(of: incorrect, with: correct)
        }
        
        // Fix common spacing issues
        correctedText = correctedText.replacingOccurrences(of: "  ", with: " ") // Double spaces
        correctedText = correctedText.replacingOccurrences(of: " .", with: ".") // Space before period
        correctedText = correctedText.replacingOccurrences(of: " ,", with: ",") // Space before comma
        
        // Capitalize first letter of sentences
        let sentences = correctedText.components(separatedBy: ". ")
        let capitalizedSentences = sentences.enumerated().map { index, sentence in
            if index == 0 || !sentence.isEmpty {
                return sentence.prefix(1).uppercased() + sentence.dropFirst()
            }
            return sentence
        }
        correctedText = capitalizedSentences.joined(separator: ". ")
        
        return correctedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Filters text to only include real words
    private func filterRealWords(_ text: String) -> String {
        // First merge separated letters into words
        let mergedText = mergeSeparatedLetters(text)
        let words = mergedText.components(separatedBy: .whitespacesAndNewlines)
        let filteredWords = words.filter { word in
            return isRealWord(word) // Pass the original word to isRealWord
        }
        return filteredWords.joined(separator: " ")
    }
    
    // Merges separated letters into complete words
    private func mergeSeparatedLetters(_ text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var result: [String] = []
        var currentWord = ""
        
        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            

            
            // If it's a single letter or number, accumulate it
            if cleanWord.count == 1 && (cleanWord.first?.isLetter == true || cleanWord.first?.isNumber == true) {
                currentWord += cleanWord
            } else {
                // If we have accumulated letters/numbers, add them as a word
                if !currentWord.isEmpty {
                    result.append(currentWord)
                    currentWord = ""
                }
                // Add the current word
                if !cleanWord.isEmpty {
                    result.append(cleanWord)
                }
            }
        }
        
        // Add any remaining accumulated letters/numbers
        if !currentWord.isEmpty {
            result.append(currentWord)
        }
        
        return result.joined(separator: " ")
    }
    
    // Checks if a word is a real English word using efficient pattern analysis
    private func isRealWord(_ word: String) -> Bool {
        let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        let originalWord = word.lowercased()
        
        // Skip empty words
        if cleanWord.isEmpty { return false }
        
        // Keep pure numbers (including those with currency symbols)
        let numberOnly = cleanWord.filter { $0.isNumber }
        if !numberOnly.isEmpty && cleanWord.filter({ $0.isLetter }).isEmpty {
            return true
        }
        
        // Keep currency amounts (like $123, €456, etc.)
        if originalWord.contains("$") || originalWord.contains("€") || originalWord.contains("£") {
            let currencyRemoved = originalWord.replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: "€", with: "")
                .replacingOccurrences(of: "£", with: "")
            if currencyRemoved.filter({ $0.isNumber }).count > 0 && currencyRemoved.filter({ $0.isLetter }).isEmpty {
                return true
            }
        }
        

        
        // Skip very short words (likely OCR artifacts)
        if cleanWord.count < 2 { return false }
        
        // Skip words that are mostly special characters
        let letterAndNumberCount = cleanWord.filter { $0.isLetter || $0.isNumber }.count
        let totalCount = cleanWord.count
        if totalCount > 0 && Double(letterAndNumberCount) / Double(totalCount) < 0.6 {
            return false
        }
        
        // Check for common English letter patterns (expanded list)
        let commonLetterPairs = ["th", "he", "an", "in", "er", "re", "on", "at", "nd", "st", "es", "en", "of", "te", "ed", "or", "ti", "hi", "as", "to", "it", "is", "be", "we", "he", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "man", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "its", "let", "put", "say", "she", "too", "use", "se", "ou", "us", "ss", "ue", "gg", "ie", "ie"]
        
        // Check if word contains at least one common letter pair (for longer words)
        let hasCommonPattern = commonLetterPairs.contains { pair in
            cleanWord.contains(pair)
        }
        
        // Only require common patterns for words longer than 5 characters
        if cleanWord.count > 5 && !hasCommonPattern {
            return false
        }
        
        // Check vowel-consonant ratio (English words typically have vowels)
        let vowels = CharacterSet(charactersIn: "aeiou")
        let vowelCount = cleanWord.filter { vowels.contains(UnicodeScalar(String($0))!) }.count
        let consonantCount = cleanWord.count - vowelCount
        
        // Skip words with no vowels or extremely poor vowel-consonant ratio
        if vowelCount == 0 || (consonantCount > 0 && Double(vowelCount) / Double(consonantCount) < 0.1) {
            return false
        }
        
        // Skip words with unrealistic letter combinations
        let unrealisticPatterns = ["qq", "ww", "xx", "zz", "jj", "kk", "qqq", "www", "xxx", "zzz"]
        for pattern in unrealisticPatterns {
            if cleanWord.contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    // Sets up camera for text recognition
    func setupCamera(on view: UIView) {
        // Request camera permission first
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.sessionQueue.async {
                    let session = AVCaptureSession()
                    session.sessionPreset = .high
                    
                    guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                        print("Failed to get camera")
                        return
                    }
                    
                    // Configure auto-focus
                    do {
                        try camera.lockForConfiguration()
                        
                        // Enable continuous auto-focus
                        if camera.isFocusModeSupported(.continuousAutoFocus) {
                            camera.focusMode = .continuousAutoFocus
                        }
                        
                        // Enable continuous auto-exposure
                        if camera.isExposureModeSupported(.continuousAutoExposure) {
                            camera.exposureMode = .continuousAutoExposure
                        }
                        
                        // Enable auto white balance
                        if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                            camera.whiteBalanceMode = .continuousAutoWhiteBalance
                        }
                        
                        camera.unlockForConfiguration()
                    } catch {
                        print("Failed to configure camera: \(error)")
                    }
                    
                    do {
                        let input = try AVCaptureDeviceInput(device: camera)
                        if session.canAddInput(input) {
                            session.addInput(input)
                        }
                        
                        let output = AVCaptureVideoDataOutput()
                        output.setSampleBufferDelegate(self, queue: self.recognitionQueue)
                        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                        
                        if session.canAddOutput(output) {
                            session.addOutput(output)
                        }
                        
                        self.captureSession = session
                        self.videoOutput = output
                        
                        DispatchQueue.main.async {
                            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                            previewLayer.frame = view.bounds
                            previewLayer.videoGravity = .resizeAspectFill
                            view.layer.addSublayer(previewLayer)
                        }
                        
                        session.startRunning()
                        
                    } catch {
                        print("Failed to setup camera: \(error)")
                    }
                }
            } else {
                print("Camera permission denied")
            }
        }
    }
    
    // Starts text recognition process
    func startTextRecognition(completion: @escaping (String, [TextRegion]) -> Void) {
        completionHandler = completion
        
        // Give a brief moment for camera to stabilize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // The recognition will be triggered by the next camera frame
        }
    }
    
    // Stops the camera session
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension TextReaderManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let textRecognitionRequest = textRecognitionRequest else { return }
        
        // Only process if we have a completion handler (meaning recognition was requested)
        guard completionHandler != nil else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            print("Failed to perform text recognition: \(error)")
            completionHandler?("", [])
        }
    }
}

#Preview {
    TextReaderFrame()
        .environmentObject(DetectionState())
} 