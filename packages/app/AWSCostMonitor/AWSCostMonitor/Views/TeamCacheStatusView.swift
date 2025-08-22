//
//  TeamCacheStatusView.swift
//  AWSCostMonitor
//
//  Team cache status display with transparency indicators
//

import SwiftUI

struct TeamCacheStatusView: View {
    @EnvironmentObject var awsManager: AWSManager
    @ObservedObject var teamCacheController: TeamCacheController
    let profileName: String
    
    @State private var countdownTimer: Timer?
    @State private var countdownString = ""
    
    private var state: TeamCacheState? {
        teamCacheController.states[profileName]
    }
    
    private var isRefreshing: Bool {
        teamCacheController.isRefreshing[profileName] ?? false
    }
    
    private var errorMessage: String? {
        teamCacheController.errorMessages[profileName]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with staleness indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(stalenessColor)
                    .frame(width: 8, height: 8)
                
                Text("Team Cache")
                    .font(.system(size: 11, weight: .semibold))
                
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                }
                
                Spacer()
            }
            
            // Last update info
            if let state = state, let lastRefreshedAt = state.lastRefreshedAt {
                VStack(alignment: .leading, spacing: 2) {
                    // Who updated when
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        
                        Text("Updated \(relativeTimeString(from: lastRefreshedAt)) by \(state.refreshedBy?.display ?? "Unknown")")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    // Data through date
                    if let asOfDate = state.asOfDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            
                            Text("Data through \(asOfDate)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No cached data available")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Refresh controls
            VStack(alignment: .leading, spacing: 4) {
                // Manual refresh button
                HStack {
                    if let state = state {
                        Button(action: {
                            Task {
                                await teamCacheController.manualRefresh(for: profileName)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10))
                                
                                if state.isManualRefreshEnabled {
                                    Text("Refresh Now")
                                        .font(.system(size: 10))
                                } else {
                                    Text("Available in \(countdownString)")
                                        .font(.system(size: 10))
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                        .disabled(!state.isManualRefreshEnabled)
                        .help(state.isManualRefreshEnabled ? 
                              "Refresh team cache now" : 
                              "Team-wide cooldown active")
                    }
                    
                    Spacer()
                }
                
                // Next auto refresh
                if let state = state {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        
                        Text("Next auto: \(timeString(from: state.nextAutoEligibleAt))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Error message if any
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
            }
            
            // Info footnote
            Text("AWS Cost Explorer updates ~2-3×/day")
                .font(.system(size: 8))
                .foregroundColor(Color.secondary)
                .italic()
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .onAppear {
            startCountdownTimer()
        }
        .onDisappear {
            stopCountdownTimer()
        }
    }
    
    // MARK: - Helper Properties
    
    private var stalenessColor: Color {
        guard let state = state else { return .gray }
        return state.staleness.color
    }
    
    // MARK: - Helper Methods
    
    private func relativeTimeString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func startCountdownTimer() {
        stopCountdownTimer()
        updateCountdown()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateCountdown()
        }
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func updateCountdown() {
        guard let state = state, !state.isManualRefreshEnabled else {
            countdownString = ""
            return
        }
        
        let remaining = state.timeUntilManualRefresh
        if remaining <= 0 {
            countdownString = "Ready"
        } else {
            let minutes = Int(remaining / 60)
            let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
            countdownString = String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

struct TeamCacheStatusView_Previews: PreviewProvider {
    static var previews: some View {
        let awsManager = AWSManager.shared
        let controller = TeamCacheController(awsManager: awsManager)
        
        // Set up preview state
        let previewState = TeamCacheState(
            teamId: "test-team",
            lastRefreshedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            refreshedBy: RefreshedBy(id: "user-123", display: "Jackson"),
            nextAutoEligibleAt: Date().addingTimeInterval(18000), // 5 hours from now
            nextManualEligibleAt: Date().addingTimeInterval(-300), // Ready now
            asOfDate: "2025-08-22",
            version: 1
        )
        
        controller.states["test-profile"] = previewState
        
        return TeamCacheStatusView(
            teamCacheController: controller,
            profileName: "test-profile"
        )
        .environmentObject(awsManager)
        .frame(width: 300)
        .padding()
    }
}