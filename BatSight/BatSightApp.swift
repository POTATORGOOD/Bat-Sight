//
//  BatSightApp.swift
//  BatSight
//
//  Created by Arnav Nair on 6/16/25.
//

import SwiftUI

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
