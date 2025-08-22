import Foundation
import UserNotifications
import SwiftUI

// Alert configuration for each profile
struct AlertConfiguration: Codable {
    var enableThresholdAlerts: Bool = true
    var enableBudgetExceededAlerts: Bool = true
    var enableAnomalyAlerts: Bool = true
    var cooldownMinutes: Int = 60 // Prevent alert spam
    var soundEnabled: Bool = true
}

// Track sent alerts to prevent spam
struct SentAlert: Codable {
    let profileName: String
    let alertType: AlertType
    let timestamp: Date
    
    enum AlertType: String, Codable {
        case threshold
        case budgetExceeded
        case anomaly
    }
}

class CostAlertManager: ObservableObject {
    @Published var alertSettings: [String: AlertConfiguration] = [:]
    @Published var sentAlerts: [SentAlert] = []
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    private let settingsKey = "CostAlertSettings"
    private let sentAlertsKey = "SentCostAlerts"
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        loadSettings()
        loadSentAlerts()
        // Delay permission check slightly to ensure proper initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.checkNotificationPermissions()
        }
    }
    
    // MARK: - Notification Permissions
    
    func requestNotificationPermissions() async {
        do {
            // Mark that we've now asked for permission
            UserDefaults.standard.set(true, forKey: "HasRequestedNotificationPermission")
            
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                checkNotificationPermissions()
            }
            print("[NotificationPermissions] Permission \(granted ? "granted" : "denied")")
        } catch {
            print("[NotificationPermissions] Error requesting permissions: \(error)")
            // If notifications are blocked at system level, update status
            await MainActor.run {
                if (error as NSError).code == 1 {
                    // Code 1 means notifications are not allowed for this app
                    self.notificationPermissionStatus = .denied
                }
            }
        }
    }
    
    func checkNotificationPermissions() {
        notificationCenter.getNotificationSettings { settings in
            Task { @MainActor in
                // Log the actual status for debugging
                print("[NotificationPermissions] Authorization status: \(settings.authorizationStatus.rawValue)")
                print("[NotificationPermissions] Status description: \(self.describeStatus(settings.authorizationStatus))")
                
                // On macOS, if we've never asked for permission but notifications are disabled,
                // the system might report it as denied. We need to check if we've ever asked.
                let hasAskedBefore = UserDefaults.standard.bool(forKey: "HasRequestedNotificationPermission")
                
                // Additional check: on macOS, apps that have never requested permission might
                // show as denied if notifications are globally disabled or if the app doesn't
                // appear in notification settings yet
                if !hasAskedBefore && (settings.authorizationStatus == .denied || settings.authorizationStatus == .notDetermined) {
                    // If we haven't asked before, always show as notDetermined
                    print("[NotificationPermissions] First time check - treating as notDetermined")
                    self.notificationPermissionStatus = .notDetermined
                } else if hasAskedBefore {
                    // If we have asked before, use the actual status
                    self.notificationPermissionStatus = settings.authorizationStatus
                } else {
                    // Fallback to actual status
                    self.notificationPermissionStatus = settings.authorizationStatus
                }
            }
        }
    }
    
    private func describeStatus(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .authorized: return "authorized"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral"
        @unknown default: return "unknown"
        }
    }
    
    // MARK: - Alert Checking
    
    func checkAndSendAlerts(for profileName: String, cost: Decimal, budget: ProfileBudget, status: AWSManager.BudgetStatus) {
        let config = getAlertConfiguration(for: profileName)
        
        // Check if notifications are enabled
        guard notificationPermissionStatus == .authorized else { return }
        
        // Check budget exceeded
        if config.enableBudgetExceededAlerts && status.isOverBudget, let monthlyBudget = budget.monthlyBudget {
            if shouldSendAlert(profileName: profileName, type: .budgetExceeded, cooldown: config.cooldownMinutes) {
                sendBudgetExceededAlert(profileName: profileName, amount: cost, budget: monthlyBudget)
            }
        }
        
        // Check threshold
        if config.enableThresholdAlerts && status.isNearThreshold && !status.isOverBudget {
            if shouldSendAlert(profileName: profileName, type: .threshold, cooldown: config.cooldownMinutes) {
                sendThresholdAlert(profileName: profileName, percentage: status.percentage, threshold: budget.alertThreshold)
            }
        }
    }
    
    func checkAndSendAnomalyAlerts(for profileName: String, anomalies: [SpendingAnomaly]) {
        let config = getAlertConfiguration(for: profileName)
        
        guard config.enableAnomalyAlerts,
              notificationPermissionStatus == .authorized,
              !anomalies.isEmpty else { return }
        
        // Only send alert for critical anomalies or if there are multiple warnings
        let criticalAnomalies = anomalies.filter { $0.severity == .critical }
        let shouldAlert = !criticalAnomalies.isEmpty || anomalies.count >= 2
        
        if shouldAlert && shouldSendAlert(profileName: profileName, type: .anomaly, cooldown: config.cooldownMinutes) {
            sendAnomalyAlert(profileName: profileName, anomalies: anomalies)
        }
    }
    
    // MARK: - Alert Sending
    
    private func sendBudgetExceededAlert(profileName: String, amount: Decimal, budget: Decimal) {
        let content = UNMutableNotificationContent()
        content.title = "Budget Exceeded"
        content.subtitle = profileName
        content.body = String(format: "Monthly spending ($%.2f) has exceeded your budget of $%.2f",
                            NSDecimalNumber(decimal: amount).doubleValue,
                            NSDecimalNumber(decimal: budget).doubleValue)
        content.sound = getAlertConfiguration(for: profileName).soundEnabled ? .default : nil
        content.categoryIdentifier = "BUDGET_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "\(profileName)-budget-exceeded-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending budget exceeded notification: \(error)")
            } else {
                self.recordSentAlert(profileName: profileName, type: .budgetExceeded)
            }
        }
    }
    
    private func sendThresholdAlert(profileName: String, percentage: Double, threshold: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Approaching Budget Limit"
        content.subtitle = profileName
        content.body = String(format: "You've used %.0f%% of your monthly budget",
                            percentage * 100)
        content.sound = getAlertConfiguration(for: profileName).soundEnabled ? .default : nil
        content.categoryIdentifier = "BUDGET_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "\(profileName)-threshold-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending threshold notification: \(error)")
            } else {
                self.recordSentAlert(profileName: profileName, type: .threshold)
            }
        }
    }
    
    private func sendAnomalyAlert(profileName: String, anomalies: [SpendingAnomaly]) {
        let content = UNMutableNotificationContent()
        content.title = "Unusual Spending Detected"
        content.subtitle = profileName
        
        // Build body with most critical anomaly
        if let mostCritical = anomalies.first(where: { $0.severity == .critical }) ?? anomalies.first {
            content.body = mostCritical.message
            if anomalies.count > 1 {
                content.body += " (+\(anomalies.count - 1) more alerts)"
            }
        }
        
        content.sound = getAlertConfiguration(for: profileName).soundEnabled ? .default : nil
        content.categoryIdentifier = "ANOMALY_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "\(profileName)-anomaly-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending anomaly notification: \(error)")
            } else {
                self.recordSentAlert(profileName: profileName, type: .anomaly)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func shouldSendAlert(profileName: String, type: SentAlert.AlertType, cooldown: Int) -> Bool {
        let cutoffTime = Date().addingTimeInterval(-TimeInterval(cooldown * 60))
        
        // Check if we've sent this type of alert recently
        let recentAlert = sentAlerts.contains { alert in
            alert.profileName == profileName &&
            alert.alertType == type &&
            alert.timestamp > cutoffTime
        }
        
        return !recentAlert
    }
    
    private func recordSentAlert(profileName: String, type: SentAlert.AlertType) {
        let alert = SentAlert(profileName: profileName, alertType: type, timestamp: Date())
        sentAlerts.append(alert)
        
        // Clean up old alerts (older than 24 hours)
        let cutoffTime = Date().addingTimeInterval(-86400)
        sentAlerts.removeAll { $0.timestamp < cutoffTime }
        
        saveSentAlerts()
    }
    
    func getAlertConfiguration(for profileName: String) -> AlertConfiguration {
        return alertSettings[profileName] ?? AlertConfiguration()
    }
    
    func updateAlertConfiguration(for profileName: String, configuration: AlertConfiguration) {
        alertSettings[profileName] = configuration
        saveSettings()
    }
    
    // MARK: - Persistence
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode([String: AlertConfiguration].self, from: data) {
            alertSettings = decoded
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(alertSettings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    private func loadSentAlerts() {
        if let data = UserDefaults.standard.data(forKey: sentAlertsKey),
           let decoded = try? JSONDecoder().decode([SentAlert].self, from: data) {
            sentAlerts = decoded
        }
    }
    
    private func saveSentAlerts() {
        if let encoded = try? JSONEncoder().encode(sentAlerts) {
            UserDefaults.standard.set(encoded, forKey: sentAlertsKey)
        }
    }
    
    // MARK: - Alert History
    
    func clearAlertHistory() {
        sentAlerts.removeAll()
        saveSentAlerts()
    }
    
    func getRecentAlerts(for profileName: String? = nil, limit: Int = 10) -> [SentAlert] {
        let filtered = profileName != nil ? sentAlerts.filter { $0.profileName == profileName! } : sentAlerts
        return Array(filtered.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }
}

