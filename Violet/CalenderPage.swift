//
//  CalendarPage.swift
//  Violet
//
//  Created by Mihail Gjoni on 7/16/25.
//

import SwiftUI

// MARK: - Calendar Storage
class CalendarStorage {
    static let shared = CalendarStorage()
    
    private init() {}
    
    private let storageKey = "calendarEvents"
    
    func save(_ events: [CalendarEvent]) {
        do {
            let encoded = try JSONEncoder().encode(events)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            print("✅ Calendar events saved successfully")
        } catch {
            print("❌ Failed to save calendar events: \(error)")
        }
    }
    
    func load() -> [CalendarEvent] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("📱 No calendar events found - starting fresh")
            return []
        }
        
        do {
            let events = try JSONDecoder().decode([CalendarEvent].self, from: data)
            print("✅ Loaded \(events.count) calendar events")
            return events
        } catch {
            print("❌ Failed to load calendar events: \(error)")
            return []
        }
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🗑️ All calendar events cleared")
    }
}

// MARK: - Updated Calendar Manager
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published var events: [CalendarEvent] = []
    private let storage = CalendarStorage.shared
    
    init() {
        loadEvents()
    }
    
    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        saveEvents()
        print("📅 Added event: '\(event.title)'")
    }
    
    func removeEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        saveEvents()
        print("🗑️ Removed event: '\(event.title)'")
    }
    
    func updateEvent(_ event: CalendarEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
            print("✏️ Updated event: '\(event.title)'")
        }
    }
    
    func addEventFromAI(_ input: String, completion: @escaping (Bool, String) -> Void) {
        AIService.shared.parseCalendarEvent(from: input) { [weak self] parsedEvent in
            guard let self = self, let event = parsedEvent else {
                completion(false, "Could not parse calendar event from input")
                return
            }
            
            // Create the timeline calendar event with proper start/end times
            let calendarEvent = CalendarEvent(
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                description: event.description,
                category: event.category,
                isAllDay: event.isAllDay
            )
            
            self.addEvent(calendarEvent)
            
            let confidenceText = event.confidence > 0.8 ? "confidently" : "tentatively"
            let durationText = event.isAllDay ? "all day" : String(format: "%.1f hours", event.endDate.timeIntervalSince(event.startDate) / 3600)
            
            let dateText = self.formatDate(event.startDate)
            let timeText = event.isAllDay ? "" : "at \(self.formatTime(event.startDate))"
            
            completion(true, "I've \(confidenceText) scheduled '\(event.title)' for \(dateText) \(timeText) (\(durationText))")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var isEmpty: Bool {
        return events.isEmpty
    }
    
    var eventCount: Int {
        return events.count
    }
    
    private func saveEvents() {
        storage.save(events)
    }
    
    private func loadEvents() {
        events = storage.load()
    }
}

// MARK: - Updated Calendar Event Model
struct CalendarEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var description: String?
    var category: String?
    var isAllDay: Bool
    
    init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date? = nil, description: String? = nil, category: String? = nil, isAllDay: Bool = false) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate ?? startDate.addingTimeInterval(3600) // Default 1 hour duration
        self.description = description
        self.category = category
        self.isAllDay = isAllDay
    }
    
    // Legacy support for old CalendarEvent format
    init(id: UUID, title: String, date: Date) {
        self.id = id
        self.title = title
        self.startDate = date
        self.endDate = date.addingTimeInterval(3600) // 1 hour default
        self.description = nil
        self.category = nil
        self.isAllDay = false
    }
    
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var durationInHours: Double {
        return duration / 3600
    }
    
    var startHour: Int {
        return Calendar.current.component(.hour, from: startDate)
    }
    
    var startMinute: Int {
        return Calendar.current.component(.minute, from: startDate)
    }
}

struct CalendarPage: View {
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var selectedDate = Date()
    @State private var showingAddEvent = false
    @State private var viewMode: CalendarViewMode = .timeline
    
    enum CalendarViewMode: String, CaseIterable {
        case timeline = "Timeline"
        case list = "List"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header with view mode toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calendar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if !calendarManager.isEmpty {
                            Text("\(calendarManager.eventCount) events")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // View mode picker
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 140)
                    
                    // Add event button
                    Button(action: {
                        showingAddEvent = true
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
                
                // Date Picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .background(Color.CC.opacity(0.7))
                    .cornerRadius(16)
                    .padding(.horizontal)
                
                // Events View
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Events for \(selectedDate, style: .date)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if viewMode == .timeline {
                        TimelineView(
                            events: eventsForSelectedDate,
                            onDeleteEvent: { event in
                                calendarManager.removeEvent(event)
                            }
                        )
                    } else {
                        ListView(
                            events: eventsForSelectedDate,
                            onDeleteEvent: { event in
                                calendarManager.removeEvent(event)
                            }
                        )
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                CustomAddEventSheet(
                    calendarManager: calendarManager,
                    selectedDate: selectedDate
                )
            }
        }
        .onAppear {
            print(" Calendar page appeared with \(calendarManager.eventCount) events")
        }
    }
    
