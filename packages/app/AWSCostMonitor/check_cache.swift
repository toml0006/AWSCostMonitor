import Foundation

// Read UserDefaults for the app
let defaults = UserDefaults(suiteName: "group.awscostmonitor") ?? UserDefaults.standard

// Check various keys
if let cacheData = defaults.data(forKey: "CostCache") {
    print("Cache data size: \(cacheData.count) bytes")
    
    // Try to decode and check age
    if let jsonObject = try? JSONSerialization.jsonObject(with: cacheData, options: []) as? [String: Any] {
        for (profile, data) in jsonObject {
            if let cache = data as? [String: Any],
               let fetchDate = cache["fetchDate"] as? String {
                print("Profile '\(profile)' - Last fetch: \(fetchDate)")
                
                // Parse the date and calculate age
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: fetchDate) {
                    let age = Date().timeIntervalSince(date)
                    print("  Cache age: \(Int(age/60)) minutes (\(Int(age/3600)) hours)")
                }
            }
        }
    }
}

// Check refresh interval
if let budgetData = defaults.data(forKey: "ProfileBudgets") {
    if let budgets = try? JSONSerialization.jsonObject(with: budgetData, options: []) as? [String: Any] {
        for (profile, budget) in budgets {
            if let b = budget as? [String: Any],
               let interval = b["refreshIntervalMinutes"] as? Int {
                print("Profile '\(profile)' - Refresh interval: \(interval) minutes (\(interval/60) hours)")
            }
        }
    }
}

// Check selected profile
if let selectedProfile = defaults.string(forKey: "SelectedAWSProfile") {
    print("Selected profile: \(selectedProfile)")
}

// Check last API calls
if let apiData = defaults.data(forKey: "APIRequestRecords") {
    if let records = try? JSONSerialization.jsonObject(with: apiData, options: []) as? [[String: Any]] {
        print("\nRecent API calls:")
        for record in records.suffix(5) {
            if let timestamp = record["timestamp"] as? String,
               let profile = record["profileName"] as? String,
               let success = record["success"] as? Bool {
                print("  \(profile): \(timestamp) - Success: \(success)")
            }
        }
    }
}
