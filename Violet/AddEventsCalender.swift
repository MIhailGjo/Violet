//
//  CustomCalendarAddEvent.swift
//  Violet
//
//  Created by Mihail Gjoni on 8/25/25.
//

import SwiftUI

// MARK: - Touch Later Calendar Setup Sheet
struct TouchLaterCalendarSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: TouchItem?
    let onCancel: () -> Void
    let onComplete: () -> Void
    
    @State private var eventTitle = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var eventDescription = ""
    @State private var selectedCategory = "General"
    @State private var isAllDay = false
    @State private var showingSuccessAnimation = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    private let categories = ["General", "Work", "Personal", "Health", "Social", "Travel"]
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(gradient: Gradient(colors: [.CC, .CBW]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                CustomCalendarHeader(
                    onCancel: {
                        onCancel()
                        dismiss()
                    },
                    onSave: {
                        saveEvent()
                    },
                    canSave: !eventTitle.trimmingCharacters(in: .whitespaces).isEmpty
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Original Touch Later Thought
                        if let item = item {
                            OriginalThoughtSection(item: item, eventTitle: $eventTitle)
                        }
                        
                        // Event Title
                        EventTitleSection(
                            eventTitle: $eventTitle,
                            isTitleFocused: $isTitleFocused
                        )
                        
                        // Date & Time Section
                        DateTimeSection(
                            startDate: $startDate,
                            endDate: $endDate,
                            isAllDay: $isAllDay
                        )
                        
                        // Category Selection
                        CategorySection(
                            selectedCategory: $selectedCategory,
                            categories: categories
                        )
                        
                        // Description Section
                        DescriptionSection(
                            eventDescription: $eventDescription,
                            isDescriptionFocused: $isDescriptionFocused
                        )
                        
                        // Quick Templates
                        if item != nil {
                            QuickCalendarTemplates(
                                originalText: item?.text ?? "",
                                eventTitle: $eventTitle,
                                eventDescription: $eventDescription,
                                startDate: $startDate,
                                endDate: $endDate,
                                selectedCategory: $selectedCategory
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            
            // Success Animation
            if showingSuccessAnimation {
                CalendarSuccessAnimation()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupInitialValues()
        }
    }
    
    private func setupInitialValues() {
        if let item = item {
            // Pre-fill with Touch Later text
            eventTitle = item.text
            
            // Try to parse time from the text using AI
            AIService.shared.parseCalendarEvent(from: item.text) { parsedEvent in
                if let event = parsedEvent {
                    DispatchQueue.main.async {
                        self.eventTitle = event.title
                        self.startDate = event.startDate
                        self.endDate = event.endDate
                        self.eventDescription = event.description ?? ""
                        self.selectedCategory = event.category ?? "General"
                        self.isAllDay = event.isAllDay
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isTitleFocused = true
        }
    }
    
    private func saveEvent() {
        let calendarEvent = CalendarEvent(
            title: eventTitle,
            startDate: startDate,
            endDate: endDate,
            description: eventDescription.isEmpty ? nil : eventDescription,
            category: selectedCategory,
            isAllDay: isAllDay
        )
        
        CalendarManager.shared.addEvent(calendarEvent)
        
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

// MARK: - Custom Calendar Header
struct CustomCalendarHeader: View {
    let onCancel: () -> Void
    let onSave: () -> Void
    let canSave: Bool
    
    var body: some View {
        HStack {
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
            
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                Text("Create Event")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            
            Spacer()
            
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
                .background(canSave ? Color.blue.opacity(0.8) : Color.white.opacity(0.2))
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

// MARK: - Original Thought Section
struct OriginalThoughtSection: View {
    let item: TouchItem
    @Binding var eventTitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.point.up.left.fill")
                    .foregroundColor(.white.opacity(0.7))
                Text("From Touch Later:")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(item.text)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            Button(action: {
                eventTitle = item.text
            }) {
                Label("Use as title", systemImage: "arrow.up.doc")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Event Title Section
struct EventTitleSection: View {
    @Binding var eventTitle: String
    @FocusState.Binding var isTitleFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.white.opacity(0.7))
                Text("Event Title")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.leading, 4)
            
            TextField("What's happening?", text: $eventTitle)
                .foregroundColor(.white)
                .font(.body)
                .padding(16)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isTitleFocused ? Color.white.opacity(0.6) : Color.white.opacity(0.3),
                            lineWidth: isTitleFocused ? 2 : 1
                        )
                        .animation(.easeInOut(duration: 0.2), value: isTitleFocused)
                )
                .focused($isTitleFocused)
        }
    }
}

// MARK: - Date Time Section
struct DateTimeSection: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isAllDay: Bool
    @State private var showingDatePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.white.opacity(0.7))
                Text("Date & Time")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("All Day", isOn: $isAllDay)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding(.leading, 4)
            
            VStack(spacing: 12) {
                // Start Date/Time
                DateTimeRow(
                    label: "Starts",
                    date: $startDate,
                    displayComponents: isAllDay ? .date : [.date, .hourAndMinute]
                )
                
                // End Date/Time
                DateTimeRow(
                    label: "Ends",
                    date: $endDate,
                    displayComponents: isAllDay ? .date : [.date, .hourAndMinute]
                )
                
                // Duration display
                if !isAllDay {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.caption)
                        Text("Duration: \(formatDuration())")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }
    
    private func formatDuration() -> String {
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(minutes) minutes"
        }
    }
}

// MARK: - Date Time Row
struct DateTimeRow: View {
    let label: String
    @Binding var date: Date
    let displayComponents: DatePicker.Components
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 60, alignment: .leading)
            
            DatePicker("", selection: $date, displayedComponents: displayComponents)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .colorScheme(.dark)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Category Section
struct CategorySection: View {
    @Binding var selectedCategory: String
    let categories: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.white.opacity(0.7))
                Text("Category")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            color: colorForCategory(category)
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Work": return .blue
        case "Personal": return .green
        case "Health": return .red
        case "Social": return .purple
        case "Travel": return .orange
        default: return .gray
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(category)
                    .font(.body)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? color.opacity(0.4) : Color.white.opacity(0.15)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Description Section
struct DescriptionSection: View {
    @Binding var eventDescription: String
    @FocusState.Binding var isDescriptionFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.white.opacity(0.7))
                Text("Description (Optional)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.leading, 4)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $eventDescription)
                    .foregroundColor(.white)
                    .font(.body)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .focused($isDescriptionFocused)
                
                if eventDescription.isEmpty {
                    Text("Add notes, location, or other details...")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.body)
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 100)
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isDescriptionFocused ? Color.white.opacity(0.6) : Color.white.opacity(0.3),
                        lineWidth: isDescriptionFocused ? 2 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isDescriptionFocused)
            )
        }
    }
}