    private var eventsForSelectedDate: [CalendarEvent] {
        let calendar = Calendar.current
        return calendarManager.events
            .filter { event in
                calendar.isDate(event.startDate, inSameDayAs: selectedDate)
            }
            .sorted { $0.startDate < $1.startDate }
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    let events: [CalendarEvent]
    let onDeleteEvent: (CalendarEvent) -> Void
    
    private let hourHeight: CGFloat = 60
    private let startHour = 6  // 6 AM
    private let endHour = 23   // 11 PM
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Time labels and grid lines
                VStack(spacing: 0) {
                    ForEach(startHour...endHour, id: \.self) { hour in
                        HStack {
                            Text(hourString(hour))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 50, alignment: .trailing)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 1)
                        }
                        .frame(height: hourHeight)
                    }
                }
                
                // Events overlay
                ForEach(events) { event in
                    if !event.isAllDay {
                        TimelineEventView(
                            event: event,
                            hourHeight: hourHeight,
                            startHour: startHour,
                            onDelete: {
                                onDeleteEvent(event)
                            }
                        )
                    }
                }
                
                // All-day events at top
                VStack(spacing: 4) {
                    ForEach(events.filter(\.isAllDay)) { event in
                        AllDayEventView(event: event) {
                            onDeleteEvent(event)
                        }
                    }
                }
                .padding(.leading, 60)
                .padding(.bottom, 8)
            }
            .padding(.horizontal)
            
            if events.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("No events for this date")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Tap + to add your first event")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 60)
            }
        }
    }
    
    private func hourString(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - Timeline Event View
struct TimelineEventView: View {
    let event: CalendarEvent
    let hourHeight: CGFloat
    let startHour: Int
    let onDelete: () -> Void
    
    @State private var showingDetails = false
    
    var body: some View {
        let topOffset = calculateTopOffset()
        let eventHeight = calculateEventHeight()
        
        HStack(spacing: 0) {
            // Left margin for time labels
            Spacer()
                .frame(width: 60)
            
            // Event block
            Button(action: {
                showingDetails = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text("\(event.startDate, style: .time) - \(event.endDate, style: .time)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if let description = event.description, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(colorForEvent(event))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .offset(y: topOffset)
        .frame(height: eventHeight)
        .sheet(isPresented: $showingDetails) {
            EventDetailSheet(event: event)
        }
    }
    
    private func calculateTopOffset() -> CGFloat {
        let eventHour = Calendar.current.component(.hour, from: event.startDate)
        let eventMinute = Calendar.current.component(.minute, from: event.startDate)
        
        let hoursFromStart = Double(eventHour - startHour)
        let minuteOffset = Double(eventMinute) / 60.0
        
        return CGFloat((hoursFromStart + minuteOffset) * Double(hourHeight))
    }
    
    private func calculateEventHeight() -> CGFloat {
        let durationInHours = event.duration / 3600
        return max(CGFloat(durationInHours * Double(hourHeight)), 30) // Minimum 30pt height
    }
    
    private func colorForEvent(_ event: CalendarEvent) -> Color {
        switch event.category {
        case "Work":
            return Color.blue.opacity(0.8)
        case "Personal":
            return Color.green.opacity(0.8)
        case "Health":
            return Color.red.opacity(0.8)
        case "Social":
            return Color.purple.opacity(0.8)
        default:
            return Color.CC.opacity(0.8)
        }
    }
}

// MARK: - All Day Event View
struct AllDayEventView: View {
    let event: CalendarEvent
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(event.title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.8))
        .cornerRadius(8)
    }
}

// MARK: - List View (Fallback)
struct ListView: View {
    let events: [CalendarEvent]
    let onDeleteEvent: (CalendarEvent) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(events) { event in
                    EventRowView(event: event) {
                        onDeleteEvent(event)
                    }
                }
                
                if events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No events for this date")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Tap + to add your first event")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 60)
                }
            }
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Event Row View (for list mode)
struct EventRowView: View {
    let event: CalendarEvent
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body)
                    .foregroundColor(.white)
                
                if event.isAllDay {
                    Text("All Day")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("\(event.startDate, style: .time) - \(event.endDate, style: .time)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text(String(format: "%.1fh", event.durationInHours))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.CC.opacity(0.7))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Event Detail Sheet
struct EventDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let event: CalendarEvent
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(event.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        if event.isAllDay {
                            Text("All Day")
                        } else {
                            Text("\(event.startDate, style: .time) - \(event.endDate, style: .time)")
                        }
                    } icon: {
                        Image(systemName: "clock")
                    }
                    
                    Label {
                        Text(event.startDate, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    
                    if !event.isAllDay {
                        Label {
                            Text(String(format: "%.1f hours", event.durationInHours))
                        } icon: {
                            Image(systemName: "timer")
                        }
                    }
                    
                    if let category = event.category {
                        Label {
                            Text(category)
                        } icon: {
                            Image(systemName: "tag")
                        }
                    }
                }
                
                if let description = event.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(description)
                            .font(.body)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Custom Add Event Sheet
struct CustomAddEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var calendarManager: CalendarManager
    let selectedDate: Date
    
    @State private var eventTitle = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var eventDescription = ""
    @State private var selectedCategory = "General"
    @State private var isAllDay = false
    @State private var useAI = false
    @State private var aiInput = ""
    @State private var isProcessing = false
    @State private var resultMessage = ""
    
    private let categories = ["General", "Work", "Personal", "Health", "Social", "Travel"]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Toggle between manual and AI input
                Picker("Input Method", selection: $useAI) {
                    Text("Manual").tag(false)
                    Text("AI Assistant").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if useAI {
                    AIInputSection(
                        aiInput: $aiInput,
                        isProcessing: $isProcessing,
                        resultMessage: $resultMessage,
                        onCreateEvent: createEventWithAI
                    )
                } else {
                    ManualInputSection(
                        eventTitle: $eventTitle,
                        startTime: $startTime,
                        endTime: $endTime,
                        eventDescription: $eventDescription,
                        selectedCategory: $selectedCategory,
                        isAllDay: $isAllDay,
                        categories: categories,
                        selectedDate: selectedDate,
                        onCreateEvent: createEventManually
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createEventWithAI() {
        isProcessing = true
        resultMessage = ""
        
        calendarManager.addEventFromAI(aiInput) { success, message in
            isProcessing = false
            resultMessage = message
            
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
    
    private func createEventManually() {
        let calendar = Calendar.current
        
        let finalStartTime: Date
        let finalEndTime: Date
        
        if isAllDay {
            finalStartTime = calendar.startOfDay(for: selectedDate)
            finalEndTime = calendar.date(byAdding: .day, value: 1, to: finalStartTime) ?? finalStartTime
        } else {
            let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
            
            finalStartTime = calendar.date(bySettingHour: startComponents.hour ?? 0,
                                         minute: startComponents.minute ?? 0,
                                         second: 0,
                                         of: selectedDate) ?? selectedDate
            
            finalEndTime = calendar.date(bySettingHour: endComponents.hour ?? 1,
                                       minute: endComponents.minute ?? 0,
                                       second: 0,
                                       of: selectedDate) ?? selectedDate.addingTimeInterval(3600)
        }
        
        let newEvent = CalendarEvent(
            title: eventTitle,
            startDate: finalStartTime,
            endDate: finalEndTime,
            description: eventDescription.isEmpty ? nil : eventDescription,
            category: selectedCategory,
            isAllDay: isAllDay
        )
        
        calendarManager.addEvent(newEvent)
        dismiss()
    }
}

// MARK: - AI Input Section
struct AIInputSection: View {
    @Binding var aiInput: String
    @Binding var isProcessing: Bool
    @Binding var resultMessage: String
    let onCreateEvent: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Describe your event naturally")
                .font(.headline)
                .padding(.horizontal)
            
            Text("Examples: \"Meeting with John at 3pm for 2 hours\", \"Lunch tomorrow at noon\", \"Doctor appointment Friday 9am to 10am\"")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            TextEditor(text: $aiInput)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .frame(minHeight: 100)
                .disabled(isProcessing)
                .padding(.horizontal)
            
            if !resultMessage.isEmpty {
                Text(resultMessage)
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            Button(action: onCreateEvent) {
                if isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing...")
                    }
                } else {
                    Text("Create Event with AI")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(aiInput.isEmpty || isProcessing)
            .padding(.horizontal)
        }
    }
}

// MARK: - Manual Input Section
struct ManualInputSection: View {
    @Binding var eventTitle: String
    @Binding var startTime: Date
    @Binding var endTime: Date
    @Binding var eventDescription: String
    @Binding var selectedCategory: String
    @Binding var isAllDay: Bool
    let categories: [String]
    let selectedDate: Date
    let onCreateEvent: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TextField("Event title", text: $eventTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Toggle("All Day", isOn: $isAllDay)
                    .padding(.horizontal)
                
                if !isAllDay {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Time")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .padding(.horizontal)
                        
                        Text("End Time")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .padding(.horizontal)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $eventDescription)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .frame(minHeight: 80)
                        .padding(.horizontal)
                }
                
                Button("Create Event") {
                    onCreateEvent()
                }
                .buttonStyle(.borderedProminent)
                .disabled(eventTitle.isEmpty)
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    CalendarPage()
}
