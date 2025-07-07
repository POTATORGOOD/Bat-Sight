//
//  HapticManager.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import UIKit

// Manages haptic feedback for user interactions
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // Provides light haptic feedback for button presses
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // Provides medium haptic feedback for important actions
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // Provides heavy haptic feedback for significant events
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // Provides notification feedback
    func notificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
}
