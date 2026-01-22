//
//  ThemeManager.swift
//  AWSCostMonitor
//
//  Theme management system with persistence and system appearance sync
//

import Foundation
import SwiftUI
import Combine
import AppKit

class ThemeManager: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = ThemeManager()
    
    // MARK: - Published Properties
    
    @Published var currentTheme: Theme
    @Published var syncWithSystemAppearance: Bool
    
    // MARK: - Private Properties
    
    private let availableThemes: [Theme] = [
        ClassicTheme(),
        ModernTheme(),
        HighContrastTheme(),
        CompactTheme(),
        ComfortableTheme(),
        TerminalTheme(),
        ProfessionalTheme(),
        MemphisTheme()
    ]
    
    private var appearanceObserver: NSObjectProtocol?
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults keys
    private let selectedThemeKey = "selectedTheme"
    private let syncWithSystemAppearanceKey = "syncWithSystemAppearance"
    
    // MARK: - Initialization
    
    init() {
        // Load saved theme or default to Classic
        let savedThemeId = userDefaults.string(forKey: selectedThemeKey) ?? "classic"
        self.currentTheme = availableThemes.first { $0.identifier == savedThemeId } ?? ClassicTheme()
        
        // Load system sync preference
        self.syncWithSystemAppearance = userDefaults.bool(forKey: syncWithSystemAppearanceKey)
        
        // Set up system appearance monitoring
        setupSystemAppearanceMonitoring()
    }
    
    deinit {
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    
    /// Get all available themes
    func getAllThemes() -> [Theme] {
        return availableThemes
    }
    
    /// Get theme by identifier
    func getTheme(byId identifier: String) -> Theme? {
        return availableThemes.first { $0.identifier == identifier }
    }
    
    /// Select a theme and persist the choice
    func selectTheme(_ theme: Theme) {
        currentTheme = theme
        userDefaults.set(theme.identifier, forKey: selectedThemeKey)
        
        // Post notification for theme change
        NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChange"), object: nil)
        
        // Log theme change for debugging
        #if DEBUG
        print("ThemeManager: Selected theme '\(theme.name)' (\(theme.identifier))")
        #endif
    }
    
    /// Toggle system appearance synchronization
    func setSyncWithSystemAppearance(_ enabled: Bool) {
        syncWithSystemAppearance = enabled
        userDefaults.set(enabled, forKey: syncWithSystemAppearanceKey)
        
        if enabled {
            // Apply appropriate theme based on current system appearance
            updateThemeForSystemAppearance()
        }
        
        #if DEBUG
        print("ThemeManager: System appearance sync \(enabled ? "enabled" : "disabled")")
        #endif
    }
    
    // MARK: - System Appearance Monitoring
    
    private func setupSystemAppearanceMonitoring() {
        // Monitor when app becomes active to check for appearance changes
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: NSApplication.shared,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemAppearanceChange()
        }
    }
    
    private func handleSystemAppearanceChange() {
        guard syncWithSystemAppearance else { return }
        updateThemeForSystemAppearance()
    }
    
    private func updateThemeForSystemAppearance() {
        let isDark = NSApplication.shared.effectiveAppearance.name == .darkAqua
        
        // Map system appearance to appropriate theme
        let recommendedThemeId: String
        
        if isDark {
            // For dark mode, prefer darker themes or themes that work well in dark mode
            recommendedThemeId = currentTheme.identifier == "terminal" ? "terminal" : "modern"
        } else {
            // For light mode, prefer lighter themes
            recommendedThemeId = currentTheme.identifier == "terminal" ? "classic" : currentTheme.identifier
        }
        
        if let newTheme = getTheme(byId: recommendedThemeId), newTheme.identifier != currentTheme.identifier {
            selectTheme(newTheme)
            
            #if DEBUG
            print("ThemeManager: Auto-switched to \(newTheme.name) for \(isDark ? "dark" : "light") mode")
            #endif
        }
    }
    
    // MARK: - Theme Caching
    
    private var colorCache: [String: Color] = [:]
    
    /// Get cached color to avoid repeated color computations
    func getCachedColor(for key: String, defaultColor: Color) -> Color {
        if let cachedColor = colorCache[key] {
            return cachedColor
        }
        
        colorCache[key] = defaultColor
        return defaultColor
    }
    
    /// Clear color cache when theme changes
    private func clearColorCache() {
        colorCache.removeAll()
    }
    
    // MARK: - Migration Support
    
    /// Migrate users from previous versions that didn't have themes
    func migrateToThemeSystem() {
        // Check if this is first run with theme system
        if userDefaults.object(forKey: selectedThemeKey) == nil {
            // First time - set to Classic theme
            userDefaults.set("classic", forKey: selectedThemeKey)
            
            #if DEBUG
            print("ThemeManager: Migrated user to Classic theme")
            #endif
        }
    }
}

// MARK: - Theme Environment

/// Environment key for theme injection
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = ClassicTheme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions for Theme Application

extension View {
    /// Apply current theme to the view
    func themed(_ themeManager: ThemeManager) -> some View {
        self.environment(\.theme, themeManager.currentTheme)
    }
    
    /// Apply theme-aware colors
    func themeBackground(_ theme: Theme) -> some View {
        self.background(theme.backgroundColor)
    }
    
    func themeForeground(_ theme: Theme) -> some View {
        self.foregroundColor(theme.textColor)
    }
    
    
    /// Apply theme-aware spacing
    func themeSpacing(_ theme: Theme, _ spacing: CGFloat = 8.0) -> some View {
        let scaledSpacing = spacing * theme.spacingMultiplier
        return self.padding(.bottom, scaledSpacing)
    }
}