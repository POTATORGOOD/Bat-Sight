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
    @State private var navigateToTextReader = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Image("Bat Sight")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .padding(.top, -20)
                Spacer()
                HStack(spacing: 25) {
                    Button(action: {
                        // Provide haptic feedback
                        HapticManager.shared.lightImpact()
                        // Trigger navigation to text reader
                        navigateToTextReader = true
                    }) {
                        Image(systemName: "doc.circle.fill")
                            .resizable()
                            .frame(width: 185, height: 185)
                            .foregroundStyle(Color(red: (241/255), green: (246/255), blue: (255/255)))
                    }
                    Button(action: {
                        // Provide haptic feedback
                        HapticManager.shared.lightImpact()
                        // Trigger navigation to camera
                        navigateToCamera = true
                    }) {
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .foregroundStyle(Color(red: (241/255), green: (246/255), blue: (255/255)))
                            .frame(width: 185, height: 185)
                    }
                }
                .padding(.top, -150)
               Spacer()
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
            .navigationDestination(isPresented: $navigateToCamera) {
                ObjectDetectionFrame()
            }
            .navigationDestination(isPresented: $navigateToTextReader) {
                TextReaderFrame()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ContentView()
        .environmentObject(DetectionState())
}
