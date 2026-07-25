//
//  AWSConfigParser.swift
//  AWSCostMonitor
//
//  Section-aware parser for ~/.aws/config. INIParser treats every bracketed
//  section as a profile, which surfaced [sso-session x] blocks in the profile
//  picker as phantom entries; this classifies sections properly and reports how
//  each profile's credentials are obtained.
//

import Foundation

enum AWSConfigParser {

    private enum Section {
        case profile(String)
        case ssoSession(String)
        case ignored
    }

    static func parse(configContent: String) -> ParsedAWSConfig {
        var rawProfiles: [(name: String, keys: [String: String])] = []
        var rawSessions: [(name: String, keys: [String: String])] = []
        var current: Section = .ignored
        var keys: [String: String] = [:]

        func flush() {
            switch current {
            case .profile(let name):    rawProfiles.append((name, keys))
            case .ssoSession(let name): rawSessions.append((name, keys))
            case .ignored:              break
            }
            keys = [:]
        }

        for rawLine in configContent.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix(";") { continue }

            if line.hasPrefix("[") && line.hasSuffix("]") {
                flush()
                current = classify(header: String(line.dropFirst().dropLast()))
                continue
            }

            // Split on the first '=' only: start URLs legitimately contain '='.
            guard let sep = line.firstIndex(of: "=") else { continue }
            let key = line[line.startIndex..<sep].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: sep)...].trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { continue }
            keys[key] = value
        }
        flush()

        var sessions: [String: SSOSession] = [:]
        for raw in rawSessions {
            guard let startUrl = raw.keys["sso_start_url"],
                  let ssoRegion = raw.keys["sso_region"] else { continue }
            sessions[raw.name] = SSOSession(
                name: raw.name,
                startUrl: startUrl,
                ssoRegion: ssoRegion,
                scopes: (raw.keys["sso_registration_scopes"] ?? "sso:account:access")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            )
        }

        let profiles = rawProfiles.map { raw in
            AWSProfileConfig(
                name: raw.name,
                region: raw.keys["region"],
                source: classifySource(keys: raw.keys, sessions: sessions)
            )
        }.sorted { $0.name < $1.name }

        return ParsedAWSConfig(profiles: profiles, ssoSessions: sessions)
    }

    private static func classify(header: String) -> Section {
        if header == "default" { return .profile("default") }
        if header.hasPrefix("profile ") {
            return .profile(String(header.dropFirst("profile ".count)).trimmingCharacters(in: .whitespaces))
        }
        if header.hasPrefix("sso-session ") {
            return .ssoSession(String(header.dropFirst("sso-session ".count)).trimmingCharacters(in: .whitespaces))
        }
        // [services ...] and anything else we don't model.
        return .ignored
    }

    private static func classifySource(
        keys: [String: String],
        sessions: [String: SSOSession]
    ) -> ProfileCredentialSource {
        if let sessionName = keys["sso_session"] {
            guard let session = sessions[sessionName] else {
                return .unsupported(reason: "References unknown sso-session '\(sessionName)'.")
            }
            guard let accountId = keys["sso_account_id"], let roleName = keys["sso_role_name"] else {
                return .unsupported(reason: "SSO profile is missing sso_account_id or sso_role_name.")
            }
            return .sso(SSOProfileRef(
                sessionName: sessionName,
                startUrl: session.startUrl,
                ssoRegion: session.ssoRegion,
                accountId: accountId,
                roleName: roleName
            ))
        }

        if let startUrl = keys["sso_start_url"] {
            guard let ssoRegion = keys["sso_region"],
                  let accountId = keys["sso_account_id"],
                  let roleName = keys["sso_role_name"] else {
                return .unsupported(reason: "Legacy SSO profile is missing sso_region, sso_account_id, or sso_role_name.")
            }
            return .sso(SSOProfileRef(
                sessionName: nil,
                startUrl: startUrl,
                ssoRegion: ssoRegion,
                accountId: accountId,
                roleName: roleName
            ))
        }

        if let roleArn = keys["role_arn"] {
            guard let sourceProfile = keys["source_profile"] else {
                return .unsupported(reason: "role_arn without source_profile is not supported.")
            }
            return .assumeRole(roleArn: roleArn, sourceProfile: sourceProfile, mfaSerial: keys["mfa_serial"])
        }

        if keys["credential_process"] != nil {
            return .unsupported(reason: "credential_process profiles are not supported.")
        }

        return .staticKeys
    }
}
