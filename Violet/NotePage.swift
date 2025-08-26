//
//  NotePage.swift
//  Violet
//
//  Created by Mihail Gjoni on 7/16/25.
//

import SwiftUI

// MARK: - Notes Storage
class NotesStorage {
    static let shared = NotesStorage()
    
    private init() {}
    
    private let storageKey = "savedNotes"
    
    func save(_ notes: [Note]) {
        do {
            let encoded = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            print("✅ Notes saved successfully")
        } catch {
            print("❌ Failed to save notes: \(error)")
        }
    }
    
    func load() -> [Note] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("📱 No notes found - starting fresh")
            return []
        }
        
        do {
            let notes = try JSONDecoder().decode([Note].self, from: data)
            print("✅ Loaded \(notes.count) notes")
            return notes
        } catch {
            print("❌ Failed to load notes: \(error)")
            return []
        }
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🗑️ All notes cleared")
    }
}

// MARK: - Notes Manager
class NotesManager: ObservableObject {
    static let shared = NotesManager() // Add singleton for Touch Later integration
    
    @Published var notes: [Note] = []
    private let storage = NotesStorage.shared
    
    init() {
        loadNotes()
    }
    
    func addNote(title: String, content: String) {
        let newNote = Note(
            id: UUID(),
            title: title.isEmpty ? "Untitled Note" : title,
            content: content,
            createdDate: Date(),
            lastModified: Date()
        )
        notes.append(newNote)
        saveNotes()
        print("📝 Added note: '\(newNote.title)'")
    }
    
    func updateNote(_ updatedNote: Note) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
            saveNotes()
            print("✏️ Updated note: '\(updatedNote.title)'")
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
        print("🗑️ Deleted note: '\(note.title)'")
    }
    
    // Method for Touch Later integration
    func addNoteFromTouchLater(title: String, content: String) {
        addNote(title: title, content: content)
    }
    
    var isEmpty: Bool {
        return notes.isEmpty
    }
    
    var noteCount: Int {
        return notes.count
    }
    
    private func saveNotes() {
        storage.save(notes)
    }
    
    private func loadNotes() {
        notes = storage.load()
    }
}

struct NotePage: View {
    @StateObject private var notesManager = NotesManager()
    @State private var showingAddNote = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header with count and + button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if !notesManager.isEmpty {
                            Text("\(notesManager.noteCount) notes")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Add note button
                    Button(action: {
                        showingAddNote = true
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
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Search notes...", text: $searchText)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Notes list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredNotes) { note in
                            NavigationLink(destination: NoteDetailView(
                                note: note,
                                onUpdate: notesManager.updateNote,
                                onDelete: notesManager.deleteNote
                            )) {
                                NoteRowView(note: note)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if filteredNotes.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text(notesManager.isEmpty ? "No notes yet" : "No notes match your search")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                if notesManager.isEmpty {
                                    Text("Create notes by tapping + or swiping Touch Later items to Notes")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 60)
                        }
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingAddNote) {
                CustomAddNoteSheet(notesManager: notesManager)
            }
        }
        .onAppear {
            print("📱 Notes page appeared with \(notesManager.noteCount) notes")
        }
    }
    
    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notesManager.notes.sorted { $0.lastModified > $1.lastModified }
        } else {
            return notesManager.notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.lastModified > $1.lastModified }
        }
    }
}

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    let createdDate: Date
    var lastModified: Date
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(note.content)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
            
            HStack {
                Text("Modified \(note.lastModified, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.CC.opacity(0.6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct NoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var noteTitle: String
    @State private var noteContent: String
    @State private var showingDeleteAlert = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    let note: Note
    let onUpdate: (Note) -> Void
    let onDelete: (Note) -> Void
    
    init(note: Note, onUpdate: @escaping (Note) -> Void, onDelete: @escaping (Note) -> Void) {
        self.note = note
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._noteTitle = State(initialValue: note.title)
        self._noteContent = State(initialValue: note.content)
    }
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(gradient: Gradient(colors: [.CC, .CBW]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                    
                    TextField("Note title", text: $noteTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .focused($isTitleFocused)
                }
                
                // Content input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                    
                    TextEditor(text: $noteContent)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                        .focused($isContentFocused)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    
                    Button("Save") {
                        saveNote()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete(note)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
    }
    
    private func saveNote() {
        let updatedNote = Note(
            id: note.id,
            title: noteTitle.isEmpty ? "Untitled Note" : noteTitle,
            content: noteContent,
            createdDate: note.createdDate,
            lastModified: Date()
        )
        onUpdate(updatedNote)
        dismiss()
    }
}

// MARK: - Custom Add Note Sheet matching app theme
struct CustomAddNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var notesManager: NotesManager
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
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    Text("New Note")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveNote()
                    }
                    .foregroundColor(canSave ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canSave ? Color.CC.opacity(0.8) : Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .disabled(!canSave)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note Title")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            TextField("Enter note title...", text: $noteTitle)
                                .foregroundColor(.white)
                                .font(.body)
                                .padding(16)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)
                                .focused($isTitleFocused)
                        }
                        
                        // Content Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note Content")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $noteContent)
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .padding(16)
                                    .scrollContentBackground(.hidden)
                                    .focused($isContentFocused)
                                
                                if noteContent.isEmpty {
                                    Text("Write your thoughts here...")
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
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Note Created!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(Color.CC.opacity(0.9))
                    .cornerRadius(20)
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
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
        notesManager.addNote(title: noteTitle, content: noteContent)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSuccessAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

#Preview {
    NotePage()
}
