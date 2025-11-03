//
//  KeychainService.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import Foundation
import Security
import CryptoKit

/// Service for securely storing and retrieving encryption keys in iCloud Keychain
final class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.seedlock.keys"
    
    private var iCloudKeychainEnabled: Bool {
        // Now tied to CloudKit sync setting
        UserDefaults.standard.bool(forKey: "cloudKitSyncEnabled")
    }
    
    private init() {}
    
    // MARK: - Save Key
    
    /// Saves an encryption key to iCloud Keychain
    /// - Parameters:
    ///   - key: The symmetric key to save
    ///   - identifier: Unique identifier for this key (typically mnemonic ID)
    /// - Throws: KeychainError if save fails
    func saveKey(_ key: SymmetricKey, for identifier: String) throws {
        let keyData = CryptoService.shared.keyToData(key)
        
        // Delete existing key first
        try? deleteKey(for: identifier)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrSynchronizable as String: iCloudKeychainEnabled // Sync based on setting
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    // MARK: - Retrieve Key
    
    /// Retrieves an encryption key from iCloud Keychain
    /// - Parameter identifier: The identifier for the key
    /// - Returns: The symmetric key if found
    /// - Throws: KeychainError if retrieval fails
    func retrieveKey(for identifier: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny, // Check both synced and local
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw KeychainError.notFound
        }
        
        return CryptoService.shared.dataToKey(keyData)
    }
    
    // MARK: - Delete Key
    
    /// Deletes an encryption key from iCloud Keychain
    /// - Parameter identifier: The identifier for the key to delete
    /// - Throws: KeychainError if deletion fails
    func deleteKey(for identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny // Delete both synced and local
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    // MARK: - Check Availability
    
    /// Checks if iCloud Keychain is available and enabled
    /// - Returns: True if iCloud Keychain is available
    func isKeychainAvailable() -> Bool {
        // Try to save and retrieve a test item
        let testKey = "test_keychain_availability"
        let testData = "test".data(using: .utf8)!
        
        let saveQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: testKey,
            kSecValueData as String: testData,
            kSecAttrSynchronizable as String: false // Test local keychain first
        ]
        
        // Clean up any existing test item
        SecItemDelete(saveQuery as CFDictionary)
        
        // Try to add
        let saveStatus = SecItemAdd(saveQuery as CFDictionary, nil)
        
        if saveStatus == errSecSuccess {
            // Clean up
            SecItemDelete(saveQuery as CFDictionary)
            return true
        }
        
        return false
    }
    
    /// Toggle iCloud Keychain sync for existing keys and migrate them
    func setKeychainSyncEnabled(_ enabled: Bool) async throws {
        logInfo("iCloud Keychain sync \(enabled ? "enabled" : "disabled")")
        
        // Migrate existing keys to new sync setting
        try await migrateKeysToSyncSetting(enabled)
    }
    
    // MARK: - Migration
    
    /// Migrates existing keys to new sync setting
    /// This is called when user changes the CloudKit sync setting
    /// - Parameter enabled: Whether sync should be enabled
    private func migrateKeysToSyncSetting(_ enabled: Bool) async throws {
        logInfo("Starting keychain migration (sync: \(enabled))")
        
        // Query all existing keys (both synced and local)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny // Find both synced and local
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logError("Failed to query keychain items: \(status)")
            throw KeychainError.saveFailed(status)
        }
        
        // If no items found, nothing to migrate
        guard status == errSecSuccess,
              let items = result as? [[String: Any]],
              !items.isEmpty else {
            logInfo("No keys to migrate")
            return
        }
        
        logInfo("Found \(items.count) keys to migrate")
        var migratedCount = 0
        var failedCount = 0
        
        for item in items {
            guard let account = item[kSecAttrAccount as String] as? String,
                  let keyData = item[kSecValueData as String] as? Data else {
                logWarning("Skipping invalid keychain item")
                continue
            }
            
            // Check current sync status
            let currentSyncStatus = item[kSecAttrSynchronizable as String] as? Bool ?? false
            
            // Skip if already in desired state
            if currentSyncStatus == enabled {
                logDebug("Key '\(account)' already in correct state")
                continue
            }
            
            do {
                // Delete old key
                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: account,
                    kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
                ]
                SecItemDelete(deleteQuery as CFDictionary)
                
                // Add key with new sync setting
                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: account,
                    kSecValueData as String: keyData,
                    kSecAttrSynchronizable as String: enabled
                ]
                
                let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
                if addStatus == errSecSuccess {
                    migratedCount += 1
                    logSuccess("Migrated key: \(account)")
                } else {
                    failedCount += 1
                    logError("Failed to migrate key '\(account)': \(addStatus)")
                }
                
            } catch {
                failedCount += 1
                logError("Error migrating key '\(account)'", error: error)
            }
        }
        
        logSuccess("Migration complete: \(migratedCount) migrated, \(failedCount) failed")
        
        if failedCount > 0 {
            throw KeychainError.saveFailed(-1) // Generic error for partial failure
        }
    }
    
    /// Lists all keys stored in keychain (for debugging)
    func listAllKeys() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            item[kSecAttrAccount as String] as? String
        }
    }
    
    // MARK: - Backup Password Management
    
    /// Saves backup password securely in Keychain
    /// - Parameter password: The backup password to store
    /// - Throws: KeychainError if save fails
    func saveBackupPassword(_ password: String) throws {
        guard let passwordData = password.data(using: .utf8) else {
            throw KeychainError.saveFailed(-1)
        }
        
        // Delete existing password first
        try? deleteBackupPassword()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "backup_password",
            kSecValueData as String: passwordData,
            kSecAttrSynchronizable as String: iCloudKeychainEnabled // Sync based on setting
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
        
        logSuccess("Backup password saved securely")
    }
    
    /// Retrieves backup password from Keychain
    /// - Returns: The backup password if found
    /// - Throws: KeychainError if retrieval fails
    func retrieveBackupPassword() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "backup_password",
            kSecReturnData as String: true,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        
        return password
    }
    
    /// Deletes backup password from Keychain
    /// - Throws: KeychainError if deletion fails
    func deleteBackupPassword() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "backup_password",
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Checks if backup password is set
    /// - Returns: True if backup password exists
    func hasBackupPassword() -> Bool {
        do {
            _ = try retrieveBackupPassword()
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case notFound
    case deleteFailed(OSStatus)
    case unavailable
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .notFound:
            return "Key not found in Keychain"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        case .unavailable:
            return "iCloud Keychain is not available"
        }
    }
}

