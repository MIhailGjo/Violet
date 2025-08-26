//
//  SettingsView.swift
//  Violet
//
//  Created by Mihail Gjoni on 7/16/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var soundEnabled = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Settings list
                List {
                    // Account section
                    Section("Account") {
                        SettingsRowView(icon: "person.circle", title: "Edit Profile", hasChevron: true) {
                            // Add edit profile action
                        }
                        
                        SettingsRowView(icon: "key", title: "Change Password", hasChevron: true) {
                            // Add change password action
                        }
                        
                        SettingsRowView(icon: "shield", title: "Privacy & Security", hasChevron: true) {
                            // Add privacy settings action
                        }
                    }
                    
                    // App Preferences section
                    Section("App Preferences") {
                        HStack {
                            Image(systemName: "bell.circle")
                                .foregroundColor(.CC)
                                .frame(width: 25)
                            Text("Notifications")
                            Spacer()
                            Toggle("", isOn: $notificationsEnabled)
                                .tint(.CC)
                        }
                        
                        HStack {
                            Image(systemName: "moon.circle")
                                .foregroundColor(.CC)
                                .frame(width: 25)
                            Text("Dark Mode")
                            Spacer()
                            Toggle("", isOn: $darkModeEnabled)
                                .tint(.CC)
                        }
                        
                        HStack {
                            Image(systemName: "speaker.wave.2.circle")
                                .foregroundColor(.CC)
                                .frame(width: 25)
                            Text("Sound Effects")
                            Spacer()
                            Toggle("", isOn: $soundEnabled)
                                .tint(.CC)
                        }
                    }
                    
                    // About section
                    Section("About") {
                        SettingsRowView(icon: "info.circle", title: "App Version", subtitle: "1.0.0", hasChevron: false) {
                            // No action for version
                        }
                        
                        SettingsRowView(icon: "doc.text", title: "Terms of Service", hasChevron: true) {
                            // Add terms of service action
                        }
                        
                        SettingsRowView(icon: "hand.raised", title: "Privacy Policy", hasChevron: true) {
                            // Add privacy policy action
                        }
                    }
                    
                    // Danger zone
                    Section("Danger Zone") {
                        SettingsRowView(icon: "trash.circle", title: "Delete Account", hasChevron: true, isDestructive: true) {
                            // Add delete account action
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [.CC.opacity(0.1), .CBW.opacity(0.1)]),
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.CC)
                }
            }
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let hasChevron: Bool
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, hasChevron: Bool = true, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.hasChevron = hasChevron
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : .CC)
                    .frame(width: 25)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(isDestructive ? .red : .primary)
                        .font(.body)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
}
