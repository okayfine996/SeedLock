//
//  BackupView.swift
//  seedlock
//
//  Backup and restore management interface
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var mnemonics: [Mnemonic]
    
    @State private var restorePassword = ""
    @State private var backupPassword = ""
    @State private var confirmPassword = ""
    
    @State private var isCreatingBackup = false
    @State private var isRestoring = false
    @State private var isLoadingBackups = false
    
    @State private var showSetPasswordSheet = false
    @State private var showRestoreSheet = false
    @State private var showBackupPicker = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    
    @State private var iCloudBackups: [BackupFileInfo] = []
    @State private var selectedBackupURL: URL?
    
    @AppStorage("autoBackupEnabled") private var autoBackupEnabled = false
    @AppStorage("autoBackupInterval") private var autoBackupInterval = 7 // days
    
    private var lastAutoBackupDate: Date? {
        get {
            guard UserDefaults.standard.object(forKey: "lastAutoBackupDate") != nil else {
                return nil
            }
            let timestamp = UserDefaults.standard.double(forKey: "lastAutoBackupDate")
            
            // Check if timestamp is valid (greater than 0, which means after 1970-01-01)
            guard timestamp > 0 else {
                return nil
            }
            
            return Date(timeIntervalSince1970: timestamp)
        }
    }
    
    private var hasBackupPassword: Bool {
        if let password = UserDefaults.standard.string(forKey: "backupPassword"),
           !password.isEmpty {
            return true
        }
        return false
    }
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing24) {
                    // Auto Backup Section
                    autoBackupSection
                    
                    // iCloud Backups List
                    if !iCloudBackups.isEmpty {
                        iCloudBackupsSection
                    }
                    
                    // Restore Section
                    restoreSection
                    
                    // Info Section
                    infoSection
                }
                .padding(.horizontal, Theme.spacing16)
                .padding(.vertical, Theme.spacing16)
            }
        }
        .navigationTitle("backup.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadiCloudBackups()
        }
        .onAppear {
            // Clean up invalid 0.0 timestamp from old versions
            if let obj = UserDefaults.standard.object(forKey: "lastAutoBackupDate") {
                let timestamp = UserDefaults.standard.double(forKey: "lastAutoBackupDate")
                if timestamp == 0.0 {
                    print("🧹 Cleaning up invalid lastAutoBackupDate (0.0)")
                    UserDefaults.standard.removeObject(forKey: "lastAutoBackupDate")
                    UserDefaults.standard.synchronize()
                }
            }
        }
        .sheet(isPresented: $showSetPasswordSheet) {
            setPasswordSheet
        }
        .sheet(isPresented: $showRestoreSheet) {
            restoreBackupPasswordSheet
        }
        .fileImporter(
            isPresented: $showBackupPicker,
            allowedContentTypes: [UTType(filenameExtension: "seedlock") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            handleBackupFileSelection(result)
        }
        .alert("common.success".localized, isPresented: $showSuccessAlert) {
            Button("common.ok".localized) { }
        } message: {
            Text(alertMessage)
        }
        .alert("common.error".localized, isPresented: $showErrorAlert) {
            Button("common.ok".localized) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Auto Backup Section
    
    private var autoBackupSection: some View {
        VStack(spacing: Theme.spacing16) {
            sectionHeader("backup.section.auto".localized)
            
            // Hint if no password set
            if !hasBackupPassword {
                HStack(spacing: Theme.spacing12) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    
                    Text("backup.auto_backup_hint".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryLabel)
                    
                    Spacer()
                }
                .padding(Theme.spacing12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(Theme.radiusSmall)
            }
            
            VStack(spacing: 0) {
                // Enable Auto Backup Toggle
                Toggle(isOn: $autoBackupEnabled) {
                    HStack(spacing: Theme.spacing12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }
                        
                        Text("backup.auto_backup".localized)
                            .font(.system(size: 17))
                            .foregroundColor(.appLabel)
                    }
                }
                .padding(Theme.spacing16)
                .onChange(of: autoBackupEnabled) { oldValue, newValue in
                    if newValue && !hasBackupPassword {
                        // Need to set password first
                        autoBackupEnabled = false
                        showSetPasswordSheet = true
                    } else if newValue && !oldValue {
                        // Log event when enabling auto backup
                        DiagnosticsLogger.shared.logEvent(.success, title: "Auto Backup Enabled")
                    } else if !newValue && oldValue {
                        // Log event when disabling auto backup
                        DiagnosticsLogger.shared.logEvent(.info, title: "Auto Backup Disabled")
                    }
                }
                
                if autoBackupEnabled {
                    Divider()
                        .padding(.leading, 68)
                    
                    // Backup Interval Picker
                    HStack {
                        HStack(spacing: Theme.spacing12) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "calendar")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                            }
                            
                            Text("backup.backup_interval".localized)
                                .font(.system(size: 17))
                                .foregroundColor(.appLabel)
                        }
                        
                        Spacer()
                        
                        Picker("", selection: $autoBackupInterval) {
                            Text("backup.interval.daily".localized).tag(1)
                            Text("backup.interval.weekly".localized).tag(7)
                            Text("backup.interval.monthly".localized).tag(30)
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(Theme.spacing16)
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // Last Backup Info
                    HStack(spacing: Theme.spacing12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "info.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("backup.last_backup".localized)
                                .font(.system(size: 17))
                                .foregroundColor(.appLabel)
                            
                            Text(lastBackupDateString)
                                .font(.system(size: 13))
                                .foregroundColor(.appSecondaryLabel)
                        }
                        
                        Spacer()
                    }
                    .padding(Theme.spacing16)
                    
                    Divider()
                        .padding(.leading, 68)
                    
                    // Backup Now Button
                    Button(action: performAutoBackupNow) {
                        HStack(spacing: Theme.spacing12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)
                            }
                            
                            Text("backup.backup_now".localized)
                                .font(.system(size: 17))
                                .foregroundColor(.appLabel)
                            
                            Spacer()
                            
                            if isCreatingBackup {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appSecondaryLabel)
                            }
                        }
                        .padding(Theme.spacing16)
                    }
                    .disabled(isCreatingBackup || mnemonics.isEmpty)
                }
            }
            .background(Color.appSurface)
            .cornerRadius(Theme.radiusMedium)
        }
    }
    
    // MARK: - iCloud Backups Section
    
    private var iCloudBackupsSection: some View {
        VStack(spacing: Theme.spacing16) {
            HStack {
                sectionHeader("backup.section.icloud_backups".localized)
                Spacer()
                Button(action: { Task { await loadiCloudBackups() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(.appPrimary)
                }
            }
            
            VStack(spacing: Theme.spacing12) {
                // Show maximum 4 backups
                ForEach(iCloudBackups.prefix(4)) { backup in
                    backupRow(backup)
                }
                
                // Show "View All" button if there are more than 4 backups
                if iCloudBackups.count > 4 {
                    NavigationLink(destination: AllBackupsView(iCloudBackups: iCloudBackups, selectedBackupURL: $selectedBackupURL, showRestoreSheet: $showRestoreSheet)) {
                        HStack(spacing: Theme.spacing12) {
                            ZStack {
                                Circle()
                                    .fill(Color.appSecondaryLabel.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18))
                                    .foregroundColor(.appSecondaryLabel)
                            }
                            
                            Text(String(format: "backup.view_all".localized, iCloudBackups.count))
                                .font(.system(size: 17))
                                .foregroundColor(.appPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appSecondaryLabel)
                        }
                        .padding(Theme.spacing16)
                        .background(Color.appSurface)
                        .cornerRadius(Theme.radiusMedium)
                    }
                }
            }
        }
    }
    
    private func backupRow(_ backup: BackupFileInfo) -> some View {
        HStack(spacing: Theme.spacing12) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "cloud.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.appPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.dateString)
                    .font(.system(size: 17))
                    .foregroundColor(.appLabel)
                
                Text(String(format: "backup.mnemonics_count".localized, backup.mnemonicCount) + " • \(backup.sizeString)")
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryLabel)
            }
            
            Spacer()
            
            Menu {
                Button(action: {
                    selectedBackupURL = backup.url
                    showRestoreSheet = true
                }) {
                    Label("backup.menu.restore".localized, systemImage: "arrow.down.doc")
                }
                
                Button(role: .destructive, action: {
                    Task { await deleteBackup(backup) }
                }) {
                    Label("backup.menu.delete".localized, systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.appSecondaryLabel)
            }
        }
        .padding(Theme.spacing16)
        .background(Color.appSurface)
        .cornerRadius(Theme.radiusMedium)
    }
    
    // MARK: - Restore Section
    
    private var restoreSection: some View {
        VStack(spacing: Theme.spacing16) {
            sectionHeader("backup.section.restore".localized)
            
            Button(action: { showBackupPicker = true }) {
                HStack(spacing: Theme.spacing12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                    }
                    
                    Text("backup.restore_from_file".localized)
                        .font(.system(size: 17))
                        .foregroundColor(.appLabel)
                    
                    Spacer()
                    
                    if isRestoring {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appSecondaryLabel)
                    }
                }
                .padding(Theme.spacing16)
            }
            .disabled(isRestoring)
            .background(Color.appSurface)
            .cornerRadius(Theme.radiusMedium)
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(spacing: Theme.spacing16) {
            sectionHeader("backup.section.about".localized)
            
            VStack(alignment: .leading, spacing: Theme.spacing12) {
                infoRow(
                    icon: "lock.shield",
                    title: "backup.info.encrypted.title".localized,
                    description: "backup.info.encrypted.description".localized
                )
                
                infoRow(
                    icon: "icloud",
                    title: "backup.info.icloud.title".localized,
                    description: "backup.info.icloud.description".localized
                )
                
                infoRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "backup.info.sync.title".localized,
                    description: "backup.info.sync.description".localized
                )
                
                infoRow(
                    icon: "exclamationmark.triangle",
                    title: "backup.info.important.title".localized,
                    description: "backup.info.important.description".localized
                )
            }
            .padding(Theme.spacing16)
            .background(Color.appSurface)
            .cornerRadius(Theme.radiusMedium)
        }
    }
    
    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Theme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.appPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appLabel)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
    
    // MARK: - Password Sheets
    
    private var setPasswordSheet: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: Theme.spacing24) {
                    // Header
                    VStack(spacing: Theme.spacing8) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 48))
                            .foregroundColor(.appPrimary)
                        
                        Text("backup.set_password.title".localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.appLabel)
                        
                        Text("backup.set_password.message".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacing16)
                    }
                    .padding(.top, Theme.spacing24)
                    
                    // Password Fields
                    VStack(spacing: Theme.spacing16) {
                        SecureField("backup.password.placeholder".localized, text: $backupPassword)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(.newPassword)
                        
                        SecureField("backup.password.confirm".localized, text: $confirmPassword)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(.newPassword)
                    }
                    .padding(.horizontal, Theme.spacing24)
                    
                    Spacer()
                    
                    // Set Password & Backup Button
                    Button(action: setPasswordAndBackup) {
                        if isCreatingBackup {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("backup.set_password.button".localized)
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacing16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusLarge)
                            .fill(passwordsValid ? Color.appPrimary : Color.appSecondaryLabel)
                    )
                    .padding(.horizontal, Theme.spacing24)
                    .disabled(!passwordsValid || isCreatingBackup)
                    
                    Button("common.cancel".localized) {
                        showSetPasswordSheet = false
                        backupPassword = ""
                        confirmPassword = ""
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.appPrimary)
                    .padding(.bottom, Theme.spacing24)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var restoreBackupPasswordSheet: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: Theme.spacing24) {
                    // Header
                    VStack(spacing: Theme.spacing8) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("backup.restore_password.title".localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.appLabel)
                        
                        Text("backup.restore_password.message".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacing16)
                    }
                    .padding(.top, Theme.spacing24)
                    
                    // Password Field
                    SecureField("backup.password.placeholder".localized, text: $restorePassword)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.password)
                        .padding(.horizontal, Theme.spacing24)
                    
                    Spacer()
                    
                    // Restore Button
                    Button(action: restoreBackup) {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("backup.restore_password.button".localized)
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacing16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusLarge)
                            .fill(!restorePassword.isEmpty ? Color.orange : Color.appSecondaryLabel)
                    )
                    .padding(.horizontal, Theme.spacing24)
                    .disabled(restorePassword.isEmpty || isRestoring)
                    
                    Button("common.cancel".localized) {
                        showRestoreSheet = false
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.appPrimary)
                    .padding(.bottom, Theme.spacing24)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.appSecondaryLabel)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var passwordsValid: Bool {
        !backupPassword.isEmpty &&
        backupPassword == confirmPassword &&
        backupPassword.count >= 6
    }
    
    private var lastBackupDateString: String {
        guard let date = lastAutoBackupDate else {
            return "backup.last_backup.never".localized
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = LanguageManager.shared.currentLocale
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Actions
    
    private func setPasswordAndBackup() {
        guard passwordsValid else { return }
        
        isCreatingBackup = true
        
        Task {
            do {
                // Create backup
                let backupURL = try await BackupService.shared.createBackup(
                    mnemonics: mnemonics,
                    password: backupPassword
                )
                
                // Save to iCloud Drive
                _ = try await BackupService.shared.saveToiCloudDrive(backupURL)
                
                // Save password for future use (both manual and auto backup)
                UserDefaults.standard.set(backupPassword, forKey: "backupPassword")
                
                // Record backup
                BackupService.shared.recordAutoBackup()
                let timestamp = Date().timeIntervalSince1970
                UserDefaults.standard.set(timestamp, forKey: "lastAutoBackupDate")
                UserDefaults.standard.synchronize()
                
                // Reload backups
                await loadiCloudBackups()
                
                await MainActor.run {
                    isCreatingBackup = false
                    showSetPasswordSheet = false
                    backupPassword = ""
                    confirmPassword = ""
                    
                    // Auto enable auto backup after setting password
                    autoBackupEnabled = true
                    
                    alertMessage = "backup.success.set_password".localized
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isCreatingBackup = false
                    alertMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func restoreBackup() {
        guard let url = selectedBackupURL, !restorePassword.isEmpty else { return }
        
        isRestoring = true
        
        Task {
            do {
                let count = try await BackupService.shared.restoreBackup(
                    from: url,
                    password: restorePassword,
                    context: modelContext
                )
                
                await MainActor.run {
                    isRestoring = false
                    showRestoreSheet = false
                    restorePassword = ""
                    selectedBackupURL = nil
                    alertMessage = String(format: "backup.success.restored".localized, count)
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    alertMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func performAutoBackupNow() {
        // Get saved backup password
        guard let backupPassword = UserDefaults.standard.string(forKey: "backupPassword"),
              !backupPassword.isEmpty else {
            // If no password, show the password setup sheet
            showSetPasswordSheet = true
            return
        }
        
        isCreatingBackup = true
        
        Task {
            do {
                // Create backup
                let backupURL = try await BackupService.shared.createBackup(
                    mnemonics: mnemonics,
                    password: backupPassword
                )
                
                // Save to iCloud Drive
                _ = try await BackupService.shared.saveToiCloudDrive(backupURL)
                
                // Record backup
                BackupService.shared.recordAutoBackup()
                let timestamp = Date().timeIntervalSince1970
                UserDefaults.standard.set(timestamp, forKey: "lastAutoBackupDate")
                UserDefaults.standard.synchronize()
                
                // Reload backups
                await loadiCloudBackups()
                
                await MainActor.run {
                    isCreatingBackup = false
                    alertMessage = "backup.success.created".localized
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isCreatingBackup = false
                    alertMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func handleBackupFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedBackupURL = url
            showRestoreSheet = true
        case .failure(let error):
            alertMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func loadiCloudBackups() async {
        isLoadingBackups = true
        do {
            let backups = try await BackupService.shared.listBackupsFromiCloudDrive()
            await MainActor.run {
                iCloudBackups = backups
                isLoadingBackups = false
            }
        } catch {
            await MainActor.run {
                isLoadingBackups = false
            }
        }
    }
    
    private func deleteBackup(_ backup: BackupFileInfo) async {
        do {
            try await BackupService.shared.deleteBackup(at: backup.url)
            await loadiCloudBackups()
        } catch {
            await MainActor.run {
                alertMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        BackupView()
            .modelContainer(for: Mnemonic.self, inMemory: true)
    }
}

