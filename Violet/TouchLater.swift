//
//  TouchLaterPageContent.swift
//  Violet
//
//  Created by Mihail Gjoni on 7/29/25.
//

import SwiftUI

struct TouchLaterPageContent: View {
    @ObservedObject var touchLaterManager: TouchLaterManager
    @State private var showingAddItem = false
    @State private var showingCalendarSetup = false
    @State private var showingNotesSetup = false
    @State private var selectedItem: TouchItem?
    @State private var itemToProcess: TouchItem? // Store item temporarily
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with Add button and item count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Touch Later")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if touchLaterManager.touchItems.count > 0 {
                        Text("\(touchLaterManager.touchItems.count) items")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingAddItem = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.CC.opacity(0.7))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Touch items stack
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(touchLaterManager.touchItems) { item in
                        TouchItemCard(
                            item: item,
                            onSwipeLeft: {
                                // Swipe left = Calendar
                                // Store the item but DON'T remove it yet
                                itemToProcess = item
                                selectedItem = item
                                showingCalendarSetup = true
                            },
                            onSwipeRight: {
                                // Swipe right = Notes
                                // Store the item but DON'T remove it yet
                                itemToProcess = item
                                selectedItem = item
                                showingNotesSetup = true
                            }
                        )
                    }
                    
                    if touchLaterManager.touchItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("No items to touch later")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Tap + to add something you want to organize later")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingAddItem) {
            CustomTouchLaterAddSheet { text in
                touchLaterManager.addTouchLaterItem(from: text) // Auto-saves
            }
        }
        .sheet(isPresented: $showingCalendarSetup) {
            TouchLaterCalendarSetupSheet(
                item: selectedItem,
                onCancel: {
                    // Keep item in Touch Later
                    selectedItem = nil
                    itemToProcess = nil
                },
                onComplete: {
                    // Remove from Touch Later and add to calendar
                    if let item = itemToProcess {
                        touchLaterManager.removeItem(item)
                    }
                    selectedItem = nil
                    itemToProcess = nil
                }
            )
        }
        .sheet(isPresented: $showingNotesSetup) {
            TouchLaterNotesSetupSheet(
                item: selectedItem,
                onCancel: {
                    // User cancelled - keep the item in Touch Later
                    selectedItem = nil
                    itemToProcess = nil
                },
                onComplete: {
                    // User confirmed - remove from Touch Later
                    if let item = itemToProcess {
                        touchLaterManager.removeItem(item)
                    }
                    selectedItem = nil
                    itemToProcess = nil
                }
            )
        }
        .onAppear {
            print("📱 Touch Later page appeared with \(touchLaterManager.touchItems.count) items")
        }
    }
}

struct TouchItemCard: View {
    let item: TouchItem
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isBeingDragged = false
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Text("Added \(item.createdDate, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.CC.opacity(0.7))
        .cornerRadius(12)
        .padding(.horizontal)
        .offset(x: offset)
        .background(
            // Background indicators for swipe directions
            HStack {
                if offset > 50 {
                    // Swiping right - Notes
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(.green)
                        Text("Notes")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.leading, 30)
                }
                
                Spacer()
                
                if offset < -50 {
                    // Swiping left - Calendar
                    HStack {
                        Spacer()
                        Text("Calendar")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, 30)
                }
            }
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    isBeingDragged = true
                    offset = value.translation.width
                }
                .onEnded { value in
                    isBeingDragged = false
                    
                    if offset > swipeThreshold {
                        // Swipe right - Notes
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = 500 // Animate off screen
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwipeRight()
                        }
                    } else if offset < -swipeThreshold {
                        // Swipe left - Calendar
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = -500 // Animate off screen
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwipeLeft()
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                }
        )
        .animation(.spring(), value: isBeingDragged)
    }
}

struct AddTouchItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var itemText = ""
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("What's on your mind?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                TextEditor(text: $itemText)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .frame(minHeight: 120)
                
                Text("Don't worry about being specific - just capture the thought and organize it later!")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Touch Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onSave(itemText)
                        dismiss()
                    }
                    .disabled(itemText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct CalendarSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: TouchItem?
    let onCancel: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Set up Calendar Event")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if let item = item {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Original thought:")
                            .font(.headline)
                        
                        Text(item.text)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
                
                Text("Convert this thought into a calendar event.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding()
                
                Text("Future: Calendar integration will be added here")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Calendar Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onComplete()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TouchLaterNotesSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: TouchItem?
    let onCancel: () -> Void
    let onComplete: () -> Void
    
    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var showingSuccessAnimation = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(gradient: Gradient(colors: [.CC, .CBW]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.title2)
                        Text("Convert to Note")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveNote()
                    }
                    .foregroundColor(canSave ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canSave ? Color.green.opacity(0.8) : Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .disabled(!canSave)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Original Thought Display
                        if let item = item {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "hand.point.up.left.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("Original Touch Later thought:")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                Text(item.text)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "textformat")
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Note Title")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(.leading, 4)
                            
                            TextField("Give your note a title...", text: $noteTitle)
                                .foregroundColor(.white)
                                .font(.body)
                                .padding(16)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)
                                .focused($isTitleFocused)
                        }
                        
                        // Content Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Note Content")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(.leading, 4)
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $noteContent)
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .padding(12)
                                    .scrollContentBackground(.hidden)
                                    .focused($isContentFocused)
                                
                                if noteContent.isEmpty {
                                    Text("Expand on your thought here...")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.body)
                                        .padding(16)
                                        .allowsHitTesting(false)
                                }
                            }
                            .frame(minHeight: 150)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)
                        }
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    if let item = item {
                                        noteContent = item.text
                                    }
                                }) {
                                    Label("Use as content", systemImage: "arrow.down.doc")
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    if let item = item {
                                        let firstWords = item.text.split(separator: " ").prefix(5).joined(separator: " ")
                                        noteTitle = firstWords
                                    }
                                }) {
                                    Label("Use as title", systemImage: "textformat")
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            
            // Success Animation
            if showingSuccessAnimation {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Note Created!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Your thought has been converted to a note")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(40)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(20)
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Pre-fill content with the Touch Later item text
            if let item = item {
                noteContent = item.text
                // Auto-generate a title from the first few words
                let words = item.text.split(separator: " ").prefix(5).joined(separator: " ")
                if words.count < item.text.count {
                    noteTitle = words + "..."
                } else {
                    noteTitle = words
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTitleFocused = true
            }
        }
    }
    
    private var canSave: Bool {
        !noteTitle.trimmingCharacters(in: .whitespaces).isEmpty ||
        !noteContent.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveNote() {
        // Save to NotesManager
        NotesManager.shared.addNote(
            title: noteTitle.isEmpty ? "Untitled Note" : noteTitle,
            content: noteContent
        )
        
        // Show success animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSuccessAnimation = true
        }
        
        // Complete after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete()
            dismiss()
        }
    }
}

#Preview {
    TouchLaterPageContent(touchLaterManager: TouchLaterManager())
        .background(
            LinearGradient(gradient: Gradient(colors: [.purple, .blue]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
}
