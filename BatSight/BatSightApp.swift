//
//  BatSightApp.swift
//  BatSight
//
//  Created by Arnav Nair on 6/16/25.
//

import SwiftUI

// Main app entry point that creates the shared detection state and sets up the root view
@main
struct BatSightApp: App {
    @StateObject private var detectionState = DetectionState()
    @StateObject private var onboardingState = OnboardingState()
    
    var body: some Scene {
        WindowGroup {
            StartView()
                .environmentObject(detectionState)
                .environmentObject(onboardingState)
        }
    }
}

// Notification for onboarding completion
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
