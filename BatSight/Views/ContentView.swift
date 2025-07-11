//
//  ContentView.swift
//  BatSight
//
//  Created by Arnav Nair on 6/16/25.
//

import SwiftUI

// Main menu screen with the Bat Sight logo that navigates to camera mode when tapped
struct ContentView: View {
    @EnvironmentObject var detectionState: DetectionState
    @State private var navigateToCamera = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {
                    // Provide haptic feedback
                    HapticManager.shared.lightImpact()
                    // Trigger navigation
                    navigateToCamera = true
                }) {
                    Image("Bat Sight")
                        .resizable()
                        .frame(width: 300, height: 300)
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
            .navigationDestination(isPresented: $navigateToCamera) {
                CameraFrame()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ContentView()
        .environmentObject(DetectionState())
}
