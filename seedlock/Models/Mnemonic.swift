//
//  Mnemonic.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import Foundation
import SwiftData

@Model
final class Mnemonic {
    var id: UUID = UUID()
    var name: String = ""
    
    // Store tags as comma-separated string for reliable CloudKit sync
    // This avoids CoreData Array serialization issues
    private var tagsString: String = ""
    
    // Computed property for convenient array access
    @Transient
    var tags: [String] {
        get {
            if tagsString.isEmpty {
                return []
            }
            return tagsString.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        set {
            tagsString = newValue.joined(separator: ",")
        }
    }
    
    var encryptedPhrase: Data = Data()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var lastAccessedAt: Date?
    var isStarred: Bool = false
    var isArchived: Bool = false
    var note: String?
    var wordCount: Int = 12 // 12, 15, 18, 21, or 24
    
    // CloudKit sync status
    var lastSyncedAt: Date?
    var syncStatus: String = "pending" // pending, synced, failed, local_only
    
    init(
        id: UUID = UUID(),
        name: String,
        tags: [String] = [],
        encryptedPhrase: Data,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastAccessedAt: Date? = nil,
        isStarred: Bool = false,
        isArchived: Bool = false,
        note: String? = nil,
        wordCount: Int = 12
    ) {
        self.id = id
        self.name = name
        self.encryptedPhrase = encryptedPhrase
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastAccessedAt = lastAccessedAt
        self.isStarred = isStarred
        self.isArchived = isArchived
        self.note = note
        self.wordCount = wordCount
        // Set tags through property to trigger encoding
        self.tags = tags
    }
    
    /// Updates the last accessed timestamp
    func markAsAccessed() {
        lastAccessedAt = Date()
        updatedAt = Date()
    }
    
    /// Updates the modification timestamp
    func markAsUpdated() {
        updatedAt = Date()
    }
}
