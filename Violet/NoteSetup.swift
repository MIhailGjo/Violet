//
//  CustomNotesSetupSheet.swift
//  Violet
//
//  Created by Mihail Gjoni on 8/17/25.
//

import SwiftUI

struct CustomNotesSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: TouchItem?
    let onComplete: () -> Void
    
    @State private var noteTitle = ""
    @State private var noteBody = ""
    @State private var showingSuccessAnimation = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isBodyFocused: Bool
    
    // Add reference to NotesManager
    private let notesManager = NotesManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(gradient: Gradient(colors: [.CC, .CBW]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                CustomHeaderView(
                    title: "Create Note",
                    onCancel: {
                        onComplete()
                        dismiss()
                    },
                    onSave: {
                        saveNote()
                    },
                    canSave: !noteTitle.trimmingCharacters(in: .whitespaces).isEmpty
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Original Touch Later Item
                        if let item = item {
                            OriginalItemCard(item: item)
                        }
                        
                        // Note Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note Title")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            CustomTextField(
                                text: $noteTitle,
                                placeholder: "Enter note title...",
                                isMultiline: false
                            )
                            .focused($isTitleFocused)
                        }
                        
                        // Note Body Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note Content")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            CustomTextEditor(
                                text: $noteBody,
                                placeholder: "Write your thoughts here..."
                            )
                            .focused($isBodyFocused)
                        }
                        
                        // Quick Action Buttons
                        QuickActionButtons(
                            onTemplate: { template in
                                applyTemplate(template)
                            }
                        )
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            
            // Success Animation Overlay
            if showingSuccessAnimation {
                SuccessAnimationView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Pre-fill title from Touch Later item
            if let item = item {
                noteTitle = extractTitle(from: item.text)
                noteBody = item.text
            }
            
            // Focus on title first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTitleFocused = true
            }
        }
        .navigationBarHidden(true)
    }
    
    private func saveNote() {
        // Save note using NotesManager
        notesManager.addNote(title: noteTitle, content: noteBody)
        print("📝 Saving note from Touch Later: '\(noteTitle)' with body: '\(noteBody)'")
        
        // Show success animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSuccessAnimation = true
        }
        
        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete()
            dismiss()
        }
    }
    
    private func extractTitle(from text: String) -> String {
        // Extract first sentence or first 50 characters as title
        let sentences = text.components(separatedBy: ". ")
        if let firstSentence = sentences.first, firstSentence.count > 0 {
            return String(firstSentence.prefix(50))
        }
        return String(text.prefix(50))
    }
    
    private func applyTemplate(_ template: NoteTemplate) {
        noteTitle = template.title
        noteBody = template.body
    }
}

// MARK: - Custom Header
struct CustomHeaderView: View {
    let title: String
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
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
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
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
}

// MARK: - Original Item Card
struct OriginalItemCard: View {
    let item: TouchItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Original Thought")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(item.text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            Text("Added \(item.createdDate, style: .relative) ago")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.CC.opacity(0.3))
        .cornerRadius(16)
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let isMultiline: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .frame(height: isMultiline ? 120 : 50)
            
            // Text Input
            if isMultiline {
                TextEditor(text: $text)
                    .foregroundColor(.white)
                    .font(.body)
                    .padding(16)
                    .scrollContentBackground(.hidden)
            } else {
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.6))
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, isMultiline ? 16 : 14)
                    .allowsHitTesting(false)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Custom Text Editor
struct CustomTextEditor: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .frame(minHeight: 150)
            
            // Text Editor
            TextEditor(text: $text)
                .foregroundColor(.white)
                .font(.body)
                .padding(16)
                .scrollContentBackground(.hidden)
            
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.6))
                    .font(.body)
                    .padding(16)
                    .allowsHitTesting(false)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Quick Action Buttons
struct QuickActionButtons: View {
    let onTemplate: (NoteTemplate) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Templates")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(NoteTemplate.allTemplates, id: \.title) { template in
                    Button(action: {
                        onTemplate(template)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: template.icon)
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text(template.title)
                                .font(.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Success Animation
struct SuccessAnimationView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(scale)
                
                Text("Note Created!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
            .padding(40)
            .background(Color.CC.opacity(0.9))
            .cornerRadius(20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Note Template Model
struct NoteTemplate {
    let title: String
    let body: String
    let icon: String
    
    static let allTemplates = [
        NoteTemplate(
            title: "To-Do List",
            body: "Tasks to complete:\n\n• \n• \n• ",
            icon: "list.bullet"
        ),
        NoteTemplate(
            title: "Meeting Notes",
            body: "Meeting: \nDate: \nAttendees: \n\nAgenda:\n• \n\nAction Items:\n• ",
            icon: "person.3"
        ),
        NoteTemplate(
            title: "Idea",
            body: "💡 Idea: \n\nDescription:\n\n\nNext Steps:\n• ",
            icon: "lightbulb"
        ),
        NoteTemplate(
            title: "Journal Entry",
            body: "Today I...\n\n\nThoughts:\n\n\nGrateful for:",
            icon: "book"
        )
    ]
}

#Preview {
    CustomNotesSetupSheet(
        item: TouchItem(text: "Remember to call mom about dinner plans"),
        onComplete: {}
    )
}
