//
//  BackupModel.swift
//  seedlock
//
//  Backup data structure for export/import
//

import Foundation

/// Represents a complete backup of all mnemonics
struct BackupModel: Codable {
    let version: String
    let createdAt: Date
    let deviceName: String
    let mnemonics: [BackupMnemonic]
    
    /// Metadata about the backup
    struct Metadata: Codable {
        let totalCount: Int
        let backupSize: Int
        let encrypted: Bool
    }
    
    var metadata: Metadata {
        Metadata(
            totalCount: mnemonics.count,
            backupSize: 0, // Will be calculated when saved
            encrypted: true
        )
    }
}

/// Represents a single mnemonic in the backup
struct BackupMnemonic: Codable, Identifiable {
    let id: UUID
    let name: String
    let tags: [String]
    let encryptedPhrase: Data
    let encryptedKey: Data // Encrypted DEK
    let createdAt: Date
    let updatedAt: Date
    let lastAccessedAt: Date?
    let isStarred: Bool
    let isArchived: Bool
    let note: String?
    let wordCount: Int
    
    /// Initialize from a Mnemonic model
    init(from mnemonic: Mnemonic, encryptedKey: Data) {
        self.id = mnemonic.id
        self.name = mnemonic.name
        self.tags = mnemonic.tags
        self.encryptedPhrase = mnemonic.encryptedPhrase
        self.encryptedKey = encryptedKey
        self.createdAt = mnemonic.createdAt
        self.updatedAt = mnemonic.updatedAt
        self.lastAccessedAt = mnemonic.lastAccessedAt
        self.isStarred = mnemonic.isStarred
        self.isArchived = mnemonic.isArchived
        self.note = mnemonic.note
        self.wordCount = mnemonic.wordCount
    }
}

/// Backup file metadata for listing
struct BackupFileInfo: Identifiable {
    let id: UUID
    let fileName: String
    let url: URL
    let createdAt: Date
    let size: Int64
    let mnemonicCount: Int
    
    var sizeString: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = LanguageManager.shared.currentLocale
        return formatter.string(from: createdAt)
    }
}

