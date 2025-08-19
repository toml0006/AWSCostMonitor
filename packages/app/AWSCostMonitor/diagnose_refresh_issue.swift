import Foundation

print("=== AWS Cost Monitor Refresh Issue Diagnostic ===\n")

// Check UserDefaults for the app
let defaults = UserDefaults.standard

print("=== CONFIGURATION STATUS ===")

// Check ProfileBudgets
if let budgetData = defaults.data(forKey: "ProfileBudgets") {
    print("✅ ProfileBudgets found")
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
                }
            }
        }
    } catch {
        print("❌ Error parsing budgets: \(error)")
    }
} else {
    print("❌ No ProfileBudgets found - this is a critical issue!")
    print("   The app needs profile budgets to function properly.")
}

// Check selected profile
print("\n=== PROFILE STATUS ===")
if let selectedProfile = defaults.string(forKey: "SelectedAWSProfile") {
    print("✅ Selected profile: \(selectedProfile)")
} else {
    print("❌ No selected profile - this prevents refresh from working!")
}

// Check auto-refresh setting
print("\n=== AUTO-REFRESH STATUS ===")
if let autoRefresh = defaults.object(forKey: "AutoRefreshEnabled") as? Bool {
    print("Auto-refresh enabled: \(autoRefresh ? "Yes" : "No")")
    if !autoRefresh {
        print("❌ Auto-refresh is disabled - this is why updates aren't happening!")
    }
} else {
    print("❌ Auto-refresh setting not found - defaulting to disabled")
}

// Check cache
print("\n=== CACHE STATUS ===")
if let cacheData = defaults.data(forKey: "CostCache") {
    print("✅ Cost cache found")
    do {
        if let jsonObject = try JSONSerialization.jsonObject(with: cacheData, options: []) as? [String: Any] {
            for (profile, cache) in jsonObject {
                print("\nProfile: \(profile)")
                if let c = cache as? [String: Any] {
                    if let fetchDate = c["fetchDate"] as? String {
                        print("  Last fetch: \(fetchDate)")
                        
                        // Parse the date and calculate age
                        let formatter = ISO8601DateFormatter()
                        if let date = formatter.date(from: fetchDate) {
                            let age = Date().timeIntervalSince(date)
                            let ageMinutes = Int(age / 60)
                            let ageHours = ageMinutes / 60
                            
                            print("  Age: \(ageHours)h \(ageMinutes % 60)m")
                            
                            if age > 480 * 60 { // 8 hours
                                print("  ⚠️  Cache is very old - should have refreshed by now!")
                            }
                        }
                    }
                }
            }
        }
    } catch {
        print("❌ Error parsing cache: \(error)")
    }
} else {
    print("❌ No cost cache found - app may not have fetched data yet")
}

// Check for any error messages
print("\n=== ERROR STATUS ===")
if let errorMessage = defaults.string(forKey: "LastErrorMessage") {
    print("❌ Last error: \(errorMessage)")
} else {
    print("✅ No recent errors")
}

// Check if app has completed onboarding
print("\n=== ONBOARDING STATUS ===")
if let hasCompletedOnboarding = defaults.object(forKey: "HasCompletedOnboarding") as? Bool {
    print("Onboarding completed: \(hasCompletedOnboarding ? "Yes" : "No")")
    if !hasCompletedOnboarding {
        print("❌ App hasn't completed onboarding - this prevents proper configuration!")
    }
} else {
    print("❌ Onboarding status unknown")
}

// Check system sleep/wake events
print("\n=== SYSTEM STATUS ===")
let now = Date()
let calendar = Calendar.current
let lastMidnight = calendar.startOfDay(for: now)
let hoursSinceMidnight = calendar.dateComponents([.hour], from: lastMidnight, to: now).hour ?? 0
print("Current time: \(now)")
print("Hours since midnight: \(hoursSinceMidnight)")

// Check if we're in a reasonable time window for AWS updates
// AWS typically updates billing data around 2-4 AM, 10 AM-12 PM, and 6-8 PM
let isReasonableTime = (2...4).contains(hoursSinceMidnight) || 
                      (10...12).contains(hoursSinceMidnight) || 
                      (18...20).contains(hoursSinceMidnight)

print("Reasonable time for AWS update: \(isReasonableTime ? "Yes" : "No")")

print("\n=== RECOMMENDATIONS ===")

if defaults.data(forKey: "ProfileBudgets") == nil {
    print("1. ❌ CRITICAL: Complete app onboarding to set up profile budgets")
    print("   - Open the app and go through the setup process")
    print("   - Set a monthly budget and refresh interval")
}

if defaults.string(forKey: "SelectedAWSProfile") == nil {
    print("2. ❌ CRITICAL: Select an AWS profile")
    print("   - Open app settings and choose a profile")
}

if let autoRefresh = defaults.object(forKey: "AutoRefreshEnabled") as? Bool, !autoRefresh {
    print("3. ❌ CRITICAL: Enable auto-refresh")
    print("   - Go to Settings > Refresh Rate and turn on auto-refresh")
}

if let hasCompletedOnboarding = defaults.object(forKey: "HasCompletedOnboarding") as? Bool, !hasCompletedOnboarding {
    print("4. ❌ CRITICAL: Complete app onboarding")
    print("   - The app needs initial configuration to work properly")
}

print("\n=== NEXT STEPS ===")
print("1. Open the AWS Cost Monitor app")
print("2. Complete the onboarding process if prompted")
print("3. Go to Settings > Refresh Rate and ensure auto-refresh is enabled")
print("4. Set a refresh interval (8 hours is recommended for AWS billing updates)")
print("5. Select an AWS profile in Settings > Profiles")
print("6. Restart the app to ensure all settings are applied")

print("\n=== TECHNICAL NOTES ===")
print("- AWS billing data typically updates 2-3 times per day")
print("- The app uses screen state monitoring to pause refresh when inactive")
print("- Refresh intervals are profile-specific and stored in ProfileBudgets")
print("- The app should automatically resume refresh after system wake events")
