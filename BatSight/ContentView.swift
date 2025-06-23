//
//  ContentView.swift
//  BatSight
//
//  Created by Arnav Nair on 6/16/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image("Bat Sight")
                .resizable()
                .frame(width: 300, height: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: (45/255), green: (5/255), blue: (102/255)))
        .padding()
    }
}

#Preview {
    ContentView()
}
