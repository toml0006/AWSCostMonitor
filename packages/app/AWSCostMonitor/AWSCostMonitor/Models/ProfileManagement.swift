//
//  ProfileManagement.swift
//  AWSCostMonitor
//
//  Profile management and visibility settings
//

import Foundation

// MARK: - Profile Visibility Settings

struct ProfileVisibilitySettings: Codable {
    var visibleProfiles: Set<String> = []
    var hiddenProfiles: Set<String> = []
    var removedProfiles: [String: RemovedProfileInfo] = [:]
    var lastScanDate: Date?
    var hasCompletedInitialSetup: Bool = false
    
    // Initialize with all profiles visible by default
    init() {
        self.lastScanDate = Date()
        self.hasCompletedInitialSetup = false
    }
}

struct RemovedProfileInfo: Codable {
    let profileName: String
    let lastSeenDate: Date
    let preserveData: Bool
    
    init(profileName: String, lastSeenDate: Date = Date(), preserveData: Bool = true) {
        self.profileName = profileName
        self.lastSeenDate = lastSeenDate
        self.preserveData = preserveData
    }
}

// MARK: - Profile Change Detection

struct ProfileChanges {
    let newProfiles: [AWSProfile]
    let removedProfiles: [String]
    let existingProfiles: [AWSProfile]
}

// MARK: - Profile Management Helper

class ProfileManager {
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "ProfileVisibilitySettings"
    private let legacyMigrationKey = "LegacyProfileVisibilityMigrated"

    // Load visibility settings. Runs a one-time merge from the legacy
    // (pre-sandbox) preferences plist so profiles known before sandboxing
    // aren't re-flagged as "new" every launch.
    func loadSettings() -> ProfileVisibilitySettings {
        migrateFromLegacyPlistIfNeeded()
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(ProfileVisibilitySettings.self, from: data) else {
            return ProfileVisibilitySettings()
        }
        return settings
    }

