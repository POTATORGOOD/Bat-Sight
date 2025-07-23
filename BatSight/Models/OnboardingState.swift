//
//  OnboardingState.swift
//  BatSight
//
//  Created by Arnav Nair on 6/16/25.
//

import Foundation
import SwiftUI

class OnboardingState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "userName")
    }
} 