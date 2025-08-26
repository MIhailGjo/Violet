//
//  TouchLaterStorage.swift
//  Violet
//
//  Created by Mihail Gjoni on 8/17/25.
//

import Foundation

class TouchLaterStorage {
    static let shared = TouchLaterStorage()
    
    private init() {} // Singleton
    
    private let storageKey = "touchLaterItems"
    
    // Save Touch Later items to device
    func save(_ items: [TouchItem]) {
        do {
            let encoded = try JSONEncoder().encode(items)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            print("✅ Touch Later items saved successfully")
        } catch {
            print("❌ Failed to save Touch Later items: \(error)")
        }
    }
    
    // Load Touch Later items from device
    func load() -> [TouchItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("📱 No Touch Later items found - starting fresh")
            return []
        }
        
        do {
            let items = try JSONDecoder().decode([TouchItem].self, from: data)
            print("✅ Loaded \(items.count) Touch Later items")
            return items
        } catch {
            print("❌ Failed to load Touch Later items: \(error)")
            return []
        }
    }
    
    // Clear all Touch Later items
    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🗑️ Touch Later items cleared")
    }
    
    // Check if any items are saved
    func hasItems() -> Bool {
        return UserDefaults.standard.data(forKey: storageKey) != nil
    }
}
