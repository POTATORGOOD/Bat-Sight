//
//  SplashView.swift
//  BatSight
//
//  Created by Arnav Nair on 6/16/25.
//

import SwiftUI

struct StartView: View {
    @State private var logoOffset: CGFloat = 0
    @State private var showWelcomeText = false
    @State private var showSubtitle = false
    @State private var showButtons = false
    @State private var navigateToOnboarding = false
    @State private var navigateToMainApp = false
    @State private var username: String = ""
    @EnvironmentObject var detectionState: DetectionState
    @EnvironmentObject var onboardingState: OnboardingState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !showButtons {
                    // Initial state: Just logo in center
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            ZStack(alignment: .topTrailing) {
                                Image("Bat Sight")
                                    .resizable()
                                    .frame(width: 200, height: 200)
                                
                                Text("BETA")
                                    .font(.system(size: 5, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.7))
                                    .clipShape(Capsule())
                                    .offset(x: -28, y: 140)
                            }
                            
                            Text("Tap to begin")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.shared.lightImpact()
                        startAnimation()
                    }
                } else {
                    // After logo is clicked: Animation sequence
                    VStack(spacing: 20) {
                        Image("Bat Sight")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .offset(y: logoOffset)
                            .padding(.top, 60)
                        
                        if showWelcomeText {
                            Text("Welcome to BatSight \(onboardingState.hasCompletedOnboarding ? username : "")")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        if showSubtitle {
                            Text("Empowering your senses")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOnboarding) {
                OnboardingView()
                    .environmentObject(detectionState)
                    .environmentObject(onboardingState)
                    .transition(.opacity)
            }
            .navigationDestination(isPresented: $navigateToMainApp) {
                ContentView()
                    .environmentObject(detectionState)
                    .environmentObject(onboardingState)
                    .transition(.opacity)
            }
            .onAppear {
                // Load username from UserDefaults
                username = UserDefaults.standard.string(forKey: "userName") ?? ""
                
                // Announce welcome message at the start
                if onboardingState.hasCompletedOnboarding && !username.isEmpty {
                    detectionState.announceCustomMessage("Welcome to BatSight \(username). Your visual assistant is ready to help you navigate the world.")
                } else {
                    detectionState.announceCustomMessage("Welcome to BatSight. Your visual assistant is ready to help you navigate the world.")
                }
            }
        }
    }
    
    private func startAnimation() {
        // Show the animation sequence
        withAnimation(.easeInOut(duration: 0.5)) {
            showButtons = true
        }
        
        // Animate logo flying to top and shrinking
        withAnimation(.easeInOut(duration: 1.0)) {
            logoOffset = -80
        }
        
        // Show welcome text after logo animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showWelcomeText = true
            }
        }
        
        // Show subtitle after welcome text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showSubtitle = true
            }
        }
        
        // Animation sequence complete - navigate to appropriate view
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeInOut(duration: 0.8)) {
                if onboardingState.hasCompletedOnboarding {
                    navigateToMainApp = true
                } else {
                    navigateToOnboarding = true
                }
            }
        }
    }
}

#Preview {
    StartView()
        .environmentObject(DetectionState())
        .environmentObject(OnboardingState())
} 
