//
//  AIService.swift
//  Violet
//
//  Created by Mihail Gjoni on 7/20/25.
//

import Foundation

class AIService {
    static let shared = AIService()
    private init() {}
    
    // Load API key from plist file with multiple name attempts
    private let apiKey: String = {
        // Try different variations of the filename
        let possibleNames = ["Secrets", "secrets", "Secret", "secret"]
        var path: String?
        
        for name in possibleNames {
            path = Bundle.main.path(forResource: name, ofType: "plist")
            if path != nil {
                print("✅ Found plist file: \(name).plist")
                break
            }
        }
        
        // If still not found, try without extension
        if path == nil {
            for name in possibleNames {
                path = Bundle.main.path(forResource: name, ofType: nil)
                if path != nil {
                    print("✅ Found file: \(name)")
                    break
                }
            }
        }
        
        guard let filePath = path else {
            print("❌ Error: Could not find plist file with any of these names: \(possibleNames)")
            print("📁 Bundle contents:")
            if let bundlePath = Bundle.main.resourcePath {
                do {
                    let files = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                    for file in files.prefix(10) { // Show first 10 files
                        print("  - \(file)")
                    }
                } catch {
                    print("  Could not list bundle contents")
                }
            }
            fatalError("Could not find secrets file. Make sure it's added to your Xcode project target.")
        }
        
        guard let plist = NSDictionary(contentsOfFile: filePath) else {
            print("❌ Error: Could not read plist file at: \(filePath)")
            fatalError("Could not read plist file. Check the file format.")
        }
        
        guard let key = plist["OPENAI_API_KEY"] as? String, !key.isEmpty else {
            print("❌ Error: OPENAI_API_KEY not found or empty")
            print("📋 Available keys in plist: \(plist.allKeys)")
            fatalError("Could not find OPENAI_API_KEY in plist. Make sure the key exists and has a value.")
        }
        
        print("✅ Successfully loaded OpenAI API key from plist")
        return key
    }()
    
    enum AIError: Error {
        case invalidURL
        case noData
        case invalidResponse
        case apiError(String)
    }
    
    enum ClassificationResult {
        case calendar
        case touchLater
        case error(String)
        
        var stringValue: String {
            switch self {
            case .calendar: return "CALENDAR"
            case .touchLater: return "TOUCH LATER"
            case .error(let message): return "ERROR: \(message)"
            }
        }
    }
    
    struct ParsedCalendarEvent {
        let title: String
        let startDate: Date
        let endDate: Date
        let description: String?
        let category: String?
        let isAllDay: Bool
        let confidence: Double
    }
    
    func classifyUserInput(_ input: String, completion: @escaping (ClassificationResult) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.error("Invalid URL"))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        You are an assistant for a productivity app. Analyze the user input and classify it as one of the following:
        
        - CALENDAR: Time-specific activities, meetings, appointments, scheduled tasks, events with dates/times, or anything that should go on a calendar
        - TOUCH: Unclear, vague, incomplete thoughts, ideas that need more thinking, or tasks without specific timing
        
        Examples:
        - "Buy groceries tomorrow" → CALENDAR
        - "Meeting at 3pm" → CALENDAR
        - "Call mom at 5pm today" → CALENDAR
        - "Dentist appointment next Friday 2-3pm" → CALENDAR
        - "Lunch break 12:30 to 1:30" → CALENDAR
        - "Conference call Monday 9am for 2 hours" → CALENDAR
        - "Remember something" → TOUCH
        - "Project ideas to think about" → TOUCH
        - "Something important" → TOUCH
        - "Need to plan vacation" → TOUCH
        - "Random thought about work" → TOUCH
        
        User input: "\(input)"
        
        Respond with exactly one word: CALENDAR or TOUCH
        """
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a productivity assistant that classifies user input."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1,
            "max_tokens": 10
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.error("Failed to serialize request"))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.error("Network error: \(error.localizedDescription)"))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.error("Invalid response"))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    completion(.error("API error: Status code \(httpResponse.statusCode)"))
                    return
                }
                
                guard let data = data else {
                    completion(.error("No data received"))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        let classification = content.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        
                        switch classification {
                        case "CALENDAR":
                            completion(.calendar)
                        case "TOUCH":
                            completion(.touchLater)
                        default:
                            // Fallback logic for unexpected responses
                            if classification.contains("CALENDAR") || classification.contains("EVENT") {
                                completion(.calendar)
                            } else {
                                completion(.touchLater)
                            }
                        }
                    } else {
                        completion(.error("Failed to parse response"))
                    }
                } catch {
                    completion(.error("JSON parsing error: \(error.localizedDescription)"))
                }
            }
        }.resume()
    }
    
    // Enhanced calendar event parsing for timeline calendar
    func parseCalendarEvent(from input: String, completion: @escaping (ParsedCalendarEvent?) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: currentDate)
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        let todayWeekday = weekdayFormatter.string(from: currentDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let currentTimeString = timeFormatter.string(from: currentDate)
        
        let prompt = """
        Parse this text into a detailed calendar event. Today is \(todayWeekday), \(todayString) at \(currentTimeString).
        
        Text: "\(input)"
        
