//
//  BackupService.swift
//  seedlock
//
//  Service for backing up and restoring mnemonic data
//

import Foundation
import SwiftData
import CryptoKit
import UIKit

final class BackupService {
    static let shared = BackupService()
    
    private let backupVersion = "1.0"
    private let fileExtension = "seedlock"
    
    private init() {}
    
    // MARK: - Backup Creation
    
    /// Creates a backup of all mnemonics
    func createBackup(mnemonics: [Mnemonic], password: String) async throws -> URL {
        print("🔄 Creating backup for \(mnemonics.count) mnemonics...")
        
        // Collect all mnemonic data with their encryption keys
        var backupMnemonics: [BackupMnemonic] = []
        
        var failedMnemonics: [(name: String, error: Error)] = []
        
        for mnemonic in mnemonics {
            do {
                // Retrieve DEK from keychain
                let dek = try KeychainService.shared.retrieveKey(for: mnemonic.id.uuidString)
                
                // Encrypt the DEK with backup password
                let dekData = CryptoService.shared.keyToData(dek)
                let encryptedKey = try encryptData(dekData, with: password)
                
                let backupMnemonic = BackupMnemonic(
                    from: mnemonic,
                    encryptedKey: encryptedKey
                )
                backupMnemonics.append(backupMnemonic)
                
            } catch {
                print("❌ Failed to backup mnemonic '\(mnemonic.name)': \(error.localizedDescription)")
                failedMnemonics.append((name: mnemonic.name, error: error))
            }
        }
        
        // Report any failures
        if !failedMnemonics.isEmpty {
            let failedNames = failedMnemonics.map { $0.name }.joined(separator: ", ")
            print("⚠️ Failed to backup \(failedMnemonics.count) mnemonics: \(failedNames)")
            
            // If all mnemonics failed, throw error
            if backupMnemonics.isEmpty {
                throw BackupError.noDataToBackup
            }
            
            // Log warning for partial failure
            DiagnosticsLogger.shared.logEvent(.warning, 
                title: "Partial Backup Failure (\(failedMnemonics.count) items failed)")
        }
        
        // Create backup model
        let backup = await BackupModel(
            version: backupVersion,
            createdAt: Date(),
            deviceName: UIDevice.current.name,
            mnemonics: backupMnemonics
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(backup)
        
        // Save to temporary file
        let fileName = "seedlock_backup_\(formatDate(Date())).\(fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try jsonData.write(to: tempURL)
        
        print("✅ Backup created: \(fileName) (\(jsonData.count) bytes)")
        
        // Log event
        DiagnosticsLogger.shared.logEvent(.success, title: "Backup Created (\(backupMnemonics.count) items)")
        
        return tempURL
    }
    
    /// Saves backup to iCloud Drive
    func saveToiCloudDrive(_ backupURL: URL) async throws -> URL {
        print("☁️ Saving backup to iCloud Drive...")
        
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            throw BackupError.iCloudNotAvailable
        }
        
        // Create Documents directory if it doesn't exist
        try? FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
        
        let destinationURL = iCloudURL.appendingPathComponent(backupURL.lastPathComponent)
        
        // Copy file to iCloud
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: backupURL, to: destinationURL)
        
