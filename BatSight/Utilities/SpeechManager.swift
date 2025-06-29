//
//  SpeechManager.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import AVFoundation

class SpeechManager: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var isSpeaking = false
    
    // Speech configuration
    private let speechRate: Float = 0.5 // Slower rate for clarity
    private let speechPitch: Float = 1.0
    private let speechVolume: Float = 0.8
    
    // Cooldown mechanism to prevent speech overlap
    private var lastSpeechTime: Date = Date.distantPast
    private let speechCooldown: TimeInterval = 2.0 // 2 seconds between announcements
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    /// Sets up the audio session for speech output
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Checks if enough time has passed since the last speech
    private func canSpeakNow() -> Bool {
        let timeSinceLastSpeech = Date().timeIntervalSince(lastSpeechTime)
        return timeSinceLastSpeech >= speechCooldown
    }
    
    /// Announces a detected object with its position
    /// - Parameters:
    ///   - objectName: The name of the detected object
    ///   - position: The position of the object ("Left", "Center", "Right")
    ///   - confidence: The confidence level of the detection (0.0 to 1.0)
    func announceObject(_ objectName: String, position: String, confidence: Float) {
        // Check if we can speak now
        guard canSpeakNow() else {
            print("Speech blocked - cooldown active")
            return
        }
        
        // Stop any current speech
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Create the announcement text (without distance)
        let announcement = "\(objectName) detected \(position)"
        
        // Create and configure the speech utterance
        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Speak the announcement
        synthesizer.speak(utterance)
        isSpeaking = true
        lastSpeechTime = Date()
        
        print("Speech: \(announcement)")
    }
    
    /// Announces when no objects are detected
    func announceNoObjects() {
        // Check if we can speak now
        guard canSpeakNow() else {
            print("Speech blocked - cooldown active")
            return
        }
        
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: "No objects detected")
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
        isSpeaking = true
        lastSpeechTime = Date()
        
        print("Speech: No objects detected")
    }
    
    /// Announces a simple direction update
    /// - Parameter position: The position to announce
    func announcePosition(_ position: String) {
        // Check if we can speak now
        guard canSpeakNow() else {
            print("Speech blocked - cooldown active")
            return
        }
        
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: position)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
        isSpeaking = true
        lastSpeechTime = Date()
        
        print("Speech: \(position)")
    }
    
    /// Stops any current speech
    func stopSpeaking() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    /// Checks if the synthesizer is currently speaking
    var isCurrentlySpeaking: Bool {
        return isSpeaking
    }
    
    /// Announces multiple detected objects
    /// - Parameter objects: Array of detected objects to announce
    func announceMultipleObjects(_ objects: [DetectedObject]) {
        if objects.isEmpty {
            announceNoObjects()
            return
        }
        
        // Check if we can speak now
        guard canSpeakNow() else {
            print("Speech blocked - cooldown active")
            return
        }
        
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Create a summary of all detected objects (without distance)
        let objectDescriptions = objects.map { object in
            return "\(object.identifier) \(object.position)"
        }
        
        let announcement = "Detected: " + objectDescriptions.joined(separator: ". ")
        
        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
        isSpeaking = true
        lastSpeechTime = Date()
        
        print("Speech: \(announcement)")
    }
    
    /// Announces camera mode activation
    func announceCameraModeActivated() {
        // Bypass cooldown for mode announcements - always speak immediately
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let announcement = "Camera Mode Activated"
        
        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
        isSpeaking = true
        lastSpeechTime = Date()
        
        print("Speech: \(announcement)")
    }
    
    /// Announces camera mode deactivation
    func announceCameraModeDeactivated() {
        // Bypass cooldown for mode announcements - always speak immediately
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let announcement = "Camera Mode Deactivated"
        
        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
        isSpeaking = true
        lastSpeechTime = Date()
        
        print("Speech: \(announcement)")
    }
    
    /// Announces voice muted
    func announceVoiceMuted() {
        // Bypass cooldown for mute announcements - always speak immediately
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let announcement = "Voice muted"
        
        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
        isSpeaking = true
        lastSpeechTime = Date()
        
        print("Speech: \(announcement)")
    }
    
    /// Announces voice unmuted
    func announceVoiceUnmuted() {
        // Bypass cooldown for mute announcements - always speak immediately
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let announcement = "Voice unmuted"
        
        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
        isSpeaking = true
        lastSpeechTime = Date()
        
        print("Speech: \(announcement)")
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        print("Speech finished: \(utterance.speechString)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        print("Speech cancelled: \(utterance.speechString)")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Speech started: \(utterance.speechString)")
    }
}
