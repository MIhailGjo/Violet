//
//  AskPage.swift
//  Violet
//
//  Created by Mihail Gjoni on 7/16/25.
//

import SwiftUI

struct AskPage: View {
    @Environment(\.dismiss) private var dismiss
    @State private var questionText = ""
    @State private var messages: [ChatMessage] = []
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.CC, .CBW]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack {
                    // Chat messages area
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(messages.indices, id: \.self) { index in
                                    ChatBubbleView(message: messages[index])
                                        .id(index)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) {
                            if !messages.isEmpty {
                                withAnimation {
                                    proxy.scrollTo(messages.count - 1, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Quick suggestion buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            QuickSuggestionButton(text: "What's the weather?") {
                                sendMessage("What's the weather?")
                            }
                            QuickSuggestionButton(text: "Set a reminder") {
                                sendMessage("Set a reminder")
                            }
                            QuickSuggestionButton(text: "Tell me a joke") {
                                sendMessage("Tell me a joke")
                            }
                            QuickSuggestionButton(text: "Help me plan") {
                                sendMessage("Help me plan")
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Input area
                    HStack {
                        TextField("Ask me anything...", text: $questionText)
                            .focused($isTextFieldFocused)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(25)
                            .onSubmit {
                                sendMessage(questionText)
                            }
                        
                        Button(action: {
                            sendMessage(questionText)
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.CC)
                                .clipShape(Circle())
                        }
                        .disabled(questionText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Ask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Add user message
        messages.append(ChatMessage(text: text, isUser: true))
        
        // Clear input
        questionText = ""
        isTextFieldFocused = false
        
        // Simulate AI response (you can integrate with ChatGPT API later)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let responses = [
                "I'd be happy to help you with that!",
                "That's an interesting question. Let me think about it.",
                "Here's what I can tell you about that topic...",
                "I understand what you're asking. Here's my response:",
                "Great question! Let me provide you with some information."
            ]
            let randomResponse = responses.randomElement() ?? "I'm here to help!"
            messages.append(ChatMessage(text: randomResponse, isUser: false))
        }
    }
}

struct ChatMessage {
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.text)
                .padding()
                .background(message.isUser ? Color.CC : Color.white.opacity(0.9))
                .foregroundColor(message.isUser ? .white : .black)
                .cornerRadius(16)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct QuickSuggestionButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(20)
        }
    }
}

#Preview {
    AskPage()
}
