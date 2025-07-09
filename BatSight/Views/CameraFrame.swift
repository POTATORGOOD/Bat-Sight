//
//  CameraFrame.swift
//  BatSight
//
//  Created by Arnav Nair on 6/23/25.
//

import Foundation
import SwiftUI
import AVFoundation

// Camera interface wrapper that provides navigation controls, detection display, and speech toggle with audio feedback
struct CameraFrame: View {
    @EnvironmentObject var detectionState: DetectionState
    @State private var navigateToMain = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack (alignment:.center){
                    Button(action: {
                        // Provide haptic feedback
                        HapticManager.shared.lightImpact()
                        // Trigger navigation
                        navigateToMain = true
                    }) {
                        Image("Bat Sight")
                            .resizable()
                            .frame(width: 75, height: 75)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                    
                    VStack {
                        Text(detectionState.currentDetectionText)
                            .font(.custom("times", size: 30))
                            .foregroundStyle(Color(red: (241/255), green: (246/255), blue: (255/255)))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                    
                    // Speech toggle button
                    Button(action: {
                        // Provide haptic feedback
                        HapticManager.shared.lightImpact()
                        
                        detectionState.toggleSpeech()
                    }) {
                        Image(systemName: detectionState.speechEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundColor(detectionState.speechEnabled ? .green : .red)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 10)
                }
                .frame(maxWidth: .infinity , maxHeight: 75)
                .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
                .padding(.bottom, -10)
                ZStack {
                    // Background
                    Color(red: (45/255), green: (5/255), blue: (102/255))
                        .ignoresSafeArea()
                    
                    // Camera view with frame
                    VStack {
                        CameraView(detectionState: detectionState)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                    }
                    .padding()
                }
                
                Button(action: {
                    // Provide haptic feedback
                    HapticManager.shared.mediumImpact()
                    
                    // Trigger manual object detection scan
                    detectionState.performManualScan()
                }) {
                    Text("Where Am I?")
                        .font(.custom("times", size: 50))
                        .foregroundStyle(Color(red: (241/255), green: (246/255), blue: (255/255)))
                        .frame(maxWidth: .infinity , maxHeight: 75)
                        .background(Color(red: (85/255), green: (5/255), blue: (200/255)))
                        .opacity(0.8)
                        .clipShape(Capsule())
                }
                .padding(.leading, 30)
                .padding(.trailing, 30)
                Spacer()
            }
        .frame(maxWidth: .infinity , maxHeight: .infinity)
        .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
        .navigationDestination(isPresented: $navigateToMain) {
            ContentView()
        }
    }
    .navigationBarBackButtonHidden(true)
    .onAppear {
        // Announce camera mode activation (always announce navigation events)
        detectionState.announceCameraModeActivated()
    }
    .onDisappear {
        // Announce camera mode deactivation (always announce navigation events)
        detectionState.announceCameraModeDeactivated()
    }
    }
}

#Preview {
    CameraFrame()
        .environmentObject(DetectionState())
}
