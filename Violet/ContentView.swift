//
//  ContentView.swift
//  Violet
//
//  Created by Mihail Gjoni on 6/30/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false // depending if you login will effect the first view
    
    var body: some View {
        NavigationStack {
            if isLoggedIn {
                MainChatHome( isLoggedIn: $isLoggedIn) //  main app view
                    .onAppear {
                        print(" Successfully to MainChatHome")
                    }
            } else {
                LoginView(isLoggedIn: $isLoggedIn) // Pass binding to LoginView
            }
        }
    }
}

#Preview {
    ContentView()
}
