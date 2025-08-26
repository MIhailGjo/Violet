//
//  mainVeiw.swift
//  violet
//
//  Created by Mihail Gjoni on 6/20/25.
//

import SwiftUI

// MARK: - Touch Later Data Models
struct TouchItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let createdDate: Date
    
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdDate = Date()
    }
}

// MARK: - Touch Later Manager
class TouchLaterManager: ObservableObject {
    @Published var touchItems: [TouchItem] = []
    
    func addTouchLaterItem(from input: String) {
        let newItem = TouchItem(text: input)
        touchItems.insert(newItem, at: 0) // Add to top of stack
    }
    
    func removeItem(_ item: TouchItem) {
        touchItems.removeAll { $0.id == item.id }
    }
}

struct MainChatHome: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab = 1 // Start with Ask tab (index 1)
    @State private var showProfile: Bool = false
    @State private var showTouchLaterPage = false
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var touchLaterManager = TouchLaterManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.CC, .CBW]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    TopButtonsView(showProfile: $showProfile, isLoggedIn: $isLoggedIn)
                    
                    TabView(selection: $selectedTab) {
                        NotePage()
                            .tag(0)
                        
                        AskPageContent(
                            selectedTab: $selectedTab,
                            showTouchLaterPage: $showTouchLaterPage,
                            calendarManager: calendarManager,
                            touchLaterManager: touchLaterManager
                        )
                        .tag(1)
                        
                        CalendarPageWrapper(calendarManager: calendarManager)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Custom Tab Bar
                    CustomTabBar(selectedTab: $selectedTab)
                }
                .gesture(
                    // Swipe down gesture to show Touch Later page
                    DragGesture()
                        .onEnded { value in
                            let translation = value.translation
                            if translation.height > 100 && abs(translation.width) < 50 {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showTouchLaterPage = true
                                }
                            }
                        }
                )
                
                // Touch Later Page Overlay
                if showTouchLaterPage {
                    TouchLaterPageOverlay(
                        showTouchLaterPage: $showTouchLaterPage,
                        touchLaterManager: touchLaterManager
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                }
            }
        }
    }
}

struct TouchLaterPageOverlay: View {
    @Binding var showTouchLaterPage: Bool
    @ObservedObject var touchLaterManager: TouchLaterManager
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [.CC, .CBW]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Touch Later Content
                TouchLaterPageContent(touchLaterManager: touchLaterManager)
                
                // Done button section
                VStack(spacing: 8) {
                    // Instructions
                    VStack(spacing: 4) {
                        Text("Swipe left for Calendar")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Swipe right for Notes")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 12)
                    
                    // Done button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showTouchLaterPage = false
                        }
                    }) {
                        Text("Done")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.CC.opacity(0.8))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .gesture(
            // Swipe up gesture to dismiss
            DragGesture()
                .onEnded { value in
                    let translation = value.translation
                    if translation.height < -100 && abs(translation.width) < 50 {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showTouchLaterPage = false
                        }
                    }
                }
        )
    }
}

struct AskPageContent: View {
    @State private var messages: [AIMessage] = []
    @Binding var selectedTab: Int
    @Binding var showTouchLaterPage: Bool
    @ObservedObject var calendarManager: CalendarManager
    @ObservedObject var touchLaterManager: TouchLaterManager
    
    var body: some View {
        VStack {
            MessageListView(messages: messages)
            InputBar(
                messages: $messages,
                selectedTab: $selectedTab,
                showTouchLaterPage: $showTouchLaterPage,
                calendarManager: calendarManager,
                touchLaterManager: touchLaterManager
            )
        }
    }
}

struct AIMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let classification: String?
    
    init(text: String, isUser: Bool, classification: String? = nil) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.classification = classification
    }
}

struct MessageListView: View {
    let messages: [AIMessage]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                            Text(message.text)
                                .foregroundColor(.white)
                                .padding()
                                .background(message.isUser ? Color.CC.opacity(0.7) : Color.CBW.opacity(0.7))
                                .cornerRadius(12)
                                .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
                            