        Extract and format as JSON:
        {
            "title": "Event title (required)",
            "startDate": "YYYY-MM-DD",
            "startTime": "HH:MM (24hr format)",
            "endDate": "YYYY-MM-DD", 
            "endTime": "HH:MM (24hr format)",
            "duration": 60,
            "isAllDay": false,
            "category": "Work|Personal|Health|Social|General",
            "description": "Additional details or null",
            "confidence": 0.9
        }
        
        Rules for parsing:
        1. DATES:
           - No date specified → use today
           - "tomorrow" → use tomorrow's date
           - "next [day]" → calculate that date from today
           - "Friday", "Monday" etc → next occurrence of that weekday
           - "next week" → 7 days from today
        
        2. TIMES & DURATION:
           - No time specified → default to 2 hours starting at next reasonable time
           - "morning" → 09:00, "afternoon" → 14:00, "evening" → 18:00, "night" → 20:00
           - "lunch" → 12:00-13:00, "dinner" → 18:00-19:30
           - "all day" → set isAllDay: true
           - Extract duration from phrases like "2 hour meeting", "30 minute call"
           - Default duration: meetings=60min, calls=30min, meals=60-90min, appointments=60min
        
        3. CATEGORIES:
           - "meeting", "conference", "presentation" → Work
           - "doctor", "gym", "workout", "medical" → Health  
           - "dinner", "lunch", "party", "friends" → Social
           - "family", "personal", "shopping", "errands" → Personal
           - Everything else → General
        
        4. CONFIDENCE:
           - 0.9 = very clear time/date/duration
           - 0.7 = some details clear, some assumed
           - 0.5 = mostly assumed/guessed
        
        Examples:
        "Team meeting tomorrow 2-4pm" → 
        {
            "title": "Team meeting",
            "startDate": "2025-07-30",
            "startTime": "14:00",
            "endDate": "2025-07-30", 
            "endTime": "16:00",
            "duration": 120,
            "isAllDay": false,
            "category": "Work",
            "description": null,
            "confidence": 0.9
        }
        
        "Lunch with Sarah" →
        {
            "title": "Lunch with Sarah",
            "startDate": "\(todayString)",
            "startTime": "12:00",
            "endDate": "\(todayString)",
            "endTime": "13:00", 
            "duration": 60,
            "isAllDay": false,
            "category": "Social",
            "description": null,
            "confidence": 0.7
        }
        
        "All day conference Friday" →
        {
            "title": "Conference",
            "startDate": "next Friday's date",
            "startTime": "09:00",
            "endDate": "next Friday's date",
            "endTime": "17:00",
            "duration": 480,
            "isAllDay": true,
            "category": "Work", 
            "description": null,
            "confidence": 0.8
        }
        
        Return only valid JSON, no other text.
        """
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1,
            "max_tokens": 300
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let message = choices.first?["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    completion(nil)
                    return
                }
                
                // Parse the JSON response
                if let eventData = content.data(using: .utf8),
                   let eventJson = try? JSONSerialization.jsonObject(with: eventData) as? [String: Any],
                   let title = eventJson["title"] as? String {
                    
                    // Parse start date and time
                    let startDate = self.parseFullDateTime(
                        dateString: eventJson["startDate"] as? String,
                        timeString: eventJson["startTime"] as? String
                    ) ?? Date()
                    
                    // Parse end date and time
                    let endDate = self.parseFullDateTime(
                        dateString: eventJson["endDate"] as? String,
                        timeString: eventJson["endTime"] as? String
                    ) ?? startDate.addingTimeInterval(3600) // Default 1 hour
                    
                    let parsedEvent = ParsedCalendarEvent(
                        title: title,
                        startDate: startDate,
                        endDate: endDate,
                        description: eventJson["description"] as? String,
                        category: eventJson["category"] as? String ?? "General",
                        isAllDay: eventJson["isAllDay"] as? Bool ?? false,
                        confidence: eventJson["confidence"] as? Double ?? 0.5
                    )
                    
                    completion(parsedEvent)
                } else {
                    // Fallback: create a simple event if JSON parsing fails
                    let fallbackEvent = ParsedCalendarEvent(
                        title: input,
                        startDate: Date().addingTimeInterval(3600), // 1 hour from now
                        endDate: Date().addingTimeInterval(7200),   // 2 hours from now
                        description: "Parsed from: \(input)",
                        category: "General",
                        isAllDay: false,
                        confidence: 0.3
                    )
                    completion(fallbackEvent)
                }
            }
        }.resume()
    }
    
    private func parseFullDateTime(dateString: String?, timeString: String?) -> Date? {
        guard let dateStr = dateString else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: dateStr) else { return nil }
        
        guard let timeStr = timeString else { return date }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        guard let time = timeFormatter.date(from: timeStr) else { return date }
        
        // Combine date and time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                           minute: timeComponents.minute ?? 0,
                           second: 0,
                           of: date) ?? date
    }
    
    private func parseDate(from dateString: Any?) -> Date? {
        guard let dateStr = dateString as? String else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateStr)
    }
    
    private func parseTime(from timeString: Any?) -> Date? {
        guard let timeStr = timeString as? String else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeStr)
    }
}
