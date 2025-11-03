//
//  CryptoService.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import Foundation
import CryptoKit

/// Service for encrypting and decrypting mnemonic phrases using AES-GCM
final class CryptoService {
    static let shared = CryptoService()
    
    private init() {}
    
    // MARK: - Encryption
    
    /// Encrypts a mnemonic phrase using AES-GCM with the provided key
    /// - Parameters:
    ///   - phrase: The mnemonic phrase to encrypt
    ///   - key: The symmetric key for encryption
    /// - Returns: Encrypted data including nonce and tag
    func encrypt(phrase: String, using key: SymmetricKey) throws -> Data {
        guard let phraseData = phrase.data(using: .utf8) else {
            throw CryptoError.invalidInput
        }
        
        let sealedBox = try AES.GCM.seal(phraseData, using: key)
        
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }
        
        return combined
    }
    
    // MARK: - Decryption
    
    /// Decrypts encrypted data back to mnemonic phrase
    /// - Parameters:
    ///   - data: The encrypted data
    ///   - key: The symmetric key for decryption
    /// - Returns: Decrypted mnemonic phrase
    func decrypt(data: Data, using key: SymmetricKey) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let phrase = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        
        return phrase
    }
    
    // MARK: - Key Generation
    
    /// Generates a new random symmetric key for encryption
    /// - Returns: A new 256-bit symmetric key
    func generateKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    /// Converts a symmetric key to raw data for storage
    /// - Parameter key: The symmetric key
    /// - Returns: Raw key data
    func keyToData(_ key: SymmetricKey) -> Data {
        return key.withUnsafeBytes { Data($0) }
    }
    
    /// Restores a symmetric key from raw data
    /// - Parameter data: Raw key data
    /// - Returns: Symmetric key
    func dataToKey(_ data: Data) -> SymmetricKey {
        return SymmetricKey(data: data)
    }
}

// MARK: - Errors

enum CryptoError: LocalizedError {
    case invalidInput
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input data"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        }
    }
}

