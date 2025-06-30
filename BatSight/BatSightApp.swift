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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(detectionState)
        }
    }
}