// MARK: - Quick Calendar Templates
struct QuickCalendarTemplates: View {
    let originalText: String
    @Binding var eventTitle: String
    @Binding var eventDescription: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var selectedCategory: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.yellow)
                Text("Quick Setup")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 12) {
                QuickSetupButton(
                    title: "Meeting (1 hour)",
                    icon: "person.3.fill",
                    color: .blue
                ) {
                    eventTitle = originalText.isEmpty ? "Meeting" : originalText
                    endDate = startDate.addingTimeInterval(3600)
                    selectedCategory = "Work"
                }
                
                QuickSetupButton(
                    title: "Appointment (30 min)",
                    icon: "calendar.badge.clock",
                    color: .green
                ) {
                    eventTitle = originalText.isEmpty ? "Appointment" : originalText
                    endDate = startDate.addingTimeInterval(1800)
                    selectedCategory = "Personal"
                }
                
                QuickSetupButton(
                    title: "All Day Event",
                    icon: "sun.max.fill",
                    color: .orange
                ) {
                    eventTitle = originalText.isEmpty ? "Event" : originalText
                    selectedCategory = "General"
                }
            }
        }
    }
}

// MARK: - Quick Setup Button
struct QuickSetupButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Calendar Success Animation
struct CalendarSuccessAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                
                Text("Event Created!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                Text("Added to your calendar")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
            }
            .padding(40)
            .background(Color.blue.opacity(0.9))
            .cornerRadius(20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    TouchLaterCalendarSetupSheet(
        item: TouchItem(text: "Meeting with team about new project"),
        onCancel: {},
        onComplete: {}
    )
}
