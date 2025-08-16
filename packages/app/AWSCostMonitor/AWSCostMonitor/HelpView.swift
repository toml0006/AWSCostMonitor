import SwiftUI

struct HelpView: View {
    @State private var selectedCategory = "Getting Started"
    
    let helpCategories = [
        "Getting Started",
        "Features",
        "Settings",
        "Troubleshooting",
        "Keyboard Shortcuts",
        "About"
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("Help Topics")
                    .font(.headline)
                    .padding()
                
                ForEach(helpCategories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack {
                            Text(category)
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? Color.accentColor : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }
                
                Spacer()
                
                // Marketing website link at bottom
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal, 8)
                    
                    Button(action: {
                        if let url = URL(string: "https://toml0006.github.io/AWSCostMonitor/") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("toml0006.github.io/AWSCostMonitor")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                }
                .padding(.bottom, 8)
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    helpContent(for: selectedCategory)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 700, height: 500)
    }
    
    @ViewBuilder
    func helpContent(for category: String) -> some View {
        switch category {
        case "Getting Started":
            gettingStartedHelp
        case "Features":
            featuresHelp
        case "Settings":
            settingsHelp
        case "Troubleshooting":
            troubleshootingHelp
        case "Keyboard Shortcuts":
            keyboardShortcutsHelp
        case "About":
            aboutHelp
        default:
            Text("Select a topic from the sidebar")
        }
    }
    
