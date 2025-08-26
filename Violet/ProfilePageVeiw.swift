//
//  ProfilePageVeiw.swift
//  Violet
//
//  Created by Mihail Gjoni on 6/30/25.
//

import SwiftUI
import FirebaseAuth

struct ProfilePageVeiw: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authVM = AuthenticationView()
    @State private var showSettings = false
    @State private var showSignOutAlert = false
    @Binding var isLoggedIn: Bool  // Add this binding to control login state
    
    // Get current user info
    private var currentUser: User? {
        Auth.auth().currentUser
    }
    
    private var userName: String {
        currentUser?.displayName ?? "User"
    }
    
    private var userEmail: String {
        currentUser?.email ?? "No email"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile image
            Image(systemName: "person.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.CC)
            
            // User info
            VStack(spacing: 10) {
                Text(userName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(userEmail)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Profile options
            VStack(spacing: 15) {
                // Settings button
                Button(action: {
                    showSettings = true
                }) {
                    ProfileRowView(icon: "gear", title: "Settings")
                }
                
                // Help & Support button
                Button(action: {
                    // Add help & support action here
                }) {
                    ProfileRowView(icon: "questionmark.circle", title: "Help & Support")
                }
                
                // Sign Out button
                Button(action: {
                    showSignOutAlert = true
                }) {
                    ProfileRowView(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out")
                }
            }
            .padding(.top, 30)
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [.CC, .CBW]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private func signOut() {
        Task {
            do {
                try await authVM.logout()
                // Dismiss all presented views and navigate to login
                await MainActor.run {
                    // Dismiss the profile page immediately
                    dismiss()
                    // Set logged out state immediately - no delay needed
                    isLoggedIn = false
                }
            } catch {
                print("Error signing out: \(error.localizedDescription)")
                // Even if logout fails, still navigate to login for safety
                await MainActor.run {
                    dismiss()
                    isLoggedIn = false
                }
            }
        }
    }
}

struct ProfileRowView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ProfilePageVeiw(isLoggedIn: .constant(true))
}
