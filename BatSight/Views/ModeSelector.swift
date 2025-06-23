//
//  ModeSelector.swift
//  BatSight
//
//  Created by Arnav Nair on 6/20/25.
//

import Foundation
import SwiftUI

struct ModeSelector: View {
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    NavigationLink {
                        ContentView()
                    } label: {
                        Image("Bat Sight")
                            .resizable()
                            .frame(width: 75, height: 75)
                    }
                }
            }
            .frame(maxWidth: .infinity , maxHeight: .infinity)
            .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ModeSelector()
}