    var gettingStartedHelp: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Getting Started")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Welcome to AWSCostMonitor! This app helps you keep track of your AWS spending directly from your Mac's menu bar.")
                .font(.body)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Prerequisites", systemImage: "checkmark.circle")
                    .font(.headline)
                
                Text("• AWS CLI configured with profiles in ~/.aws/config")
                Text("• AWS credentials configured in ~/.aws/credentials")
                Text("• IAM permissions for Cost Explorer API")
                    .padding(.bottom)
                
                Label("First Steps", systemImage: "1.circle")
                    .font(.headline)
                
                Text("1. Select your AWS profile from the dropdown")
                Text("2. Click 'Refresh' to fetch current month costs")
                Text("3. Configure your budget in Settings → Budget")
                Text("4. Enable automatic refresh in Settings → Refresh")
            }
        }
    }
    
    var featuresHelp: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Features")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Group {
                FeatureSection(
                    title: "Cost Monitoring",
                    icon: "dollarsign.circle",
                    features: [
                        "Month-to-date AWS spending display",
                        "Real-time cost updates",
                        "Multiple AWS profile support",
                        "Service-level cost breakdown",
                        "14-day spending histograms per service",
                        "Month-end spending projection",
                        "Percentage comparison to last month"
                    ]
                )
                
                FeatureSection(
                    title: "Budget Management",
                    icon: "chart.line.uptrend.xyaxis",
                    features: [
                        "Per-profile monthly budgets",
                        "Visual budget progress indicators",
                        "Customizable alert thresholds",
                        "Budget velocity tracking"
                    ]
                )
                
                FeatureSection(
                    title: "Smart Features",
                    icon: "brain",
                    features: [
                        "Automatic refresh with smart intervals",
                        "Spending trend analysis",
                        "End-of-month cost projections",
                        "Anomaly detection alerts",
                        "Color-coded histogram bars (red/green vs last month)",
                        "Smart error handling with retry options"
                    ]
                )
                
                FeatureSection(
                    title: "Display Options",
                    icon: "textformat",
                    features: [
                        "Customizable menu bar display",
                        "Full, abbreviated, or icon-only modes",
                        "Currency formatting options",
                        "Color-coded budget status"
                    ]
                )
            }
        }
    }
    
    var settingsHelp: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 20) {
                SettingSection(
                    title: "Display Settings",
                    description: "Customize how costs appear in the menu bar",
                    options: [
                        "Menu bar format: Choose between full amount, abbreviated, or icon only",
                        "Currency options: Toggle symbol display and decimal places",
                        "Number formatting: Enable/disable thousands separator"
                    ]
                )
                
                SettingSection(
                    title: "Refresh Settings",
                    description: "Control when cost data is updated",
                    options: [
                        "Automatic refresh: Enable scheduled updates",
                        "Refresh interval: Set update frequency (1-60 minutes)",
                        "Smart refresh: Adjusts based on budget usage"
                    ]
                )
                
                SettingSection(
                    title: "Budget Settings",
                    description: "Set spending limits and alerts",
                    options: [
                        "Monthly budget: Set per-profile spending limits",
                        "Alert threshold: Percentage for warnings (50-100%)",
                        "Visual indicators: Colors change based on budget status"
                    ]
                )
                
                SettingSection(
                    title: "Alert Settings",
                    description: "Configure anomaly detection",
                    options: [
                        "Enable/disable spending alerts",
                        "Sensitivity threshold: 10-50% deviation",
                        "Alert types: Spikes, velocity, service costs"
                    ]
                )
            }
        }
    }
    
    var troubleshootingHelp: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Troubleshooting")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 20) {
                TroubleshootingSection(
                    problem: "No AWS profiles found",
                    solutions: [
                        "Ensure AWS CLI is installed and configured",
                        "Check that ~/.aws/config file exists",
                        "Verify profile names in config file",
                        "Run 'aws configure list-profiles' in Terminal"
                    ]
                )
                
                TroubleshootingSection(
                    problem: "Authentication errors",
                    solutions: [
                        "Verify AWS credentials are current",
                        "Check IAM permissions for Cost Explorer",
                        "Ensure profile has correct region configured",
                        "Try running 'aws ce get-cost-and-usage' manually"
                    ]
                )
                
                TroubleshootingSection(
                    problem: "Rate limiting errors",
                    solutions: [
                        "AWS limits Cost Explorer to 1 request/minute",
                        "Wait for the countdown to complete",
                        "Use manual override sparingly",
                        "Adjust refresh interval in settings"
                    ]
                )
                
                TroubleshootingSection(
                    problem: "Incorrect cost data",
                    solutions: [
                        "Costs may take 24-48 hours to finalize",
                        "Verify the correct profile is selected",
                        "Check time zone settings",
                        "Review AWS Cost Explorer console"
                    ]
                )
            }
        }
    }
    
    var keyboardShortcutsHelp: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Use these shortcuts for quick access to features:")
                .font(.body)
                .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 12) {
                ShortcutRow(keys: "⌘R", action: "Refresh cost data")
                ShortcutRow(keys: "⌘,", action: "Open Settings")
                ShortcutRow(keys: "1-9", action: "Quick switch profiles (by position)")
                ShortcutRow(keys: "⌘Q", action: "Quit application")
            }
        }
    }
    
    var aboutHelp: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 20) {
                // App Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AWSCostMonitor")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("A lightweight macOS menu bar application for monitoring AWS spending in real-time.")
                        .font(.body)
                        .padding(.top, 4)
                }
                
                Divider()
                
                // Mission Statement
                VStack(alignment: .leading, spacing: 8) {
                    Label("Mission", systemImage: "target")
                        .font(.headline)
                    
                    Text("Keep AWS costs under control with always-visible spending data, intelligent refresh rates, and privacy-first design. No external services, no telemetry - just your data on your machine.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Key Features Summary
                VStack(alignment: .leading, spacing: 8) {
                    Label("What Makes It Special", systemImage: "star.fill")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Native macOS app with minimal resource usage")
                        Text("• 100% private - all data stays on your Mac")
                        Text("• Smart API rate limiting to protect your AWS bill")
                        Text("• 14-day spending histograms with hover details")
                        Text("• Multi-profile support with persistent settings")
                        Text("• End-of-month cost projections")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Technical Info
                VStack(alignment: .leading, spacing: 8) {
                    Label("Technical Details", systemImage: "gear")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Built with SwiftUI and AWS SDK for Swift")
                        Text("• Requires AWS CLI configured with profiles")
                        Text("• Uses Cost Explorer API (1 request per minute max)")
                        Text("• Data cached locally for performance")
                        Text("• macOS 13.0+ required")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Developer Info
                VStack(alignment: .leading, spacing: 8) {
                    Label("Development", systemImage: "hammer.fill")
                        .font(.headline)
                    
                    Text("Developed with focus on developer experience and cost transparency. Open to feedback and feature requests.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Button("GitHub Repository") {
                            if let url = URL(string: "https://github.com/") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                        
                        Button("Report Issue") {
                            if let url = URL(string: "https://github.com/") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                    }
                    .font(.body)
                }
            }
        }
    }
}

// MARK: - Helper Views

struct FeatureSection: View {
    let title: String
    let icon: String
    let features: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(features, id: \.self) { feature in
                    Text("• \(feature)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingSection: View {
    let title: String
    let description: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(options, id: \.self) { option in
                    Text("• \(option)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct TroubleshootingSection: View {
    let problem: String
    let solutions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(problem, systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(solutions, id: \.self) { solution in
                    Text("→ \(solution)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ShortcutRow: View {
    let keys: String
    let action: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .frame(width: 60, alignment: .leading)
            Text("—")
                .foregroundColor(.secondary)
            Text(action)
        }
    }
}

#Preview {
    HelpView()
}