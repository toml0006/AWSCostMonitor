import Foundation

// Function to find and read plist files
func findAndReadPreferences() {
    let fm = FileManager.default
    let homeDir = fm.homeDirectoryForCurrentUser
    
    // Common locations for app preferences
    var paths = [
        homeDir.appendingPathComponent("Library/Preferences/com.awscostmonitor.app.plist"),
        homeDir.appendingPathComponent("Library/Containers/com.awscostmonitor.app/Data/Library/Preferences/com.awscostmonitor.app.plist"),
        homeDir.appendingPathComponent("Library/Group Containers/group.awscostmonitor/Library/Preferences/group.awscostmonitor.plist")
    ]
    
    for path in paths {
        if fm.fileExists(atPath: path.path) {
            print("Found preferences at: \(path.path)")
            
            if let dict = NSDictionary(contentsOf: path) {
                print("\n=== PREFERENCES CONTENT ===")
                
                // Check for cache
                if let cacheData = dict["CostCache"] as? Data {
                    print("\nCache data size: \(cacheData.count) bytes")
                    if let jsonObject = try? JSONSerialization.jsonObject(with: cacheData, options: []) as? [String: Any] {
                        for (profile, data) in jsonObject {
                            print("\nProfile: \(profile)")
                            if let cache = data as? [String: Any] {
                                if let fetchDate = cache["fetchDate"] as? String {
                                    print("  Last fetch: \(fetchDate)")
                                    
                                    let formatter = ISO8601DateFormatter()
                                    if let date = formatter.date(from: fetchDate) {
                                        let age = Date().timeIntervalSince(date)
                                        print("  Cache age: \(Int(age/60)) minutes (\(String(format: "%.1f", age/3600)) hours)")
                                        print("  >>> STALE (>6 hours): \(age > 21600)")
                                    }
                                }
                                if let mtdTotal = cache["mtdTotal"] as? Double {
                                    print("  MTD Total: $\(String(format: "%.2f", mtdTotal))")
                                }
                            }
                        }
                    }
                }
                
                // Check for selected profile
                if let selected = dict["SelectedAWSProfile"] as? String {
                    print("\nSelected Profile: \(selected)")
                }
                
                // Check for budgets
                if let budgetData = dict["ProfileBudgets"] as? Data {
                    if let budgets = try? JSONSerialization.jsonObject(with: budgetData, options: []) as? [String: Any] {
                        print("\n=== PROFILE BUDGETS ===")
                        for (profile, budget) in budgets {
                            print("\nProfile: \(profile)")
                            if let b = budget as? [String: Any] {
                                if let interval = b["refreshIntervalMinutes"] as? Int {
                                    print("  Refresh interval: \(interval) minutes (\(interval/60) hours)")
                                }
                            }
                        }
                    }
                }
                
                // Check auto-refresh setting
                if let autoRefresh = dict["AutoRefreshEnabled"] as? Bool {
                    print("\nAuto-refresh enabled: \(autoRefresh)")
                }
            }
            return
        }
    }
    
    print("No preferences file found. Checking current app state via direct UserDefaults...")
    
    // Try direct UserDefaults access
    let defaults = UserDefaults.standard
    print("\n=== Direct UserDefaults Check ===")
    
    if let selected = defaults.string(forKey: "SelectedAWSProfile") {
        print("Selected Profile: \(selected)")
    }
    
    if defaults.object(forKey: "AutoRefreshEnabled") \!= nil {
        print("Auto-refresh: \(defaults.bool(forKey: "AutoRefreshEnabled"))")
    }
    
    print("\nAll UserDefaults keys:")
    for (key, value) in defaults.dictionaryRepresentation() {
        if key.lowercased().contains("aws") || key.lowercased().contains("cost") || key.lowercased().contains("cache") {
            print("  \(key): \(type(of: value))")
        }
    }
}

findAndReadPreferences()
