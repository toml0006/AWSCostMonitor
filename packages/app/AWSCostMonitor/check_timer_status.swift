import Foundation

print("=== Checking Timer Status ===\n")

// Get the current time for reference
let now = Date()
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
print("Current time: \(formatter.string(from: now))")

// Check if the app is running
func checkAppRunning() -> Bool {
    let process = Process()
    let pipe = Pipe()
    
    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = ["-c", "ps aux | grep -i AWSCostMonitor | grep -v grep"]
    process.launchPath = "/bin/zsh"
    
    do {
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return !(output?.isEmpty ?? true)
    } catch {
        return false
    }
}

let isAppRunning = checkAppRunning()
print("App Status: \(isAppRunning ? "✅ Running" : "❌ Not Running")")

if isAppRunning {
    print("\n=== Configuration Check ===")
    
    // Check auto-refresh setting
    let autoRefresh = UserDefaults(suiteName: "middleout.AWSCostMonitor")?.bool(forKey: "AutoRefreshEnabled") ?? false
    print("AutoRefreshEnabled: \(autoRefresh ? "✅ True" : "❌ False")")
    
    // Check selected profile
    let selectedProfile = UserDefaults(suiteName: "middleout.AWSCostMonitor")?.string(forKey: "SelectedAWSProfileName") ?? "None"
    print("Selected Profile: \(selectedProfile)")
    
    // Get refresh interval from profile budgets
    if let budgetData = UserDefaults(suiteName: "middleout.AWSCostMonitor")?.data(forKey: "ProfileBudgets") {
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: budgetData, options: []) as? [String: Any],
               let profileBudget = jsonObject[selectedProfile] as? [String: Any],
               let refreshInterval = profileBudget["refreshIntervalMinutes"] as? Int {
                print("Refresh Interval: \(refreshInterval) minutes (\(Double(refreshInterval)/60.0) hours)")
                
                // Calculate next expected refresh
                let intervalSeconds = TimeInterval(refreshInterval * 60)
                let nextRefresh = now.addingTimeInterval(intervalSeconds)
                print("If timer started now, next refresh would be at: \(formatter.string(from: nextRefresh))")
            }
        } catch {
            print("Error parsing budget data: \(error)")
        }
    }
    
    // Check last cost cache update
    if let cacheData = UserDefaults(suiteName: "middleout.AWSCostMonitor")?.data(forKey: "CostCacheData") {
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: cacheData, options: []) as? [String: Any],
               let profileCache = jsonObject[selectedProfile] as? [String: Any],
               let fetchDateString = profileCache["fetchDate"] as? String {
                
                let isoFormatter = ISO8601DateFormatter()
                if let fetchDate = isoFormatter.date(from: fetchDateString) {
                    let timeSinceLastUpdate = now.timeIntervalSince(fetchDate)
                    let minutesSince = Int(timeSinceLastUpdate / 60)
                    let hoursSince = minutesSince / 60
                    
                    print("Last data update: \(formatter.string(from: fetchDate))")
                    print("Time since last update: \(hoursSince)h \(minutesSince % 60)m")
                    
                    if timeSinceLastUpdate > 3600 { // More than 1 hour
                        print("⚠️  Data is \(hoursSince) hours old - should refresh automatically")
                    } else {
                        print("✅ Data is relatively fresh")
                    }
                }
            }
        } catch {
            print("Error parsing cache data: \(error)")
        }
    }
    
    print("\n=== Monitoring Instructions ===")
    print("1. Wait 2-5 minutes for the timer startup delay")
    print("2. Do NOT click the menu bar - let it update automatically")
    print("3. Check Console.app for 'AsyncRefresh' or 'Starting automatic refresh' messages")
    print("4. If configured for 8 hours, you'll need to wait or set a shorter interval for testing")
    print("5. You can set a shorter test interval in the app settings")
    
    print("\n💡 To test faster:")
    print("   - Open the app settings")
    print("   - Set refresh interval to 5-10 minutes")
    print("   - Restart the app")
    print("   - Watch for automatic updates")
    
} else {
    print("❌ App is not running. Please launch it first.")
}