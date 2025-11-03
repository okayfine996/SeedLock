//
//  MnemonicViewModel.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import Foundation
import SwiftData
import CryptoKit

@MainActor
class MnemonicViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let cryptoService = CryptoService.shared
    private let keychainService = KeychainService.shared
    private let bip39Service = BIP39Service.shared
    
    // MARK: - Create Mnemonic
    
    /// Creates a new mnemonic with encryption
    /// - Parameters:
    ///   - name: Name for the mnemonic
    ///   - phrase: The mnemonic phrase
    ///   - tags: Optional tags
    ///   - note: Optional note
    ///   - context: SwiftData model context
    /// - Returns: Created mnemonic
    func createMnemonic(
        name: String,
        phrase: String,
        tags: [String] = [],
        note: String? = nil,
        context: ModelContext
    ) async throws -> Mnemonic {
        isLoading = true
        defer { isLoading = false }
        
        // Validate phrase
        let cleanedPhrase = bip39Service.cleanMnemonic(phrase)
        let validation = bip39Service.validate(cleanedPhrase)
        
        guard validation.isValid else {
            if let error = validation.error {
                throw error
            }
            throw BIP39Error.invalidWordCount
        }
        
        // Generate encryption key
        let key = cryptoService.generateKey()
        
        // Encrypt phrase
        let encryptedData = try cryptoService.encrypt(phrase: cleanedPhrase, using: key)
        
        // Count words
        let wordCount = cleanedPhrase.components(separatedBy: " ").count
        
        // Create mnemonic
        let mnemonic = Mnemonic(
            name: name,
            tags: tags,
            encryptedPhrase: encryptedData,
            note: note,
            wordCount: wordCount
        )
        
        // Set initial sync status based on CloudKit settings
        CloudKitSyncMonitor.shared.updateSyncStatusForNewItem(mnemonic)
        
        // Save to context
        context.insert(mnemonic)
        try context.save()
        
        // Save key to keychain
        try keychainService.saveKey(key, for: mnemonic.id.uuidString)
        
        // Log event
        DiagnosticsLogger.shared.logEvent(.success, title: "New Mnemonic Created")
        
        successMessage = "Mnemonic created successfully"
        return mnemonic
    }
    
    // MARK: - Decrypt Mnemonic
    
    /// Decrypts a mnemonic phrase
    /// - Parameter mnemonic: The mnemonic to decrypt
    /// - Returns: Decrypted phrase
    func decryptMnemonic(_ mnemonic: Mnemonic) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        // Retrieve key from keychain
        let key = try keychainService.retrieveKey(for: mnemonic.id.uuidString)
        
        // Decrypt phrase
        let phrase = try cryptoService.decrypt(data: mnemonic.encryptedPhrase, using: key)
        
        // Update last accessed
        mnemonic.markAsAccessed()
        
        return phrase
    }
    
    // MARK: - Update Mnemonic
    
    /// Updates mnemonic metadata
    /// - Parameters:
    ///   - mnemonic: The mnemonic to update
    ///   - name: New name
    ///   - tags: New tags
    ///   - note: New note
    ///   - context: SwiftData model context
    func updateMnemonic(
        _ mnemonic: Mnemonic,
        name: String,
        tags: [String],
        note: String?,
        context: ModelContext
    ) throws {
        mnemonic.name = name
        mnemonic.tags = tags
        mnemonic.note = note
        mnemonic.markAsUpdated()
        
        try context.save()
        successMessage = "Mnemonic updated successfully"
    }
    
    // MARK: - Delete Mnemonic
    
    /// Deletes a mnemonic and its encryption key
    /// - Parameters:
    ///   - mnemonic: The mnemonic to delete
    ///   - context: SwiftData model context
    func deleteMnemonic(_ mnemonic: Mnemonic, context: ModelContext) throws {
        // Delete key from keychain
        try? keychainService.deleteKey(for: mnemonic.id.uuidString)
        
        // Delete from context
        context.delete(mnemonic)
        try context.save()
        
        successMessage = "Mnemonic deleted"
    }
    
    // MARK: - Generate Mnemonic
    
    /// Generates a new BIP-39 mnemonic phrase
    /// - Parameter wordCount: Number of words
    /// - Returns: Generated phrase
    func generatePhrase(wordCount: Int = 12) throws -> String {
        return try bip39Service.generateMnemonic(wordCount: wordCount)
    }
    
    // MARK: - Validate Phrase
    
    /// Validates a mnemonic phrase
    /// - Parameter phrase: The phrase to validate
    /// - Returns: Validation result
    func validatePhrase(_ phrase: String) -> ValidationResult {
        let cleaned = bip39Service.cleanMnemonic(phrase)
        return bip39Service.validate(cleaned)
    }
    
    // MARK: - Clear Messages
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

