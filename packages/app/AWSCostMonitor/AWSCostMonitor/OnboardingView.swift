import SwiftUI
import AppKit

struct OnboardingView: View {
    @EnvironmentObject var awsManager: AWSManager
    @State private var currentStep = 0
    @State private var selectedProfile: AWSProfile?
    @State private var monthlyBudget: String = "5"
    @State private var alertThreshold: Double = 0.8
    @State private var enableNotifications = true
    @State private var enableAutoRefresh = true
    @State private var enableAnomalyAlerts = true
    @State private var refreshInterval: Double = 360
    
    let totalSteps = 5
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Welcome to AWS Cost Monitor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Let's get you set up in just a few steps")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            // Progress indicator
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .progressViewStyle(.linear)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            // Content
            TabView(selection: $currentStep) {
                welcomeStep
                    .tag(0)
                
                profileSelectionStep
                    .tag(1)
                
                budgetSetupStep
                    .tag(2)
                
                notificationStep
                    .tag(3)
                
                completionStep
                    .tag(4)
            }
            .tabViewStyle(.automatic)
            .frame(height: 350)
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                }
                
                Spacer()
                
                if currentStep < totalSteps - 1 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep == 1 && selectedProfile == nil)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 600)
        .frame(minHeight: 600)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Steps
    
    var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Monitor Your AWS Spending")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Track costs in real-time", systemImage: "clock.fill")
                Label("Set budgets and get alerts", systemImage: "bell.fill")
                Label("View spending trends", systemImage: "chart.xyaxis.line")
                Label("Export detailed reports", systemImage: "square.and.arrow.up")
            }
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 80)
        }
    }
    
    var profileSelectionStep: some View {
        VStack(spacing: 20) {
            Text("Select Your AWS Profile")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose the AWS profile you want to monitor")
                .font(.body)
                .foregroundColor(.secondary)
            
            if awsManager.profiles.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("No AWS profiles found")
                        .font(.headline)
                    
                    Text("Make sure you have configured AWS profiles in ~/.aws/config")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Open AWS Documentation") {
                        if let url = URL(string: "https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(awsManager.profiles) { profile in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(profile.name)
                                        .font(.headline)
                                    if let region = profile.region {
                                        Text(region)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedProfile?.id == profile.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedProfile?.id == profile.id ? Color.accentColor.opacity(0.1) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedProfile?.id == profile.id ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedProfile = profile
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxHeight: 200)
            }
        }
    }
    
    var budgetSetupStep: some View {
        VStack(spacing: 20) {
            Text("Configure Cost Explorer API Usage")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Balance API costs with data freshness")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 20) {
                // API Usage Budget
                VStack(alignment: .leading, spacing: 12) {
                    Label("Cost Explorer API Budget", systemImage: "network")
                        .font(.headline)
                    
                    Text("AWS charges ~$0.01 per Cost Explorer API request")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("5", text: $monthlyBudget)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        
                        Text("USD per month")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Estimated ~\(Int((Double(monthlyBudget) ?? 5.0) / 0.01)) API calls per month")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Refresh interval
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Auto-refresh Interval", systemImage: "arrow.clockwise")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(formatRefreshInterval(refreshInterval))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $refreshInterval, in: 60...1440, step: 60)
                    
                    HStack {
                        Text("1 hour")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("24 hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("More frequent updates = higher API costs")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 60)
        }
    }
    
    func formatRefreshInterval(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours >= 24 {
            return "24 hours"
        } else if hours > 0 && mins == 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins) minutes"
        }
    }
    
    var notificationStep: some View {
        VStack(spacing: 20) {
            Text("Configure Notifications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Stay informed about your AWS spending")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 20) {
                // Enable notifications
                Toggle(isOn: $enableNotifications) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Spending Alerts")
                            .font(.headline)
                        Text("Get notified when spending exceeds thresholds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if enableNotifications {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Alert when spending reaches \(Int(alertThreshold * 100))% of budget", systemImage: "bell")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 32)
                        
                        Slider(value: $alertThreshold, in: 0.5...0.95, step: 0.05)
                            .padding(.leading, 32)
                    }
                }
                
                Divider()
                
                // Anomaly detection
                Toggle(isOn: $enableAnomalyAlerts) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Detect Spending Anomalies")
                            .font(.headline)
                        Text("Alert on unusual spending patterns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if enableAnomalyAlerts {
                    Label("Notifies when spending deviates significantly from normal", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
            }
            .padding(.horizontal, 80)
        }
    }
    
    var completionStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("All Set!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("AWS Cost Monitor is ready to help you track your spending")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 12) {
                if let profile = selectedProfile {
                    Label("Profile: \(profile.name)", systemImage: "person.circle")
                }
                
                Label("API Budget: $\(monthlyBudget) USD/month", systemImage: "network")
                
                Label("Refresh: \(formatRefreshInterval(refreshInterval))", systemImage: "arrow.clockwise.circle")
                
                if enableNotifications {
                    Label("Spending alerts at \(Int(alertThreshold * 100))%", systemImage: "bell.circle")
                }
                
                if enableAnomalyAlerts {
                    Label("Anomaly detection enabled", systemImage: "exclamationmark.triangle")
                }
            }
            .font(.body)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
            )
        }
    }
    
    // MARK: - Actions
    
    func completeOnboarding() {
        // Save settings
        if let profile = selectedProfile {
            awsManager.selectedProfile = profile
            awsManager.saveSelectedProfile(profile: profile)
            
            // Set budgets
            if let monthlyBudgetValue = Decimal(string: monthlyBudget) {
                awsManager.updateBudget(for: profile.name, monthlyBudget: monthlyBudgetValue, alertThreshold: alertThreshold)
                awsManager.updateAPIBudgetAndRefresh(for: profile.name, apiBudget: Decimal(string: monthlyBudget) ?? 5, refreshIntervalMinutes: Int(refreshInterval))
            }
        }
        
        // Configure notifications
        if enableNotifications {
            Task {
                await awsManager.alertManager.requestNotificationPermissions()
            }
        }
        
        // Configure auto-refresh (always enabled with selected interval)
        awsManager.refreshInterval = Int(refreshInterval)
        awsManager.startAutomaticRefresh()
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        
        // Close the window
        if let window = NSApp.keyWindow {
            window.close()
        }
        
        // Fetch initial data
        if selectedProfile != nil {
            Task {
                await awsManager.fetchCostForSelectedProfile()
            }
        }
    }
}

// Helper to show onboarding window
func showOnboardingWindow(awsManager: AWSManager) {
    let onboardingView = OnboardingView()
        .environmentObject(awsManager)
    
    let hostingController = NSHostingController(rootView: onboardingView)
    let window = NSWindow(contentViewController: hostingController)
    window.title = "Welcome to AWS Cost Monitor"
    window.styleMask = [.titled, .closable]
    window.isMovableByWindowBackground = true
    window.center()
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}