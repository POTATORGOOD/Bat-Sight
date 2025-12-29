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
    @EnvironmentObject var onboardingState: OnboardingState
    @State private var navigateToCamera = false
    @State private var navigateToTextReader = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack(alignment: .topTrailing) {
                    Image("Bat Sight")
                        .resizable()
                        .frame(width: 200, height: 200)
                        .padding(.top, -20)
                        .padding(.bottom, -50)
                    
                    Text("BETA")
                        .font(.system(size: 5, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.7))
                        .clipShape(Capsule())
                        .offset(x: -25, y: 120)
                }
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
                .padding(.horizontal, 20)
               Spacer()
                Button(action: {
                    // Provide haptic feedback
                    HapticManager.shared.lightImpact()
                    // Announce help information
                    detectionState.announceCustomMessage("Bat Sight has two modes to help visually impaired users navigate their environment. You are on the mode selector main screen. Tap the left button to enter text reading mode. To read text out loud point your camera at the selected text. Then click the button on the bottom of the screen. Tap the right button to enter object detection mode to identify objects around you. In this mode the app will automatically detect objects wherever the camera is facing. In object detection mode, you can use the Where Am I button on the bottom of the screen to analyze your environment. When entering either mode you can mute or unmute the voice by pressing the top right button. Also you can go back to the mode selector screen by pressing the top left button. All buttons provide haptic feedback so you know if a button is being pressed. Disclaimer: Don't trust Bat Sight completely as AI can make mistakes and it is essential to use your own judgment and other resources for safety.")
                }) {
                    Text("Help")
                        .font(.custom("times", size: 50))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity , maxHeight: 150)
                        .background(Color(red: (120/255), green: (50/255), blue: (255/255)))
                        .clipShape(Capsule())
                }
                .onLongPressGesture {
                    showingResetAlert = true
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: (30/255), green: (0/255), blue: (80/255)))
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
            .navigationDestination(isPresented: $navigateToCamera) {
                ObjectDetectionFrame()
            }
            .navigationDestination(isPresented: $navigateToTextReader) {
                TextReaderFrame()
            }
            .alert("Reset Onboarding", isPresented: $showingResetAlert) {
                Button("Reset") {
                    onboardingState.resetOnboarding()
                    // Restart app to show onboarding
                    exit(0)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset the onboarding process. The app will restart.")
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Announce mode selector activation
            detectionState.announceCustomMessage("Mode selector activated. Tap the left button for text reading mode or the right button for object detection mode. There is also a help button at the bottom of the screen.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DetectionState())
        .environmentObject(OnboardingState())
}
