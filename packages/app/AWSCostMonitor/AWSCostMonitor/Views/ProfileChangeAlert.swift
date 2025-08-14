//
//  ProfileChangeAlert.swift
//  AWSCostMonitor
//
//  Alerts for profile changes detection
//

import SwiftUI

// MARK: - New Profiles Alert

struct NewProfilesAlert: View {
    let newProfiles: [AWSProfile]
    let onAdd: ([String]) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedProfiles: Set<String> = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("New AWS Profiles Detected")
                        .font(.headline)
                    Text("Found \(newProfiles.count) new profile\(newProfiles.count == 1 ? "" : "s") in your AWS configuration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Profile list
            VStack(alignment: .leading, spacing: 8) {
                Text("Select profiles to add to your dropdown:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(newProfiles, id: \.name) { profile in
                    HStack {
                        Button(action: {
                            if selectedProfiles.contains(profile.name) {
                                selectedProfiles.remove(profile.name)
                            } else {
                                selectedProfiles.insert(profile.name)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedProfiles.contains(profile.name) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selectedProfiles.contains(profile.name) ? .blue : .secondary)
                                
                                VStack(alignment: .leading) {
                                    Text(profile.name)
                                        .font(.body)
                                    if let region = profile.region {
                                        Text("Region: \(region)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    .background(selectedProfiles.contains(profile.name) ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(4)
                }
            }
            
            // Action buttons
            HStack {
                Button("Select All") {
                    selectedProfiles = Set(newProfiles.map { $0.name })
                }
                .disabled(selectedProfiles.count == newProfiles.count)
                
                Spacer()
                
                Button("Skip") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Add Selected") {
                    onAdd(Array(selectedProfiles))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProfiles.isEmpty)
            }
        }
        .padding()
        .frame(maxWidth: 500)
        .onAppear {
            // Select all profiles by default
            selectedProfiles = Set(newProfiles.map { $0.name })
        }
    }
}

// MARK: - Removed Profiles Alert

struct RemovedProfilesAlert: View {
    let removedProfiles: [String]
    let onRemove: ([String]) -> Void
    let onKeep: ([String]) -> Void
    let onDismiss: () -> Void
    
    @State private var profileActions: [String: ProfileAction] = [:]
    
    enum ProfileAction: CaseIterable {
        case remove, keep
        
        var title: String {
            switch self {
            case .remove: return "Remove"
            case .keep: return "Keep (view-only)"
            }
        }
        
        var description: String {
            switch self {
            case .remove: return "Delete all data and remove from dropdown"
            case .keep: return "Keep data for viewing, mark as (removed)"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.badge.minus")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading) {
                    Text("Profiles No Longer Available")
                        .font(.headline)
                    Text("These profiles are no longer in your AWS configuration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Profile list with actions
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose what to do with each profile:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(removedProfiles, id: \.self) { profileName in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(profileName)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        HStack {
                            ForEach(ProfileAction.allCases, id: \.self) { action in
                                Button(action: {
                                    profileActions[profileName] = action
                                }) {
                                    HStack {
                                        Image(systemName: profileActions[profileName] == action ? "circle.fill" : "circle")
                                            .foregroundColor(profileActions[profileName] == action ? .blue : .secondary)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(action.title)
                                                .font(.subheadline)
                                            Text(action.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Action buttons
            HStack {
                Button("Keep All") {
                    for profile in removedProfiles {
                        profileActions[profile] = .keep
                    }
                }
                
                Spacer()
                
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Apply") {
                    let toRemove = profileActions.compactMap { key, value in
                        value == .remove ? key : nil
                    }
                    let toKeep = profileActions.compactMap { key, value in
                        value == .keep ? key : nil
                    }
                    
                    if !toRemove.isEmpty {
                        onRemove(toRemove)
                    }
                    if !toKeep.isEmpty {
                        onKeep(toKeep)
                    }
                    
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(profileActions.count != removedProfiles.count)
            }
        }
        .padding()
        .frame(maxWidth: 600)
        .onAppear {
            // Default to keeping profiles
            for profile in removedProfiles {
                profileActions[profile] = .keep
            }
        }
    }
}

// MARK: - Profile Change Window Controller

class ProfileChangeWindowController: NSWindowController {
    static func showNewProfilesAlert(newProfiles: [AWSProfile], onAdd: @escaping ([String]) -> Void, onDismiss: @escaping () -> Void) {
        let contentView = NewProfilesAlert(
            newProfiles: newProfiles,
            onAdd: onAdd,
            onDismiss: onDismiss
        )
        
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        
        window.title = "New Profiles Detected"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .modalPanel
        
        let controller = ProfileChangeWindowController(window: window)
        window.delegate = controller
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    static func showRemovedProfilesAlert(
        removedProfiles: [String],
        onRemove: @escaping ([String]) -> Void,
        onKeep: @escaping ([String]) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        let contentView = RemovedProfilesAlert(
            removedProfiles: removedProfiles,
            onRemove: onRemove,
            onKeep: onKeep,
            onDismiss: onDismiss
        )
        
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        
        window.title = "Profiles Removed"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .modalPanel
        
        let controller = ProfileChangeWindowController(window: window)
        window.delegate = controller
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension ProfileChangeWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clean up the window controller
    }
}