        print("✅ Backup saved to iCloud Drive")
        return destinationURL
    }
    
    // MARK: - Backup Restoration
    
    /// Restores mnemonics from a backup file
    func restoreBackup(from url: URL, password: String, context: ModelContext) async throws -> Int {
        print("🔄 Restoring backup from: \(url.lastPathComponent)")
        
        // Read backup file
        let data = try Data(contentsOf: url)
        
        // Decode backup
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupModel.self, from: data)
        
        print("📦 Backup version: \(backup.version)")
        print("📦 Created at: \(backup.createdAt)")
        print("📦 Device: \(backup.deviceName)")
        print("📦 Mnemonics: \(backup.mnemonics.count)")
        
        var restoredCount = 0
        
        for backupMnemonic in backup.mnemonics {
            do {
                // Decrypt the DEK with backup password
                let dekData = try decryptData(backupMnemonic.encryptedKey, with: password)
                let dek = CryptoService.shared.dataToKey(dekData)
                
                // Check if mnemonic already exists
                let descriptor = FetchDescriptor<Mnemonic>(
                    predicate: #Predicate { $0.id == backupMnemonic.id }
                )
                let existing = try? context.fetch(descriptor).first
                
                if let existing = existing {
                    print("⚠️ Mnemonic '\(backupMnemonic.name)' already exists, skipping...")
                    continue
                }
                
                // Create new mnemonic
                let mnemonic = Mnemonic(
                    id: backupMnemonic.id,
                    name: backupMnemonic.name,
                    tags: backupMnemonic.tags,
                    encryptedPhrase: backupMnemonic.encryptedPhrase,
                    createdAt: backupMnemonic.createdAt,
                    updatedAt: backupMnemonic.updatedAt,
                    lastAccessedAt: backupMnemonic.lastAccessedAt,
                    isStarred: backupMnemonic.isStarred,
                    isArchived: backupMnemonic.isArchived,
                    note: backupMnemonic.note,
                    wordCount: backupMnemonic.wordCount
                )
                
                // Save to context
                context.insert(mnemonic)
                
                // Save DEK to keychain
                try KeychainService.shared.saveKey(dek, for: mnemonic.id.uuidString)
                
                restoredCount += 1
                print("✅ Restored: \(mnemonic.name)")
                
            } catch {
                print("❌ Failed to restore '\(backupMnemonic.name)': \(error)")
            }
        }
        
        // Save context
        try context.save()
        
        print("✅ Restore complete: \(restoredCount)/\(backup.mnemonics.count) mnemonics restored")
        
        // Log event
        if restoredCount > 0 {
            DiagnosticsLogger.shared.logEvent(.success, title: "Backup Restored (\(restoredCount) items)")
        } else {
            DiagnosticsLogger.shared.logEvent(.warning, title: "Backup Restore: No new items")
        }
        
        return restoredCount
    }
    
    // MARK: - iCloud Drive Management
    
    /// Lists all backup files in iCloud Drive
    func listBackupsFromiCloudDrive() async throws -> [BackupFileInfo] {
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            throw BackupError.iCloudNotAvailable
        }
        
        guard FileManager.default.fileExists(atPath: iCloudURL.path) else {
            return []
        }
        
        let files = try FileManager.default.contentsOfDirectory(
            at: iCloudURL,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        let backupFiles = files.filter { $0.pathExtension == fileExtension }
        
        var backupInfos: [BackupFileInfo] = []
        
        for file in backupFiles {
            let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
            let size = attributes[.size] as? Int64 ?? 0
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            
            // Try to read mnemonic count from backup
            var mnemonicCount = 0
            if let data = try? Data(contentsOf: file) {
                print("📦 Reading backup file: \(file.lastPathComponent) (\(data.count) bytes)")
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let backup = try? decoder.decode(BackupModel.self, from: data) {
                    mnemonicCount = backup.mnemonics.count
                    print("✅ Found \(mnemonicCount) mnemonics in backup")
                } else {
                    print("❌ Failed to decode backup file")
                }
            } else {
                print("❌ Failed to read backup file: \(file.lastPathComponent)")
            }
            
            let info = BackupFileInfo(
                id: UUID(),
                fileName: file.lastPathComponent,
                url: file,
                createdAt: creationDate,
                size: size,
                mnemonicCount: mnemonicCount
            )
            backupInfos.append(info)
        }
        
        // Sort by creation date, newest first
        return backupInfos.sorted { $0.createdAt > $1.createdAt }
    }
    
    /// Deletes a backup file from iCloud Drive
    func deleteBackup(at url: URL) async throws {
        try FileManager.default.removeItem(at: url)
        print("🗑️ Deleted backup: \(url.lastPathComponent)")
    }
    
    // MARK: - Auto Backup
    
    /// Checks if automatic backup is needed
    func shouldPerformAutoBackup() -> Bool {
        guard UserDefaults.standard.bool(forKey: "autoBackupEnabled") else {
            return false
        }
        
        // Check if we have a valid last backup timestamp
        guard UserDefaults.standard.object(forKey: "lastAutoBackupDate") != nil else {
            print("📅 No previous backup found, should backup")
            return true // Never backed up before
        }
        
        let lastBackupTimestamp = UserDefaults.standard.double(forKey: "lastAutoBackupDate")
        guard lastBackupTimestamp > 0 else {
            print("📅 Invalid backup timestamp (0.0), should backup")
            return true // Invalid timestamp
        }
        
        let lastBackupDate = Date(timeIntervalSince1970: lastBackupTimestamp)
        let interval = UserDefaults.standard.integer(forKey: "autoBackupInterval")
        
        // Default to 7 days if not set
        let backupInterval = interval > 0 ? TimeInterval(interval * 86400) : TimeInterval(7 * 86400)
        
        let timeSinceLastBackup = Date().timeIntervalSince(lastBackupDate)
        let shouldBackup = timeSinceLastBackup > backupInterval
        
        print("📅 Last backup: \(lastBackupDate), interval: \(interval) days, time since: \(timeSinceLastBackup/3600) hours, should backup: \(shouldBackup)")
        
        return shouldBackup
    }
    
    /// Records that an automatic backup was performed
    func recordAutoBackup() {
        let timestamp = Date().timeIntervalSince1970
        UserDefaults.standard.set(timestamp, forKey: "lastAutoBackupDate")
        UserDefaults.standard.synchronize()
        print("💾 BackupService: Saved lastAutoBackupDate = \(timestamp)")
    }
    
    // MARK: - Helper Methods
    
    private func encryptData(_ data: Data, with password: String) throws -> Data {
        let key = deriveKey(from: password)
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw BackupError.encryptionFailed
        }
        return combined
    }
    
    private func decryptData(_ data: Data, with password: String) throws -> Data {
        let key = deriveKey(from: password)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func deriveKey(from password: String) -> SymmetricKey {
        // Use SHA-256 to derive a key from password
        let passwordData = password.data(using: .utf8)!
        let hash = SHA256.hash(data: passwordData)
        return SymmetricKey(data: hash)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }
}

// MARK: - Errors

enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case encryptionFailed
    case decryptionFailed
    case invalidBackupFile
    case restoreFailed
    case noDataToBackup
    case partialBackupFailure(failedCount: Int, failedNames: [String])
    
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud Drive is not available. Please sign in to iCloud in Settings."
        case .encryptionFailed:
            return "Failed to encrypt backup data."
        case .decryptionFailed:
            return "Failed to decrypt backup. Please check your password."
        case .invalidBackupFile:
            return "Invalid backup file format."
        case .restoreFailed:
            return "Failed to restore backup."
        case .noDataToBackup:
            return "No data available to backup. Unable to retrieve encryption keys."
        case .partialBackupFailure(let failedCount, let failedNames):
            let names = failedNames.prefix(3).joined(separator: ", ")
            let more = failedCount > 3 ? " and \(failedCount - 3) more" : ""
            return "Failed to backup \(failedCount) items: \(names)\(more)"
        }
    }
}

