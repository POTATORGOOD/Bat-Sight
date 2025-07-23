//
//  OnboardingView.swift
//  BatSight
//
//  Created by Arnav Nair on 6/16/25.
//

import SwiftUI
import Speech
import AVFoundation

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var username = ""
    @State private var isOnboardingComplete = false
    @State private var navigateToMainApp = false

    @State private var isListening = false
    @State private var speechRecognitionAttempts = 0

    @State private var selectedSignInMethod = ""
    @State private var showTermsAlert = false
    @State private var showPermissionsAlert = false
    @State private var nameVerified = false
    @State private var showNameVerification = false
    @State private var nameFromVoice = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var speechDetected = false
    @EnvironmentObject var detectionState: DetectionState
    @EnvironmentObject var onboardingState: OnboardingState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Logo and welcome text at the top
                VStack(spacing: 20) {
                    Image("Bat Sight")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .padding(.top, 60)
                    
                    Text("Welcome to BatSight \(nameVerified ? username : "")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Empowering your senses")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Content based on current step
                VStack(spacing: 0) {
                    switch currentStep {
                    case 0:
                        signInStep
                    case 1:
                        voiceInputStep
                    case 2:
                        nameVerificationStep
                    case 3:
                        appOverviewStep
                    default:
                        signInStep
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Navigation buttons
                if currentStep > 0 {
                    VStack(spacing: 16) {
                        if currentStep == 3 {
                            // Terms and Get Started for final step
                            VStack(spacing: 12) {
                                HStack {
                                    Button("Terms of Service") {
                                        showTermsAlert = true
                                    }
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 14, weight: .medium))
                                    
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Button("Permissions") {
                                        showPermissionsAlert = true
                                    }
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 14, weight: .medium))
                                }
                                
                                Button(action: {
                                    HapticManager.shared.lightImpact()
                                    completeOnboarding()
                                }) {
                                    Text("Get Started")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color(red: (85/255), green: (5/255), blue: (200/255)))
                                        .cornerRadius(16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else if currentStep != 1 {
                            // Continue button for all steps except voice input step
                            Button(action: {
                                HapticManager.shared.lightImpact()
                                withAnimation {
                                    currentStep += 1
                                }
                            }) {
                                Text("Continue")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(red: (85/255), green: (5/255), blue: (200/255)))
                                    .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToMainApp) {
                ContentView()
                    .environmentObject(detectionState)
                    .environmentObject(onboardingState)
            }

            .alert("Terms of Service", isPresented: $showTermsAlert) {
                Button("OK") { }
            } message: {
                Text("BatSight is designed to assist visually impaired users. While we strive for accuracy, please use your own judgment and other resources for safety. We do not store personal data or images.")
            }
            .alert("Permissions", isPresented: $showPermissionsAlert) {
                Button("OK") { }
            } message: {
                Text("BatSight requires camera access for object detection and text reading. Microphone access is needed for voice input. All processing is done locally on your device for privacy.")
            }
        }
    }
    

    
    private var signInStep: some View {
        VStack(spacing: 40) {
            VStack(spacing: 24) {
                Text("Continue with")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        selectedSignInMethod = "Google"
                        withAnimation {
                            currentStep += 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.title2)
                            Text("Continue with Google")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: (85/255), green: (5/255), blue: (200/255)))
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        selectedSignInMethod = "Apple"
                        withAnimation {
                            currentStep += 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.title2)
                            Text("Continue with Apple")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: (85/255), green: (5/255), blue: (200/255)))
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            detectionState.announceCustomMessage("Please choose your sign-in method. Tap Continue with Google or Continue with Apple.")
        }
    }
    
    private var voiceInputStep: some View {
        VStack(spacing: 40) {
            VStack(spacing: 24) {
                Text("What's your name?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        // Stop any current speech before starting recognition
                        detectionState.stopSpeech()
                        startSpeechRecognition()
                    }) {
                        HStack {
                            Image(systemName: isListening ? "waveform" : "mic.fill")
                                .font(.title2)
                            Text(isListening ? "Listening..." : "Tap to speak")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isListening ? Color.green : Color(red: (85/255), green: (5/255), blue: (200/255)))
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isListening)
                    
                                            if speechRecognitionAttempts > 0 && speechRecognitionAttempts < 3 {
                            Button("Try again") {
                                HapticManager.shared.lightImpact()
                                // Stop any current speech before starting recognition
                                detectionState.stopSpeech()
                                startSpeechRecognition()
                            }
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16, weight: .medium))
                    }
                    
                    // Show green continue button if name is detected
                    if !username.isEmpty && !isListening {
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            nameFromVoice = true
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            Text("Continue")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.green)
                                .cornerRadius(16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // After 3 attempts, show message to try again later
                    if speechRecognitionAttempts >= 3 {
                        VStack(spacing: 16) {
                            Text("Voice recognition is having trouble. Please try again later.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Text("We'll use this to personalize your experience")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            announceVoiceGuidance()
        }
    }
    
    private var nameVerificationStep: some View {
        VStack(spacing: 40) {
            VStack(spacing: 24) {
                Text("Verify Your Name")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    Text("Is this correct?")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text(username.isEmpty ? "No name entered" : username)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            nameVerified = true
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            Text("Yes, that's correct")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            // Go back to voice input step
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("No, try again")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .onAppear {
            if nameFromVoice {
                detectionState.announceCustomMessage("I heard \(username.isEmpty ? "no name" : username). Is that correct? Tap yes if correct, or no to try again.")
            } else {
                detectionState.announceCustomMessage("Please verify your typed name. Is \(username.isEmpty ? "no name" : username) correct? Tap yes if correct, or no to try again.")
            }
        }
    }
    
    private var appOverviewStep: some View {
        VStack(spacing: 40) {
            VStack(spacing: 24) {
                Text("About BatSight")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    // Circle with app summary
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 200, height: 200)
                        
                        VStack(spacing: 12) {
                                   Image(systemName: "eye.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white)
                            
                            Text("Dual-Mode Interface")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Text("Object Detection Mode")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Real-time detection with direction and distance estimation using Vision framework and YOLOv8. Provides spoken feedback and intelligent location inference.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        Text("Text Reader Mode")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("OCR capabilities using Vision framework with intelligent filtering and autocorrect. Reads printed or displayed text aloud.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
            }
        }
        .onAppear {
            // Load username from UserDefaults if not already set
            if username.isEmpty {
                username = UserDefaults.standard.string(forKey: "userName") ?? ""
            }
            let welcomeMessage = nameVerified ? "Welcome to BatSight \(username). This app helps visually impaired users navigate their environment using computer vision. Tap Get Started to begin using the app." : "Welcome to BatSight. This app helps visually impaired users navigate their environment using computer vision. Tap Get Started to begin using the app."
            detectionState.announceCustomMessage(welcomeMessage)
        }
        .onDisappear {
            // Clean up speech recognition when view disappears
            cleanupSpeechRecognition()
        }
    }
    
    private func startSpeechRecognition() {
        print("Starting speech recognition...")
        
        // Check if speech recognition is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available or not ready")
            detectionState.announceCustomMessage("Speech recognition not available. Please try again later.")
            return
        }
        
        print("Speech recognizer is available and ready")
        
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            print("Speech recognition authorization status: \(authStatus.rawValue)")
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized, starting recording...")
                    self.beginRecording()
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                    self.detectionState.announceCustomMessage("Speech recognition permission denied. Please try again later.")
                @unknown default:
                    print("Speech recognition authorization unknown")
                    self.detectionState.announceCustomMessage("Speech recognition not available. Please try again later.")
                }
            }
        }
    }
    
    private func beginRecording() {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Reset speech detection flag
        speechDetected = false
        
        // Configure audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            DispatchQueue.main.async {
                self.detectionState.announceCustomMessage("Audio setup failed. Please try again later.")
            }
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { 
            DispatchQueue.main.async {
                self.detectionState.announceCustomMessage("Speech recognition failed to initialize. Please try again later.")
            }
            return 
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let error = error {
                print("Speech recognition error: \(error)")
            }
            
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                print("Speech recognition result: '\(recognizedText)' (final: \(result.isFinal))")
                DispatchQueue.main.async {
                    // Only update username if we have non-empty text
                    if !recognizedText.isEmpty {
                        self.username = recognizedText
                        self.speechDetected = true
                    }
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                print("Speech recognition completed - final: \(isFinal), error: \(error?.localizedDescription ?? "none")")
                // Clean up audio engine
                DispatchQueue.global(qos: .userInitiated).async {
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    
                    DispatchQueue.main.async {
                        self.recognitionRequest = nil
                        self.recognitionTask = nil
                        self.isListening = false
                        
                        // Don't auto-advance, let user manually continue
                        print("Final processing - username: '\(self.username)', speechDetected: \(self.speechDetected)")
                        if !self.username.isEmpty {
                            self.nameFromVoice = true
                            self.detectionState.announceCustomMessage("Click continue to verify.")
                        } else {
                            self.speechRecognitionAttempts += 1
                            if self.speechRecognitionAttempts >= 3 {
                                self.detectionState.announceCustomMessage("Voice recognition failed after 3 attempts. Please try again later.")
                            } else {
                                self.detectionState.announceCustomMessage("I didn't catch that. Please try again.")
                            }
                        }
                    }
                }
            }
        }
        
        // Add a shorter timeout to stop listening when speech is detected
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.isListening && self.speechDetected && !self.username.isEmpty {
                // If we have detected speech and have a name, stop listening after 2 seconds
                self.recognitionTask?.cancel()
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isListening = false
                
                self.nameFromVoice = true
                self.detectionState.announceCustomMessage("Click continue to verify.")
            }
        }
        
        // Add a timeout to stop listening after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.isListening {
                self.recognitionTask?.cancel()
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isListening = false
                
                // If speech was detected, stop listening but don't auto-advance
                if self.speechDetected && !self.username.isEmpty {
                    self.nameFromVoice = true
                    self.detectionState.announceCustomMessage("Click continue to verify.")
                } else if !self.speechDetected {
                    // Only show timeout message if no speech was detected
                    self.username = ""
                    self.speechRecognitionAttempts += 1
                    if self.speechRecognitionAttempts >= 3 {
                        self.detectionState.announceCustomMessage("Voice recognition failed after 3 attempts. Please try again later.")
                    } else {
                        self.detectionState.announceCustomMessage("I didn't hear anything. Please try again.")
                    }
                }
            }
        }
        
        // Wait a moment for audio session to be properly configured
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Configure audio input
            let inputNode = self.audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            print("Audio input node format: \(recordingFormat)")
            
                        // Validate the audio format
            guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
                print("Invalid audio format - sampleRate: \(recordingFormat.sampleRate), channelCount: \(recordingFormat.channelCount)")
                DispatchQueue.main.async {
                    self.detectionState.announceCustomMessage("Audio format error. Please try again later.")
                }
                return
            }
            
            // Remove any existing tap first
            inputNode.removeTap(onBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            print("Audio tap installed successfully")
            
            // Start audio engine
            self.audioEngine.prepare()
            do {
                try self.audioEngine.start()
                print("Audio engine started successfully")
                DispatchQueue.main.async {
                    self.isListening = true
                    // Don't announce "Listening" - it interferes with speech recognition
                }
            } catch {
                print("Audio engine failed to start: \(error)")
                DispatchQueue.main.async {
                    self.detectionState.announceCustomMessage("Audio recording failed. Please try again later.")
                }
            }
        }
    }
    
    private func completeOnboarding() {
        // Save username
        UserDefaults.standard.set(username, forKey: "userName")
        
        // Provide haptic feedback
        HapticManager.shared.notificationFeedback(type: .success)
        
        // Announce completion
        detectionState.announceCustomMessage("Welcome to BatSight \(username). Your visual assistant is ready. Click the bottom of the screen for help using the app. Disclaimer: Don't trust Bat Sight completely as AI can make mistakes and it is essential to use your own judgment and other resources for safety.")
        
        // Complete onboarding using the state object
        onboardingState.completeOnboarding()
        
        // Navigate to main app
        navigateToMainApp = true
    }
    
    private func cleanupSpeechRecognition() {
        // Cancel any ongoing recognition
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Reset state
        isListening = false
        recognitionRequest = nil
        
        // Reset attempts
        speechRecognitionAttempts = 0
    }
    
    private func announceVoiceGuidance() {
        detectionState.announceCustomMessage("Please speak your name. Tap the microphone button to start recording.")
    }
}

#Preview {
    OnboardingView()
        .environmentObject(DetectionState())
        .environmentObject(OnboardingState())
} 