                            if let classification = message.classification {
                                Text("AI Classification: \(classification)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 4)
                            }
                        }
                        .id(message.id)
                    }
                }
                .padding()
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
            .onChange(of: messages.count) { oldValue, newValue in
                if newValue > 0 {
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct InputBar: View {
    @Binding var messages: [AIMessage]
    @Binding var selectedTab: Int
    @Binding var showTouchLaterPage: Bool
    @ObservedObject var calendarManager: CalendarManager
    @ObservedObject var touchLaterManager: TouchLaterManager
    @State private var messageText: String = ""
    @FocusState private var isFocused: Bool
    @State private var tapTrigger = false
    @State private var textEditorHeight: CGFloat = 40
    @State private var isProcessing = false
    
    private var hasText: Bool {
        !messageText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Background container for the entire input area
            HStack {
                ZStack(alignment: .topLeading) {
                    Text(messageText + " ") // Add a space to count final line
                        .font(.body)
                        .foregroundColor(.clear)
                        .padding(.leading, 16)
                        .padding(.trailing, 60) // Extra padding to avoid button overlap
                        .padding(.vertical, 16)
                        .overlay(
                                   GeometryReader { geo in
                                       Color.clear
                                           .onAppear {
                                               textEditorHeight = max(50, geo.size.height)
                                           }
                                           .onChange(of: messageText) {
                                               textEditorHeight = max(50, geo.size.height)
                                           }
                                   }
                               )
                    
                    TextEditor(text: $messageText)
                        .foregroundColor(.white)
                        .focused($isFocused)
                        .frame(minHeight: 50, maxHeight: max(50, textEditorHeight))
                        .padding(.leading, 20)
                        .padding(.trailing, 60) // Padding to avoid button overlap
                        .padding(.vertical, 10)
                        .scrollContentBackground(.hidden)
                        .background(Color.CC.opacity(0.14))
                        .cornerRadius(25)
                        .disabled(isProcessing)
                    
                    // Placeholder text
                    if messageText.isEmpty && !isProcessing {
                        Text("Type a message...")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 20)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                    
                    // Processing indicator
                    if isProcessing {
                        Text("AI is thinking...")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 20)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
            }
            
            // Dynamic button - Touch when empty, Send when has text
            Button(action: {
                if hasText {
                    sendMessage()
                } else {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showTouchLaterPage = true
                    }
                }
            }) {
                Group {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else if hasText {
                        // Send button
                        Image(systemName: "arrowshape.zigzag.forward.fill")
                            .font(.title2)
                            .symbolEffect(.bounce, value: tapTrigger)
                    } else {
                        // Touch button - same style as send but different icon
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.title2)
                    }
                }
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .padding(12)
                .background(Color.CC)
                .clipShape(Circle())
                .animation(.easeInOut(duration: 0.2), value: hasText)
            }
            .disabled(isProcessing)
            .padding(.trailing, 8) // Small padding from the edge
            .padding(.bottom, max(50, textEditorHeight) > 50 ? 8 : 0) // Adjust position for multiline
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    private func sendMessage() {
        let inputText = messageText.trimmingCharacters(in: .whitespaces)
        guard !inputText.isEmpty else { return }
        
        // Add user message immediately
        let userMessage = AIMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        
        // Clear input and dismiss keyboard
        messageText = ""
        isFocused = false
        tapTrigger.toggle()
        isProcessing = true
        
        // Get AI classification
        AIService.shared.classifyUserInput(inputText) { result in
            isProcessing = false
            
            switch result {
            case .calendar:
                // Parse and create calendar event
                calendarManager.addEventFromAI(inputText) { success, message in
                    let classification = success ? "CALENDAR ✅" : "CALENDAR ❌"
                    let aiMessage = AIMessage(text: message, isUser: false, classification: classification)
                    messages.append(aiMessage)
                    
                    // Switch to calendar tab if successful
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                selectedTab = 2
                            }
                        }
                    }
                }
                
            case .touchLater:
                // Add to Touch Later stack
                touchLaterManager.addTouchLaterItem(from: inputText)
                
                let classification = "TOUCH LATER ✅"
                let responseText = "I've added '\(inputText)' to your Touch Later list. You can organize it when you're ready by swiping left for Calendar or right for Notes."
                let aiMessage = AIMessage(text: responseText, isUser: false, classification: classification)
                messages.append(aiMessage)
                
            case .error(let errorMessage):
                let classification = "ERROR"
                let responseText = "Sorry, I encountered an error: \(errorMessage)"
                let aiMessage = AIMessage(text: responseText, isUser: false, classification: classification)
                messages.append(aiMessage)
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            // Note button
            Button(action: {
                // Dismiss keyboard
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 0
                }
            }) {
                Text("Note")
                    .font(.title2)
                    .frame(width: 87)
                    .foregroundColor(selectedTab == 0 ? Color.black : Color.white)
                    .padding(10)
                    .background(
                        selectedTab == 0 ?
                        LinearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.CC, .CBW], startPoint: .bottom, endPoint: .center)
                    )
                    .cornerRadius(100)
            }
            
            // Ask button
            Button(action: {
                // Dismiss keyboard
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 1
                }
            }) {
                Text("Ask")
                    .font(.title2)
                    .frame(width: 87)
                    .foregroundColor(selectedTab == 1 ? Color.black : Color.white)
                    .padding(10)
                    .background(
                        selectedTab == 1 ?
                        LinearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.CC, .CBW], startPoint: .bottom, endPoint: .center)
                    )
                    .cornerRadius(100)
            }
            
            // Calendar button
            Button(action: {
                // Dismiss keyboard
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 2
                }
            }) {
                Text("Calendar")
                    .font(.title2)
                    .frame(width: 87)
                    .foregroundColor(selectedTab == 2 ? Color.black : Color.white)
                    .padding(10)
                    .background(
                        selectedTab == 2 ?
                        LinearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.CC, .CBW], startPoint: .bottom, endPoint: .center)
                    )
                    .cornerRadius(100)
                    .padding(.horizontal, 14)
            }
        }
        .padding(.bottom, 5)
    }
}

struct TopButtonsView: View {
    @Binding var showProfile: Bool
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                            // Left button action
                        }) {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.CC.opacity(0.7))
                        .cornerRadius(20)
                    
            Spacer()
            
            Button(action: {
                            showProfile = true
                        }) {
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.CC.opacity(0.7))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    .navigationDestination(isPresented: $showProfile) {
                        ProfilePageVeiw(isLoggedIn: $isLoggedIn)
                           }
    }
}

// Calendar Page Wrapper
struct CalendarPageWrapper: View {
    @ObservedObject var calendarManager: CalendarManager
    
    var body: some View {
        // Use the full CalendarPage from CalendarPage.swift
        CalendarPage()
    }
}

#Preview {
    MainChatHome(isLoggedIn: .constant(true))
}