    // Merge the unsandboxed ~/Library/Preferences/<bundle-id>.plist
    // ProfileVisibilitySettings into the sandbox-container defaults. Runs once.
    // Best-effort: if the legacy plist is unreadable (sandbox denial, missing,
    // corrupt), we silently flip the migration flag so startup can proceed.
    private func migrateFromLegacyPlistIfNeeded() {
        if userDefaults.bool(forKey: legacyMigrationKey) { return }
        defer { userDefaults.set(true, forKey: legacyMigrationKey) }

        let bundleID = Bundle.main.bundleIdentifier ?? "middleout.AWSCostMonitor"

        // Resolve the real home even when sandboxed (NSHomeDirectory returns
        // the container; we need the user's actual home).
        let realHome: String
        if let user = getpwuid(getuid()), let homeDir = user.pointee.pw_dir {
            realHome = String(cString: homeDir)
        } else {
            realHome = NSHomeDirectory()
        }
        let legacyURL = URL(fileURLWithPath: realHome)
            .appendingPathComponent("Library/Preferences/\(bundleID).plist")

        guard FileManager.default.fileExists(atPath: legacyURL.path),
              let plistData = try? Data(contentsOf: legacyURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let legacyBlob = plist["ProfileVisibilitySettings"] as? Data,
              let legacy = try? JSONDecoder().decode(ProfileVisibilitySettings.self, from: legacyBlob)
        else { return }

        var current: ProfileVisibilitySettings
        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(ProfileVisibilitySettings.self, from: data) {
            current = decoded
        } else {
            current = ProfileVisibilitySettings()
        }

        // Merge: legacy-visible wins over unknown, but never unhide a profile
        // the user has explicitly hidden in the current sandbox settings, and
        // never resurrect a profile marked removed in the current settings.
        for name in legacy.visibleProfiles
            where !current.hiddenProfiles.contains(name)
               && current.removedProfiles[name] == nil {
            current.visibleProfiles.insert(name)
        }
        for name in legacy.hiddenProfiles
            where !current.visibleProfiles.contains(name)
               && current.removedProfiles[name] == nil {
            current.hiddenProfiles.insert(name)
        }
        current.hasCompletedInitialSetup = true

        if let encoded = try? JSONEncoder().encode(current) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    // Save visibility settings
    func saveSettings(_ settings: ProfileVisibilitySettings) {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
    
    // Check for profile changes
    func detectProfileChanges(currentProfiles: [AWSProfile]) -> ProfileChanges {
        let settings = loadSettings()
        let currentProfileNames = Set(currentProfiles.map { $0.name })
        
        // Find all previously known profiles (visible + hidden + removed)
        var previouslyKnownProfiles = settings.visibleProfiles.union(settings.hiddenProfiles)
        previouslyKnownProfiles.formUnion(settings.removedProfiles.keys)
        
        // Detect new profiles
        let newProfileNames = currentProfileNames.subtracting(previouslyKnownProfiles)
        let newProfiles = currentProfiles.filter { newProfileNames.contains($0.name) }
        
        // Detect removed profiles (were known but not in current config)
        let removedProfileNames = previouslyKnownProfiles.subtracting(currentProfileNames)
            .subtracting(settings.removedProfiles.keys) // Don't re-detect already removed profiles
        
        // Existing profiles
        let existingProfiles = currentProfiles.filter { !newProfileNames.contains($0.name) }
        
        return ProfileChanges(
            newProfiles: newProfiles,
            removedProfiles: Array(removedProfileNames),
            existingProfiles: existingProfiles
        )
    }
    
    // Add new profiles as visible
    func addNewProfiles(_ profileNames: [String]) {
        var settings = loadSettings()
        for name in profileNames {
            settings.visibleProfiles.insert(name)
            settings.hiddenProfiles.remove(name)
        }
        settings.lastScanDate = Date()
        saveSettings(settings)
    }
    
    // Mark profiles as removed
    func markProfilesAsRemoved(_ profileNames: [String], preserveData: Bool) {
        var settings = loadSettings()
        for name in profileNames {
            settings.removedProfiles[name] = RemovedProfileInfo(
                profileName: name,
                lastSeenDate: settings.lastScanDate ?? Date(),
                preserveData: preserveData
            )
            settings.visibleProfiles.remove(name)
            settings.hiddenProfiles.remove(name)
        }
        saveSettings(settings)
    }
    
    // Toggle profile visibility
    func toggleProfileVisibility(_ profileName: String, isVisible: Bool) {
        var settings = loadSettings()
        if isVisible {
            settings.visibleProfiles.insert(profileName)
            settings.hiddenProfiles.remove(profileName)
        } else {
            settings.hiddenProfiles.insert(profileName)
            settings.visibleProfiles.remove(profileName)
        }
        saveSettings(settings)
    }
    
    // Get filtered profiles for dropdown
    func getVisibleProfiles(from allProfiles: [AWSProfile]) -> [AWSProfile] {
        let settings = loadSettings()
        
        // If no settings exist, initialize them first
        if settings.visibleProfiles.isEmpty && settings.hiddenProfiles.isEmpty {
            // First time - initialize with defaults (demo hidden)
            initializeProfiles(allProfiles)
            let newSettings = loadSettings()
            return allProfiles.filter { newSettings.visibleProfiles.contains($0.name) }
        }
        
        // Filter to only visible profiles
        var visibleProfiles = allProfiles.filter { settings.visibleProfiles.contains($0.name) }
        
        // Add removed profiles that user chose to keep
        for (profileName, info) in settings.removedProfiles where info.preserveData {
            // Create a synthetic profile for removed but preserved profiles
            let removedProfile = AWSProfile(
                name: "\(profileName) (removed)",
                region: nil,
                accountId: nil,
                isRemoved: true,
                lastSeenDate: info.lastSeenDate
            )
            visibleProfiles.append(removedProfile)
        }
        
        return visibleProfiles
    }
    
    // Check if this is first launch or profiles need scanning
    func shouldScanForChanges() -> Bool {
        let settings = loadSettings()
        
        // First launch - no settings exist
        if settings.visibleProfiles.isEmpty && 
           settings.hiddenProfiles.isEmpty && 
           settings.removedProfiles.isEmpty {
            return true  // Need to initialize
        }
        
        // Check if it's been more than 24 hours since last scan
        if let lastScan = settings.lastScanDate {
            let hoursSinceLastScan = Date().timeIntervalSince(lastScan) / 3600
            return hoursSinceLastScan > 24  // Scan for changes if it's been a day
        }
        
        return false  // Default: don't scan if we have settings and it's been less than 24 hours
    }
    
    // Initialize profiles on first launch
    func initializeProfiles(_ profiles: [AWSProfile]) {
        var settings = ProfileVisibilitySettings()
        for profile in profiles {
            // Demo profile (acme) is hidden by default
            if profile.name != "acme" {
                settings.visibleProfiles.insert(profile.name)
            } else {
                settings.hiddenProfiles.insert(profile.name)
            }
        }
        // Set last scan date to prevent immediate re-scan
        settings.lastScanDate = Date()
        // Mark as initialized to prevent showing alerts
        settings.hasCompletedInitialSetup = true
        saveSettings(settings)
    }
}

