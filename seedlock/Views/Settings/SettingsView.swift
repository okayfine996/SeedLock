//
//  SettingsView.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    
    // Data & Sync Settings
    @AppStorage("cloudKitSyncEnabled") private var cloudKitSyncEnabled = false
    
    // Security Settings
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage("biometricsRequired") private var biometricsRequired = false
    @AppStorage("screenshotWarningEnabled") private var screenshotWarningEnabled = false
    @AppStorage("clipboardTimeout") private var clipboardTimeout = 60
    
    @State private var showClipboardPicker = false
    @State private var showLanguagePicker = false
    @State private var iCloudAccount: String? = nil
    @State private var isSignedIntoiCloud = false
    @State private var isCheckingiCloud = true
    @State private var cloudKitSyncStatus: String = "Checking..."
    @State private var showSyncAlert = false
    @State private var syncAlertMessage = ""
    @State private var showRestartAlert = false
    @State private var navigateToEnableAppLock = false
    @State private var navigateToEnableBiometrics = false
    
    // Computed property for iCloud status (updates with language changes)
    private var iCloudStatus: String {
        if isCheckingiCloud {
            return "settings.icloud_checking".localized
        }
        return isSignedIntoiCloud ? "settings.icloud_connected".localized : "settings.icloud_not_signed_in".localized
    }
    
    // Computed property for app version
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // DATA & SYNC Section
                    sectionHeader("settings.section.data_sync".localized)
                    
                    VStack(spacing: 0) {
                        // iCloud Account (enhanced with storage info)
                        iCloudAccountRow
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // iCloud Sync (CloudKit + Keychain)
                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                icon: "icloud.fill",
                                iconColor: .appPrimary,
                                title: "settings.icloud_sync".localized,
                                isOn: $cloudKitSyncEnabled
                            )
                            .onChange(of: cloudKitSyncEnabled) { oldValue, newValue in
                                handleCloudKitSyncToggle(newValue)
                            }
                            
                            // Description
                            HStack {
                                Text("settings.icloud_sync_description".localized)
                                    .font(.system(size: 13))
                                    .foregroundColor(.appSecondaryLabel)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 68)
                            .padding(.bottom, 12)
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Backup & Restore
                        NavigationLink(destination: BackupView()) {
                            SettingsRow(
                                icon: "arrow.up.doc",
                                iconColor: .appPrimary,
                                title: "settings.backup_restore".localized,
                                showChevron: true
                            )
                        }
                    }
                    .background(Color.appSurface)
                    .cornerRadius(Theme.radiusMedium)
                    .padding(.horizontal, Theme.spacing16)
                    .padding(.bottom, Theme.spacing32)
                    
                    // SECURITY Section
                    sectionHeader("settings.section.security".localized)
                    
                    VStack(spacing: 0) {
                        // App Lock - Navigate to enable page
                        NavigationLink(
                            destination: EnableAppLockView(navigateToEnableAppLock: $navigateToEnableAppLock),
                            isActive: $navigateToEnableAppLock
                        ) {
                            EmptyView()
                        }
                        .hidden()
                        
                        SettingsToggleRow(
                            icon: "lock",
                            iconColor: .appPrimary,
                            title: "settings.app_lock".localized,
                            isOn: $appLockEnabled
                        )
                        .onChange(of: appLockEnabled) { oldValue, newValue in
                            handleAppLockToggle(oldValue: oldValue, newValue: newValue)
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Require Biometrics to View - Navigate to enable page
                        NavigationLink(
                            destination: EnableBiometricsView(navigateToEnableBiometrics: $navigateToEnableBiometrics),
                            isActive: $navigateToEnableBiometrics
                        ) {
                            EmptyView()
                        }
                        .hidden()
                        
                        SettingsToggleRow(
                            icon: "faceid",
                            iconColor: .appPrimary,
                            title: "settings.require_biometrics".localized,
                            isOn: $biometricsRequired
                        )
                        .onChange(of: biometricsRequired) { oldValue, newValue in
                            handleBiometricsRequiredToggle(oldValue: oldValue, newValue: newValue)
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Clipboard Timeout
                        Button(action: {
                            showClipboardPicker = true
                        }) {
                            SettingsRow(
                                icon: "clipboard",
                                iconColor: .appPrimary,
                                title: "settings.clipboard_timeout".localized,
                                value: formatClipboardTimeout(clipboardTimeout),
                                showChevron: true
                            )
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Screenshot Warning
                        SettingsToggleRow(
                            icon: "tv",
                            iconColor: .appPrimary,
                            title: "settings.screenshot_warning".localized,
                            isOn: $screenshotWarningEnabled
                        )
                    }
                    .background(Color.appSurface)
                    .cornerRadius(Theme.radiusMedium)
                    .padding(.horizontal, Theme.spacing16)
                    .padding(.bottom, Theme.spacing32)
                    
                    // APPEARANCE Section
                    sectionHeader("settings.section.appearance".localized)
                    
                    VStack(spacing: 0) {
                        // Language Selection
                        Button(action: {
                            showLanguagePicker = true
                        }) {
                            SettingsRow(
                                icon: "globe",
                                iconColor: .appPrimary,
                                title: "language.settings_title".localized,
                                value: languageManager.currentLanguage.nativeName,
                                showChevron: true
                            )
                        }
                    }
                    .background(Color.appSurface)
                    .cornerRadius(Theme.radiusMedium)
                    .padding(.horizontal, Theme.spacing16)
                    .padding(.bottom, Theme.spacing32)
                    
                    // ABOUT Section
                    sectionHeader("settings.section.about".localized)
                    
                    VStack(spacing: 0) {
                        // Security Whitepaper
                        NavigationLink(destination: SecurityWhitepaperView()) {
                            SettingsRow(
                                icon: "lock.shield.fill",
                                iconColor: .appPrimary,
                                title: "settings.security_whitepaper".localized,
                                showChevron: true
                            )
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // About & Privacy
                        NavigationLink(destination: AboutPrivacyView()) {
                            SettingsRow(
                                icon: "hand.raised.fill",
                                iconColor: .appPrimary,
                                title: "settings.about_privacy".localized,
                                showChevron: true
                            )
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Diagnostics
                        NavigationLink(destination: DiagnosticsView()) {
                            SettingsRow(
                                icon: "chart.bar.doc.horizontal",
                                iconColor: .appPrimary,
                                title: "settings.diagnostics".localized,
                                showChevron: true
                            )
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // App Version
                        SettingsRow(
                            icon: "info.circle",
                            iconColor: .appPrimary,
                            title: "settings.app_version".localized,
                            value: appVersion
                        )
                        
                        
                    }
                    .background(Color.appSurface)
                    .cornerRadius(Theme.radiusMedium)
                    .padding(.horizontal, Theme.spacing16)
                    .padding(.bottom, Theme.spacing32)
                }
                .padding(.top, Theme.spacing8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("common.settings".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.appLabel)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("common.back".localized)
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
        .confirmationDialog("settings.clipboard_timeout".localized, isPresented: $showClipboardPicker) {
            Button("settings.clipboard.30_seconds".localized) { clipboardTimeout = 30 }
            Button("settings.clipboard.1_minute".localized) { clipboardTimeout = 60 }
            Button("settings.clipboard.2_minutes".localized) { clipboardTimeout = 120 }
            Button("settings.clipboard.5_minutes".localized) { clipboardTimeout = 300 }
            Button("common.cancel".localized, role: .cancel) {}
        } message: {
            Text("settings.clipboard_timeout_message".localized)
        }
        .confirmationDialog("language.select_language".localized, isPresented: $showLanguagePicker) {
            ForEach(LanguageManager.Language.allCases, id: \.self) { language in
                Button(language.nativeName) {
                    languageManager.currentLanguage = language
                }
            }
            Button("common.cancel".localized, role: .cancel) {}
        }
        .onAppear {
            checkiCloudStatus()
            checkCloudKitStatus()
            
            // Log event
            DiagnosticsLogger.shared.logEvent(.info, title: "Settings Accessed")
        }
        .alert("alert.sync_status".localized, isPresented: $showSyncAlert) {
            Button("common.ok".localized, role: .cancel) {}
        } message: {
            Text(syncAlertMessage)
        }
        .alert("settings.restart_required_title".localized, isPresented: $showRestartAlert) {
            Button("common.ok".localized, role: .cancel) {}
        } message: {
            Text("settings.restart_required_message".localized)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.appSecondaryLabel)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.spacing24)
            .padding(.bottom, Theme.spacing8)
    }
    
    // MARK: - Custom Rows
    
    private var iCloudAccountRow: some View {
        Button(action: {
            // Open iOS Settings app to iCloud settings
            if let url = URL(string: "App-Prefs:root=CASTLE") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: Theme.spacing12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSignedIntoiCloud ? Color.appPrimary.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isSignedIntoiCloud ? "cloud.fill" : "exclamationmark.icloud")
                        .font(.system(size: 18))
                        .foregroundColor(isSignedIntoiCloud ? .appPrimary : .orange)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("settings.icloud_account".localized)
                        .font(.system(size: 17))
                        .foregroundColor(.appLabel)
                    
                    // Status info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            // Status indicator
                            Circle()
                                .fill(isSignedIntoiCloud ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)
                            
                            Text(iCloudStatus)
                                .font(.system(size: 13))
                                .foregroundColor(.appSecondaryLabel)
                        }
                        
                        // Show sync status when connected
                        if isSignedIntoiCloud {
                            if cloudKitSyncEnabled {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.green)
                                    Text("settings.icloud_sync_active".localized)
                                        .font(.system(size: 11))
                                        .foregroundColor(.appTertiaryLabel)
                                }
                            } else {
                                Text("settings.icloud_sync_disabled".localized)
                                    .font(.system(size: 11))
                                    .foregroundColor(.appTertiaryLabel)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                if isSignedIntoiCloud {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appSecondaryLabel)
                }
            }
            .padding(Theme.spacing16)
            .background(Color.appSurface)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Functions
    
    private func checkiCloudStatus() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Check if user is signed into iCloud
            if let token = FileManager.default.ubiquityIdentityToken {
                // User is signed in
                DispatchQueue.main.async {
                    isSignedIntoiCloud = true
                    isCheckingiCloud = false
                    iCloudAccount = "Tap to view in Settings"
                }
            } else {
                // User is not signed into iCloud
                DispatchQueue.main.async {
                    isSignedIntoiCloud = false
                    isCheckingiCloud = false
                    iCloudAccount = nil
                }
            }
        }
    }
    
    private func formatClipboardTimeout(_ seconds: Int) -> String {
        if seconds < 60 {
            return String(format: "time.seconds".localized, seconds)
        } else {
            let minutes = seconds / 60
            return minutes == 1 ? "time.minute".localized : String(format: "time.minutes".localized, minutes)
        }
    }
    
    // MARK: - CloudKit Sync Handlers
    
    private func handleCloudKitSyncToggle(_ enabled: Bool) {
        // Check if this is the first time enabling CloudKit
        let wasEverEnabled = UserDefaults.standard.bool(forKey: "cloudKitWasEverEnabled")
        
        // Check iCloud login status first
        guard isSignedIntoiCloud else {
            cloudKitSyncEnabled = false
            syncAlertMessage = "alert.icloud_not_available".localized
            showSyncAlert = true
            return
        }
        
        CloudKitSyncService.shared.checkAvailability { status in
            switch status {
            case .available:
                CloudKitSyncService.shared.setSyncEnabled(enabled)
                
                // Also sync Keychain setting (always match CloudKit setting)
                Task {
                    do {
                        try await KeychainService.shared.setKeychainSyncEnabled(enabled)
                        print("✅ Keychain sync setting updated successfully")
                    } catch {
                        print("⚠️ Failed to update Keychain sync setting: \(error.localizedDescription)")
                        // Log error but don't fail the entire operation
                        DiagnosticsLogger.shared.logEvent(.error, title: "Keychain Sync Update Failed")
                    }
                }
                
                // Notify sync monitor
                CloudKitSyncMonitor.shared.handleCloudKitToggle(enabled: enabled)
                
                // Log event
                if enabled {
                    DiagnosticsLogger.shared.logEvent(.success, title: "iCloud Sync Enabled (CloudKit + Keychain)")
                    
                    // Mark as ever enabled
                    UserDefaults.standard.set(true, forKey: "cloudKitWasEverEnabled")
                    
                    // If first time enabling, show restart alert
                    if !wasEverEnabled {
                        print("⚠️ First time enabling iCloud Sync, restart required")
                        showRestartAlert = true
                    } else {
                        syncAlertMessage = "alert.icloud_sync_enabled".localized
                        showSyncAlert = true
                    }
                } else {
                    DiagnosticsLogger.shared.logEvent(.info, title: "iCloud Sync Disabled")
                    syncAlertMessage = "alert.icloud_sync_disabled".localized
                    showSyncAlert = true
                }
                
            case .notAvailable:
                cloudKitSyncEnabled = false
                syncAlertMessage = "alert.icloud_not_available".localized
                showSyncAlert = true
                DiagnosticsLogger.shared.logEvent(.error, title: "iCloud Sync Failed: Not Available")
                
            case .error(let message):
                cloudKitSyncEnabled = false
                syncAlertMessage = "CloudKit error: \(message)"
                showSyncAlert = true
                DiagnosticsLogger.shared.logEvent(.error, title: "iCloud Sync Error")
                
            case .syncing:
                break
            }
        }
    }
    
    
    private func checkCloudKitStatus() {
        CloudKitSyncService.shared.checkAvailability { status in
            switch status {
            case .available:
                cloudKitSyncStatus = "Available"
            case .notAvailable:
                cloudKitSyncStatus = "Not signed in"
                cloudKitSyncEnabled = false
            case .error(let message):
                cloudKitSyncStatus = "Error: \(message)"
                cloudKitSyncEnabled = false
            case .syncing:
                cloudKitSyncStatus = "Syncing..."
            }
        }
    }
    
    private func handleAppLockToggle(oldValue: Bool, newValue: Bool) {
        if newValue && !oldValue {
            // Trying to enable App Lock
            // Check if biometric is available
            guard BiometricService.shared.isBiometricAvailable() else {
                appLockEnabled = false
                syncAlertMessage = "alert.biometric_not_available".localized
                showSyncAlert = true
                return
            }
            
            // Navigate to enable page (don't reset toggle here, let EnableAppLockView handle it)
            navigateToEnableAppLock = true
        } else if !newValue && oldValue {
            // Disabling App Lock - no alert needed, just disable silently
            // The toggle already reflects the change
            
            // Log event
            DiagnosticsLogger.shared.logEvent(.info, title: "App Lock Disabled")
            
            navigateToEnableAppLock = false // Ensure navigation is reset
        }
    }
    
    private func handleBiometricsRequiredToggle(oldValue: Bool, newValue: Bool) {
        if newValue && !oldValue {
            // Trying to enable Biometric Requirement
            // Check if biometric is available
            guard BiometricService.shared.isBiometricAvailable() else {
                biometricsRequired = false
                syncAlertMessage = "alert.biometric_not_available".localized
                showSyncAlert = true
                return
            }
            
            // Navigate to enable page (don't reset toggle here, let EnableBiometricsView handle it)
            navigateToEnableBiometrics = true
        } else if !newValue && oldValue {
            // Disabling Biometric Requirement - no alert needed
            
            // Log event
            DiagnosticsLogger.shared.logEvent(.info, title: "Biometric Requirement Disabled")
            
            navigateToEnableBiometrics = false // Ensure navigation is reset
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String = ""
    var showChevron: Bool = false
    
    var body: some View {
        HStack(spacing: Theme.spacing12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
            
            // Title
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.appLabel)
            
            Spacer()
            
            // Value
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 17))
                    .foregroundColor(.appSecondaryLabel)
            }
            
            // Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTertiaryLabel)
            }
        }
        .padding(.horizontal, Theme.spacing16)
        .padding(.vertical, Theme.spacing12)
        .contentShape(Rectangle())
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: Theme.spacing12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
            
            // Title
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.appLabel)
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.appPrimary)
        }
        .padding(.horizontal, Theme.spacing16)
        .padding(.vertical, Theme.spacing12)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
