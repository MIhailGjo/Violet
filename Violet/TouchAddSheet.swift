//
//  CustomTouchLaterAddSheet.swift
//  Violet
//
//  Created by Mihail Gjoni on 8/17/25.
//

import SwiftUI

struct CustomTouchLaterAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String) -> Void
    
    @State private var thoughtText = ""
    @State private var showingSuccessAnimation = false
    @State private var selectedTemplate: TouchLaterTemplate?
    @FocusState private var isTextFocused: Bool
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(gradient: Gradient(colors: [.CC, .CBW]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                CustomTouchLaterHeader(
                    onCancel: {
                        dismiss()
                    },
                    onSave: {
                        saveThought()
                    },
                    canSave: !thoughtText.trimmingCharacters(in: .whitespaces).isEmpty
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Main inspiration section
                        InspirationSection()
                        
                        // Text input area
                        ThoughtInputSection(
                            text: $thoughtText,
                            isTextFocused: $isTextFocused
                        )
                        
                        // Quick templates
                        QuickTemplatesSection(
                            selectedTemplate: $selectedTemplate,
                            onTemplateSelect: { template in
                                applyTemplate(template)
                            }
                        )
                        
                        // Tips section
                        TipsSection()
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            
            // Success Animation
            if showingSuccessAnimation {
                TouchLaterSuccessAnimation()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Focus on text input after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isTextFocused = true
            }
        }
    }
    
    private func saveThought() {
        let finalText = thoughtText.trimmingCharacters(in: .whitespaces)
        print("💭 Saving Touch Later thought: '\(finalText)'")
        
        onSave(finalText)
        
        // Show success animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSuccessAnimation = true
        }
        
        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func applyTemplate(_ template: TouchLaterTemplate) {
        thoughtText = template.text
        selectedTemplate = template
        
        // Animate template selection
        withAnimation(.easeInOut(duration: 0.2)) {
            // Template selection visual feedback handled in view
        }
    }
}

// MARK: - Custom Header
struct CustomTouchLaterHeader: View {
    let onCancel: () -> Void
    let onSave: () -> Void
    let canSave: Bool
    
    var body: some View {
        HStack {
            // Cancel Button
            Button(action: onCancel) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.body)
                    Text("Cancel")
                        .font(.body)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Title with icon
            HStack(spacing: 8) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Touch Later")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Save Button
            Button(action: onSave) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.body)
                    Text("Save")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(canSave ? .white : .white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(canSave ? Color.CC.opacity(0.8) : Color.white.opacity(0.2))
                .cornerRadius(20)
                .scaleEffect(canSave ? 1.0 : 0.95)
                .animation(.easeInOut(duration: 0.2), value: canSave)
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
}

// MARK: - Inspiration Section
struct InspirationSection: View {
    @State private var currentQuote = 0
    
    private let inspirationQuotes = [
        "💭 What's on your mind?",
        "✨ Capture any thought, organize it later",
        "🧠 Don't let good ideas slip away",
        "🎯 Quick thoughts, smart organization"
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            Text(inspirationQuotes[currentQuote])
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.8), value: currentQuote)
            
            Text("Don't worry about being perfect - just capture the thought!")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .onAppear {
            // Cycle through inspiration quotes
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation {
                    currentQuote = (currentQuote + 1) % inspirationQuotes.count
                }
            }
        }
    }
}

// MARK: - Thought Input Section
struct ThoughtInputSection: View {
    @Binding var text: String
    @FocusState.Binding var isTextFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.white)
                Text("Your Thought")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
                // Character count
                if !text.isEmpty {
                    Text("\(text.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.leading, 4)
            
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
                    .frame(minHeight: 120)
                
                // Text Editor
                TextEditor(text: $text)
                    .foregroundColor(.white)
                    .font(.body)
                    .padding(16)
                    .scrollContentBackground(.hidden)
                    .focused($isTextFocused)
                
                // Placeholder with animation
                if text.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type anything that comes to mind...")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.body)
                        
                        Text("Examples: \"Call mom\", \"Project idea\", \"Grocery list\"")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.caption)
                            .italic()
                    }
                    .padding(16)
                    .allowsHitTesting(false)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isTextFocused ? Color.white.opacity(0.6) : Color.white.opacity(0.3),
                        lineWidth: isTextFocused ? 2 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isTextFocused)
            )
        }
    }
}

// MARK: - Quick Templates Section
struct QuickTemplatesSection: View {
    @Binding var selectedTemplate: TouchLaterTemplate?
    let onTemplateSelect: (TouchLaterTemplate) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Quick Ideas")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.leading, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(TouchLaterTemplate.allTemplates, id: \.id) { template in
                    TouchLaterTemplateCard(
                        template: template,
                        isSelected: selectedTemplate?.id == template.id,
                        onTap: {
                            onTemplateSelect(template)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Template Card
struct TouchLaterTemplateCard: View {
    let template: TouchLaterTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .CC : .white)
                
                Text(template.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .CC : .white)
                    .multilineTextAlignment(.center)
                
                Text(template.subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.2)
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

// MARK: - Tips Section
struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Pro Tips")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.leading, 4)
            
            VStack(spacing: 8) {
                TipRow(
                    icon: "arrow.right.circle",
                    text: "Swipe right to convert to Notes",
                    color: .green
                )
                
                TipRow(
                    icon: "arrow.left.circle",
                    text: "Swipe left to add to Calendar",
                    color: .blue
                )
                
                TipRow(
                    icon: "hand.tap",
                    text: "Keep thoughts short and sweet",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

// MARK: - Success Animation
struct TouchLaterSuccessAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                
                Text("Thought Captured!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                Text("Organize it whenever you're ready")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
            }
            .padding(40)
            .background(Color.CC.opacity(0.9))
            .cornerRadius(20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                rotation = 10
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Touch Later Template Model
struct TouchLaterTemplate: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let text: String
    let icon: String
    
    static let allTemplates = [
        TouchLaterTemplate(
            title: "Quick Task",
            subtitle: "Something to do",
            text: "Remember to ",
            icon: "checkmark.circle"
        ),
        TouchLaterTemplate(
            title: "Call Someone",
            subtitle: "Phone reminder",
            text: "Call ",
            icon: "phone.fill"
        ),
        TouchLaterTemplate(
            title: "Random Idea",
            subtitle: "Creative thought",
            text: "Idea: ",
            icon: "lightbulb.fill"
        ),
        TouchLaterTemplate(
            title: "Meeting Topic",
            subtitle: "Discuss later",
            text: "Bring up in meeting: ",
            icon: "person.3.fill"
        ),
        TouchLaterTemplate(
            title: "Shopping Item",
            subtitle: "Buy something",
            text: "Buy ",
            icon: "cart.fill"
        ),
        TouchLaterTemplate(
            title: "Free Thought",
            subtitle: "Whatever's on mind",
            text: "",
            icon: "brain.head.profile"
        )
    ]
}

#Preview {
    CustomTouchLaterAddSheet { text in
        print("Saved: \(text)")
    }
}
