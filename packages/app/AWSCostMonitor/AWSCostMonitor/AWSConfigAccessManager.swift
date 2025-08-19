import Foundation
import AppKit
import os.log

/// Manages secure access to AWS configuration files in a sandboxed environment
class AWSConfigAccessManager: ObservableObject {
    static let shared = AWSConfigAccessManager()
    
    private let logger = Logger(subsystem: "middleout.AWSCostMonitor", category: "AWSConfigAccess")
    private let bookmarkKey = "AWSConfigFolderBookmark"
    private let bookmarkVersionKey = "AWSConfigBookmarkVersion"
    private let currentBookmarkVersion = 1
    
    @Published var hasAccess: Bool = false
    @Published var needsAccessGrant: Bool = false
    
    private var securityScopedURL: URL?
    
    private init() {
        checkAccess()
    }
    
    /// Check if we have valid access to AWS config
    func checkAccess() {
        // First check if we're sandboxed
        let isSandboxed = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
        
        if !isSandboxed {
            // Not sandboxed, direct access works
            hasAccess = true
            needsAccessGrant = false
            logger.info("App is not sandboxed, direct AWS config access available")
            return
        }
        
        // Check for existing bookmark
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) {
            if restoreAccessFromBookmark(bookmarkData) {
                hasAccess = true
                needsAccessGrant = false
                logger.info("Successfully restored AWS config access from bookmark")
            } else {
                // Bookmark is stale or invalid
                hasAccess = false
                needsAccessGrant = true
                logger.warning("AWS config bookmark is stale or invalid")
            }
        } else {
            // No bookmark exists
            hasAccess = false
            needsAccessGrant = true
            logger.info("No AWS config bookmark found, need to request access")
        }
    }
    
    /// Request access to AWS config folder from user
    func requestAccess(from window: NSWindow? = nil) {
        let panel = NSOpenPanel()
        panel.title = "Grant Access to AWS Configuration"
        panel.message = "AWSCostMonitor needs access to your AWS configuration folder to read profiles and credentials."
        panel.prompt = "Grant Access"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.showsHiddenFiles = true
        
        // Set default location to home directory
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        _ = homeURL.appendingPathComponent(".aws")
        
        // Check if .aws exists in real home directory
        let realHome = NSString("~").expandingTildeInPath
        let realAWSPath = "\(realHome)/.aws"
        
        if FileManager.default.fileExists(atPath: realAWSPath) {
            panel.directoryURL = URL(fileURLWithPath: realHome)
        } else {
            panel.directoryURL = homeURL
        }
        
        panel.begin { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK, let url = panel.url {
                // Verify this is the .aws folder
                if url.lastPathComponent != ".aws" {
                    self.showError(
                        title: "Invalid Folder Selected",
                        message: "Please select your .aws folder, not \(url.lastPathComponent)",
                        window: window
                    )
                    return
                }
                
                self.saveBookmark(for: url)
            } else {
                self.logger.info("User cancelled AWS config access request")
            }
        }
    }
    
    /// Save security-scoped bookmark for the AWS config folder
    private func saveBookmark(for url: URL) {
        do {
            // Create security-scoped bookmark
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            // Save to UserDefaults
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            UserDefaults.standard.set(currentBookmarkVersion, forKey: bookmarkVersionKey)
            
            // Update state
            hasAccess = true
            needsAccessGrant = false
            securityScopedURL = url
            
            logger.info("Successfully saved AWS config bookmark")
            
            // Post notification for app to reload profiles
            NotificationCenter.default.post(name: .awsConfigAccessGranted, object: nil)
            
        } catch {
            logger.error("Failed to create bookmark: \(error.localizedDescription)")
            showError(
                title: "Access Grant Failed",
                message: "Failed to save access permissions: \(error.localizedDescription)"
            )
        }
    }
    
    /// Restore access from saved bookmark
    @discardableResult
    private func restoreAccessFromBookmark(_ bookmarkData: Data) -> Bool {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                logger.warning("AWS config bookmark is stale")
                // Try to refresh the bookmark
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // Create new bookmark
                    if let newBookmarkData = try? url.bookmarkData(
                        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        UserDefaults.standard.set(newBookmarkData, forKey: bookmarkKey)
                        logger.info("Successfully refreshed stale bookmark")
                    }
                }
            }
            
            securityScopedURL = url
            return true
            
        } catch {
            logger.error("Failed to restore bookmark: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Read AWS config file with security-scoped access
    func readConfigFile() -> String? {
        // If not sandboxed, read directly
        if !ProcessInfo.processInfo.environment.keys.contains("APP_SANDBOX_CONTAINER_ID") {
            let configPath = NSString("~/.aws/config").expandingTildeInPath
            return try? String(contentsOfFile: configPath, encoding: .utf8)
        }
        
        // Use security-scoped access
        guard let url = securityScopedURL else {
            logger.error("No security-scoped URL available")
            needsAccessGrant = true
            return nil
        }
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to start accessing security-scoped resource")
            needsAccessGrant = true
            return nil
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Read config file
        let configURL = url.appendingPathComponent("config")
        
        do {
            let configContent = try String(contentsOf: configURL, encoding: .utf8)
            logger.info("Successfully read AWS config file")
            return configContent
        } catch {
            logger.error("Failed to read AWS config: \(error.localizedDescription)")
            
            // Check if file exists
            if !FileManager.default.fileExists(atPath: configURL.path) {
                logger.error("AWS config file does not exist at: \(configURL.path)")
            }
            
            return nil
        }
    }
    
    /// Read AWS credentials file with security-scoped access
    func readCredentialsFile() -> String? {
        // If not sandboxed, read directly
        if !ProcessInfo.processInfo.environment.keys.contains("APP_SANDBOX_CONTAINER_ID") {
            let credentialsPath = NSString("~/.aws/credentials").expandingTildeInPath
            return try? String(contentsOfFile: credentialsPath, encoding: .utf8)
        }
        
        // Use security-scoped access
        guard let url = securityScopedURL else {
            logger.error("No security-scoped URL available for credentials")
            return nil
        }
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to start accessing security-scoped resource for credentials")
            return nil
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Read credentials file
        let credentialsURL = url.appendingPathComponent("credentials")
        
        do {
            let credentialsContent = try String(contentsOf: credentialsURL, encoding: .utf8)
            logger.info("Successfully read AWS credentials file")
            return credentialsContent
        } catch {
            // Credentials file is optional
            logger.info("No AWS credentials file found (this is normal if using SSO or IAM roles)")
            return nil
        }
    }
    
    /// Clear saved bookmark and reset access
    func resetAccess() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: bookmarkVersionKey)
        securityScopedURL = nil
        hasAccess = false
        needsAccessGrant = true
        logger.info("Reset AWS config access")
    }
    
    /// Show error alert
    private func showError(title: String, message: String, window: NSWindow? = nil) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            
            if let window = window {
                alert.beginSheetModal(for: window)
            } else {
                alert.runModal()
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let awsConfigAccessGranted = Notification.Name("awsConfigAccessGranted")
    static let awsConfigAccessRevoked = Notification.Name("awsConfigAccessRevoked")
    static let awsConfigDemoMode = Notification.Name("awsConfigDemoMode")
}

