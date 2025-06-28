//
//  CameraFrame.swift
//  BatSight
//
//  Created by Arnav Nair on 6/23/25.
//

import Foundation
import SwiftUI
import AVFoundation

struct CameraFrame: View {
    @EnvironmentObject var detectionState: DetectionState
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack (alignment:.center){
                    NavigationLink {
                        ContentView()
                    } label: {
                        Image("Bat Sight")
                            .resizable()
                            .frame(width: 75, height: 75)
                    }
                    Spacer()
                    
                    VStack {
                        
                        Text(detectionState.currentDetectionText)
                            .font(.custom("times", size: 30))
                            .foregroundStyle(Color(red: (241/255), green: (246/255), blue: (255/255)))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    Spacer()
                    
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
                
                
            }
        .frame(maxWidth: .infinity , maxHeight: .infinity)
    }
    .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    CameraFrame()
        .environmentObject(DetectionState())
}
