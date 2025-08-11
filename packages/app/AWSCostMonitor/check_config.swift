import Foundation

// Try to read UserDefaults for the app
let defaults = UserDefaults.standard

// Check ProfileBudgets
if let budgetData = defaults.data(forKey: "ProfileBudgets") {
    print("=== PROFILE BUDGETS ===")
    do {
        if let jsonObject = try JSONSerialization.jsonObject(with: budgetData, options: []) as? [String: Any] {
            for (profile, budget) in jsonObject {
                print("\nProfile: \(profile)")
                if let b = budget as? [String: Any] {
                    if let interval = b["refreshIntervalMinutes"] as? Int {
                        print("  Refresh interval: \(interval) minutes (\(interval/60) hours)")
                    }
                    if let monthlyBudget = b["monthlyBudget"] as? Double {
                        print("  Monthly budget: $\(monthlyBudget)")
                    }
                    if let alertThreshold = b["alertThreshold"] as? Double {
                        print("  Alert threshold: \(alertThreshold * 100)%")
                    }
                }
            }
        }
    } catch {
        print("Error parsing budgets: \(error)")
    }
} else {
    print("No ProfileBudgets found in UserDefaults")
}

// Check selected profile
print("\n=== SELECTED PROFILE ===")
if let selectedProfile = defaults.string(forKey: "SelectedAWSProfile") {
    print("Selected profile: \(selectedProfile)")
} else {
    print("No selected profile")
}

// Check refresh interval setting
print("\n=== REFRESH SETTINGS ===")
if let refreshInterval = defaults.object(forKey: "RefreshInterval") as? Int {
    print("Global refresh interval: \(refreshInterval) minutes")
} else {
    print("No global refresh interval set")
}

// Check auto-refresh setting
if let autoRefresh = defaults.object(forKey: "AutoRefreshEnabled") as? Bool {
    print("Auto-refresh enabled: \(autoRefresh)")
}

// Check cache
print("\n=== CACHE STATUS ===")
if let cacheData = defaults.data(forKey: "CostCache") {
    do {
        if let jsonObject = try JSONSerialization.jsonObject(with: cacheData, options: []) as? [String: Any] {
            for (profile, data) in jsonObject {
                print("\nProfile: \(profile)")
                if let cache = data as? [String: Any],
                   let fetchDate = cache["fetchDate"] as? String {
                    print("  Last fetch: \(fetchDate)")
                    
                    // Parse the date and calculate age
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: fetchDate) {
                        let age = Date().timeIntervalSince(date)
                        print("  Cache age: \(Int(age/60)) minutes (\(String(format: "%.1f", age/3600)) hours)")
                    }
                }
            }
        }
    } catch {
        print("Error parsing cache: \(error)")
    }
} else {
    print("No cache data found")
}
