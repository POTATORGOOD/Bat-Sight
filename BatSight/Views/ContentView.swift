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
                    .padding(.bottom, -50)
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
               Spacer()
                Button(action: {
                    // Provide haptic feedback
                    HapticManager.shared.lightImpact()
                    // Announce help information
                    detectionState.announceCustomMessage("Bat Sight has two modes to help visually impaired users navigate their environment. You are on the mode selector main screen. Tap the left button to enter text reading mode. To read text out loud point your camera at the selected text. Then click the button on the bottom of the screen. Tap the right button to enter object detection mode to identify objects around you. In this mode the app will automatically detect objects wherever the camera is facing. In object detection mode, you can use the Where Am I button on the bottom of the screen to analyze your environment. When entering either mode you can mute or unmute the voice by pressing the top right button. Also you can go back to the mode selector screen by pressing the top left button. All buttons provide haptic feedback so you know if a button is being pressed. Disclaimer: Don't trust Bat Sight completely as AI can make mistakes and it is essential to use your own judgment and other resources for safety.")
                }) {
                    Text("Help")
                        .font(.custom("times", size: 50))
                        .foregroundStyle(Color(red: (241/255), green: (246/255), blue: (255/255)))
                        .frame(maxWidth: .infinity , maxHeight: 150)
                        .background(Color(red: (85/255), green: (5/255), blue: (200/255)))
                        .opacity(0.8)
                        .clipShape(Capsule())
                }
                .padding(.bottom, -200)
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
