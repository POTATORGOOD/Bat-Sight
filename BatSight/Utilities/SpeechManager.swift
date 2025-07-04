//
//  SpeechManager.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import AVFoundation

// Text-to-speech engine that handles all audio announcements with cooldown management and speech configuration
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
    
    // Configures the iOS audio system for optimal speech playback
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // Checks if enough time has passed since the last speech to prevent overlapping announcements
    private func canSpeakNow() -> Bool {
        let timeSinceLastSpeech = Date().timeIntervalSince(lastSpeechTime)
        return timeSinceLastSpeech >= speechCooldown
    }
    
    // Announces a single detected object with its position and confidence level
    func announceObject(_ objectName: String, position: String, confidence: Float, distance: Float? = nil, distanceCategory: String? = nil) {
        // Check if we can speak now
        guard canSpeakNow() else {
            print("Speech blocked - cooldown active")
            return
        }
        
        // Stop any current speech
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Create the announcement text (with distance if available)
        var announcement = "\(objectName) detected \(position)"
        if let category = distanceCategory, let dist = distance {
            announcement += ", \(category), \(String(format: "%.1f", dist)) meters"
        } else if let category = distanceCategory {
            announcement += ", \(category)"
        } else if let dist = distance {
            announcement += ", \(String(format: "%.1f", dist)) meters"
        }
        
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
    
    // Announces when no objects are detected in the camera view
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
    
    // Announces a simple direction update for navigation purposes
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
    
    // Stops any currently playing speech immediately
    func stopSpeaking() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    // Checks if the synthesizer is currently speaking
    var isCurrentlySpeaking: Bool {
        return isSpeaking
    }
    
    // Announces multiple detected objects in a summary format
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
    
    // Announces camera mode activation (bypasses cooldown for immediate feedback)
    func announceCameraModeActivated() {
        // Bypass cooldown for mode announcements - always speak immediately
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let announcement = "Object Detection Activated"
        
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
    
    // Announces camera mode deactivation (bypasses cooldown for immediate feedback)
    func announceCameraModeDeactivated() {
        // Bypass cooldown for mode announcements - always speak immediately
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let announcement = "Object Detection Deactivated"
        
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
    
    // Announces when voice is muted (bypasses cooldown for immediate feedback)
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
    
    // Announces when voice is unmuted (bypasses cooldown for immediate feedback)
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

// Monitors speech synthesis state and updates internal flags when speech starts, finishes, or is cancelled
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
