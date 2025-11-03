//
//  seedlockApp.swift
//  seedlock
//
//  Created by Fine Ke on 20/10/2025.
//

import SwiftUI
import SwiftData

@main
struct seedlockApp: App {
    @AppStorage("cloudKitSyncEnabled") private var cloudKitSyncEnabled = false
    @ObservedObject private var languageManager = LanguageManager.shared
    
    // Initialize AppLockService early to register lifecycle observers
    private let appLockService = AppLockService.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Mnemonic.self,
        ])
        
        // Check if CloudKit sync is enabled
        // Note: This is read at app startup time
        let syncEnabled = UserDefaults.standard.bool(forKey: "cloudKitSyncEnabled")
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: syncEnabled ? .automatic : .none
        )

        do {
            print("📦 ModelContainer initialized with CloudKit: \(syncEnabled ? "enabled" : "disabled")")
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .environment(\.cloudKitSyncEnabled, cloudKitSyncEnabled)
                .onAppear {
                    // Log app launch
                    DiagnosticsLogger.shared.logEvent(.success, title: "App Launched")
                    
                    // Note: Database migration already performed before ModelContainer creation
                    // Configure CloudKit sync monitor with model context
                    let context = sharedModelContainer.mainContext
                    CloudKitSyncMonitor.shared.configure(with: context)
                    
                    // Check and perform auto backup if needed
                    checkAutoBackup()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Auto Backup
    
    private func checkAutoBackup() {
        guard BackupService.shared.shouldPerformAutoBackup() else {
            print("⏭️ Auto backup not needed yet")
            return
        }
        
        print("🔄 Performing automatic backup...")
        
        Task {
            do {
                // Fetch all mnemonics
                let context = sharedModelContainer.mainContext
                let descriptor = FetchDescriptor<Mnemonic>()
                let mnemonics = try context.fetch(descriptor)
                
                guard !mnemonics.isEmpty else {
                    print("⚠️ No mnemonics to backup")
                    return
                }
                
                // Retrieve backup password from Keychain (secure storage)
                guard let autoBackupPassword = try? KeychainService.shared.retrieveBackupPassword() else {
                    print("⚠️ Auto backup password not set in Keychain")
                    return
                }
                
                // Create backup
                let backupURL = try await BackupService.shared.createBackup(
                    mnemonics: mnemonics,
                    password: autoBackupPassword
                )
                
                // Save to iCloud Drive
                _ = try await BackupService.shared.saveToiCloudDrive(backupURL)
                
                // Record backup (this will save the timestamp)
                BackupService.shared.recordAutoBackup()
                
                print("✅ Auto backup completed successfully")
            } catch {
                print("❌ Auto backup failed: \(error.localizedDescription)")
            }
        }
    }
}
