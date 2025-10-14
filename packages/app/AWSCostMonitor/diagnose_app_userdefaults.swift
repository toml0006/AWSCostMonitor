import Foundation

print("=== AWS Cost Monitor UserDefaults Diagnostic ===\n")

// Check multiple potential UserDefaults sources
let standardDefaults = UserDefaults.standard
let appDefaults = UserDefaults(suiteName: "middleout.AWSCostMonitor")

print("=== USERDEFAULTS DOMAINS ===")

// Check standard defaults
print("Standard UserDefaults:")
print("- ProfileBudgets: \(standardDefaults.data(forKey: "ProfileBudgets") != nil ? "✅ Found" : "❌ Not found")")
print("- SelectedAWSProfile: \(standardDefaults.string(forKey: "SelectedAWSProfile") ?? "Not set")")
print("- AutoRefreshEnabled: \(standardDefaults.object(forKey: "AutoRefreshEnabled") as? Bool ?? false)")
print("- HasCompletedOnboarding: \(standardDefaults.object(forKey: "HasCompletedOnboarding") as? Bool ?? false)")

// Check app-specific defaults
if let appDefaults = appDefaults {
    print("\nApp-specific UserDefaults (middleout.AWSCostMonitor):")
    print("- ProfileBudgets: \(appDefaults.data(forKey: "ProfileBudgets") != nil ? "✅ Found" : "❌ Not found")")
    print("- SelectedAWSProfile: \(appDefaults.string(forKey: "SelectedAWSProfile") ?? "Not set")")
    print("- AutoRefreshEnabled: \(appDefaults.object(forKey: "AutoRefreshEnabled") as? Bool ?? false)")
    print("- HasCompletedOnboarding: \(appDefaults.object(forKey: "HasCompletedOnboarding") as? Bool ?? false)")
}

// Use defaults command-line tool to check the app's preferences directly
print("\n=== SYSTEM PREFERENCES ANALYSIS ===")

// Function to run shell command and get output
func runCommand(_ command: String) -> String? {
    let process = Process()
    let pipe = Pipe()
    
    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = ["-c", command]
    process.launchPath = "/bin/zsh"
    
    do {
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return output
    } catch {
        return nil
    }
}

// Check if app preferences exist in the system
if let prefsOutput = runCommand("defaults read middleout.AWSCostMonitor 2>/dev/null") {
    print("✅ Found app preferences in system:")
    print(prefsOutput)
} else {
    print("❌ No app preferences found in system defaults")
}

// Check for any preferences containing "AWSCost" or similar
if let searchOutput = runCommand("defaults domains | tr ',' '\\n' | grep -i aws") {
    print("\n✅ Found AWS-related domains:")
    print(searchOutput)
} else {
    print("\n❌ No AWS-related domains found")
}

print("\n=== TIMER ANALYSIS ===")

// Check if the app is running
if let runningApps = runCommand("ps aux | grep -i awscost | grep -v grep") {
    print("✅ App processes found:")
    print(runningApps)
} else {
    print("❌ No AWS Cost Monitor processes found - app might not be running")
}

// Check for any background timers or dispatch queues
if let bgProcesses = runCommand("ps aux | grep -E '(dispatch|timer|refresh)' | grep -i aws") {
    print("\n✅ Background processes:")
    print(bgProcesses)
} else {
    print("\n❌ No background timer processes found")
}

print("\n=== RECOMMENDATIONS ===")
print("1. Ensure the AWS Cost Monitor app is actually running")
print("2. Complete the onboarding process if not already done")
print("3. Check if the app is using a different bundle identifier or UserDefaults suite")
print("4. Verify timer implementation is not being prevented by macOS power management")