// MARK: - SwiftUI View for First Run
import SwiftUI

struct AWSConfigAccessView: View {
    @ObservedObject private var accessManager = AWSConfigAccessManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("HasDismissedConfigAccess") private var hasDismissedConfigAccess: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("AWS Configuration Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("AWSCostMonitor needs permission to read your AWS configuration files to load your profiles and monitor costs.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Label("Read AWS profiles from ~/.aws/config", systemImage: "doc.text")
                Label("Access is limited to read-only", systemImage: "lock")
                Label("Your credentials remain secure", systemImage: "shield.checkered")
            }
            .font(.system(size: 13))
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack(spacing: 15) {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                
                Button("Grant Access") {
                    accessManager.requestAccess()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.top)
            
            // Later button styled as a link with explanation
            Button(action: {
                // Set flag to remember user chose to use demo mode
                hasDismissedConfigAccess = true
                // Post notification to load demo mode
                NotificationCenter.default.post(name: .awsConfigDemoMode, object: nil)
                dismiss()
            }) {
                Text("Continue with demo data instead")
                    .foregroundColor(.accentColor)
                    .underline()
            }
            .buttonStyle(.plain)
            .help("Explore the app with sample data without granting access")
            .padding(.top, 8)
        }
        .padding(30)
        .frame(width: 450)
        .onReceive(NotificationCenter.default.publisher(for: .awsConfigAccessGranted)) { _ in
            dismiss()
        }
    }
}