//
//  AppearanceSettingsTab.swift
//  AWSCostMonitor
//
//  Theme selection UI for the Settings window
//

import SwiftUI

struct AppearanceSettingsTab: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Customize the visual appearance of AWSCostMonitor with different themes and display options.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            // System Appearance Sync
            VStack(alignment: .leading, spacing: 12) {
                Text("System Integration")
                    .font(.headline)

                Toggle("Sync with System Appearance", isOn: Binding(
                    get: { themeManager.syncWithSystemAppearance },
                    set: { themeManager.setSyncWithSystemAppearance($0) }
                ))
                .toggleStyle(SwitchToggleStyle())

                Text("Automatically switch themes when macOS changes between light and dark mode.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }

            Divider()

            // Menu Bar Style
            VStack(alignment: .leading, spacing: 12) {
                Text("Menu Bar Style")
                    .font(.headline)

                Toggle("Show Pill Background", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "ShowMenuBarPillBackground") },
                    set: {
                        UserDefaults.standard.set($0, forKey: "ShowMenuBarPillBackground")
                        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
                    }
                ))
                .toggleStyle(SwitchToggleStyle())

                Text("Add a subtle pill-shaped background behind the cost display in the menu bar. Some themes enable this by default.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            
            Divider()
            
            // Theme Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Theme Selection")
                    .font(.headline)
                
                ThemeGridSelector(themeManager: themeManager)
            }
            
            Divider()
            
            // Live Preview
            VStack(alignment: .leading, spacing: 16) {
                Text("Preview")
                    .font(.headline)
                
                ThemeLivePreview(themeManager: themeManager)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Theme Grid Selector

struct ThemeGridSelector: View {
    @ObservedObject var themeManager: ThemeManager
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(themeManager.getAllThemes(), id: \.identifier) { theme in
                ThemePreviewCard(
                    theme: theme,
                    isSelected: themeManager.currentTheme.identifier == theme.identifier,
                    onSelect: {
                        themeManager.selectTheme(theme)
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Theme Preview Card

struct ThemePreviewCard: View {
    let theme: Theme
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Theme Preview Area
                VStack(spacing: 8) {
                    // Mock menu bar preview
                    HStack {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 8, height: 8)
                        
                        Text("$123.45")
                            .font(.system(size: theme.regularFontSize, weight: theme.primaryFontWeight))
                            .foregroundColor(theme.textColor)
                        
                        Spacer()
                        
                        Text("MTD")
                            .font(.system(size: theme.smallFontSize, weight: theme.secondaryFontWeight))
                            .foregroundColor(theme.secondaryColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.backgroundColor)
                    .cornerRadius(4)
                    
                    // Color palette preview
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Rectangle()
                                .fill(theme.chartColor(for: index))
                                .frame(height: 12)
                        }
                    }
                    .cornerRadius(2)
                }
                .padding(12)
                .background(theme.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                )
                
                // Theme Information
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(theme.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.accentColor : (isHovered ? Color.gray.opacity(0.5) : Color.clear),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("\(theme.name) theme")
        .accessibilityHint(theme.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Live Preview

struct ThemeLivePreview: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Theme: \(themeManager.currentTheme.name)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Preview the actual UI elements with current theme
            VStack(spacing: 16) {
                // Menu bar preview
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    
                    Text("$456.78 MTD")
                        .themeFont(themeManager.currentTheme, size: .regular, weight: .primary)
                        .themeForeground(themeManager.currentTheme)
                    
                    Spacer()
                    
                    Text("AWS Costs")
                        .themeFont(themeManager.currentTheme, size: .small, weight: .secondary)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                }
                .themePadding(themeManager.currentTheme)
                .themeBackground(themeManager.currentTheme)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.currentTheme.accentColor.opacity(0.2), lineWidth: 1)
                )
                
                // Sample chart colors
                HStack(spacing: 8) {
                    Text("Chart Colors:")
                        .themeFont(themeManager.currentTheme, size: .small, weight: .secondary)
                        .themeForeground(themeManager.currentTheme)
                    
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(themeManager.currentTheme.chartColor(for: index))
                            .frame(width: 16, height: 16)
                    }
                    
                    Spacer()
                }
                
                // Typography samples
                VStack(alignment: .leading, spacing: 4) {
                    Text("Typography Preview")
                        .themeFont(themeManager.currentTheme, size: .large, weight: .secondary)
                        .themeForeground(themeManager.currentTheme)
                    
                    Text("Regular text with primary weight")
                        .themeFont(themeManager.currentTheme, size: .regular, weight: .primary)
                        .themeForeground(themeManager.currentTheme)
                    
                    Text("Small secondary text")
                        .themeFont(themeManager.currentTheme, size: .small, weight: .secondary)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .themePadding(themeManager.currentTheme)
            .themeBackground(themeManager.currentTheme)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    AppearanceSettingsTab(themeManager: ThemeManager())
        .frame(width: 600, height: 400)
}