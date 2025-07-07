//
//  ModeSelector.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import SwiftUI

struct ModeSelector: View {
    @State private var navigateToMain = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
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
                }
            }
            .frame(maxWidth: .infinity , maxHeight: .infinity)
            .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
            .navigationDestination(isPresented: $navigateToMain) {
                ContentView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ModeSelector()
}
