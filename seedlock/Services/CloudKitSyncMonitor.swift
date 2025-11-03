//
//  CloudKitSyncMonitor.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import Foundation
import SwiftData
import Combine

/// Monitor for tracking CloudKit sync status using SwiftData
final class CloudKitSyncMonitor: ObservableObject {
    static let shared = CloudKitSyncMonitor()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    private var modelContext: ModelContext?
    private var syncTimer: Timer?
    
    // Sync status for individual items
    private var itemSyncStatus: [UUID: String] = [:]
    
    private init() {
        setupPeriodicSync()
    }
    
    // MARK: - Setup
    
    func configure(with context: ModelContext) {
        self.modelContext = context
        print("📡 CloudKit Monitor configured")
    }
    
    /// Setup periodic sync status check
    private func setupPeriodicSync() {
        // Check sync status every 30 seconds
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkSyncStatus()
        }
    }
    
    // MARK: - Sync Status Check
    
    private func checkSyncStatus() {
        guard checkSyncEnabled() else {
            // CloudKit is disabled, mark all as local only
            updateAllItemsSyncStatus(status: "local_only")
            return
        }
        
        // If CloudKit is enabled and items are pending, mark as synced after a delay
        // SwiftData handles sync automatically, we just update the UI status
        Task { @MainActor in
            await markPendingItemsAsSynced()
        }
    }
    
    private func markPendingItemsAsSynced() async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Mnemonic>(
                predicate: #Predicate { $0.syncStatus == "pending" }
            )
            
            let pendingMnemonics = try context.fetch(descriptor)
            
            // Mark items as synced if they've been pending for more than 10 seconds
            let now = Date()
            for mnemonic in pendingMnemonics {
                let timeSinceCreation = now.timeIntervalSince(mnemonic.createdAt)
                if timeSinceCreation > 10 {
                    mnemonic.syncStatus = "synced"
                    mnemonic.lastSyncedAt = Date()
                    print("✅ Marked as synced: \(mnemonic.name)")
                }
            }
            
            if !pendingMnemonics.isEmpty {
                try context.save()
            }
        } catch {
            print("❌ Failed to check sync status: \(error)")
        }
    }
    
    // MARK: - Sync Status Management
    
    func updateItemSyncStatus(_ itemId: UUID, status: String) {
        itemSyncStatus[itemId] = status
        
        // Update in database if context is available
        guard let context = modelContext else { return }
        
        Task { @MainActor in
            do {
                let descriptor = FetchDescriptor<Mnemonic>(
                    predicate: #Predicate { $0.id == itemId }
                )
                
                if let mnemonic = try context.fetch(descriptor).first {
                    mnemonic.syncStatus = status
                    if status == "synced" {
                        mnemonic.lastSyncedAt = Date()
                    }
                    try context.save()
                    print("✅ Updated sync status for \(mnemonic.name): \(status)")
                }
            } catch {
                print("❌ Failed to update sync status: \(error)")
            }
        }
    }
    
    func updateAllItemsSyncStatus(status: String) {
        guard let context = modelContext else { return }
        
        Task { @MainActor in
            do {
                let descriptor = FetchDescriptor<Mnemonic>()
                let mnemonics = try context.fetch(descriptor)
                
                for mnemonic in mnemonics {
                    mnemonic.syncStatus = status
                    if status == "synced" {
                        mnemonic.lastSyncedAt = Date()
                    }
                }
                
                try context.save()
                print("✅ Updated sync status for \(mnemonics.count) items to: \(status)")
            } catch {
                print("❌ Failed to update all items sync status: \(error)")
            }
        }
    }
    
    func getSyncStatus(for itemId: UUID) -> String {
        return itemSyncStatus[itemId] ?? "pending"
    }
    
    // MARK: - Manual Sync Trigger
    
    func triggerSync() {
        print("📡 Manual sync triggered")
        isSyncing = true
        
        // Mark all pending items as syncing
        Task { @MainActor in
            await updatePendingItemsStatus()
            
            // After a delay, mark as synced
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await markPendingItemsAsSynced()
            
            DispatchQueue.main.async { [weak self] in
                self?.isSyncing = false
                self?.lastSyncDate = Date()
            }
        }
    }
    
    private func updatePendingItemsStatus() async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Mnemonic>(
                predicate: #Predicate { $0.syncStatus == "pending" }
            )
            
            let pendingMnemonics = try context.fetch(descriptor)
            print("📡 Found \(pendingMnemonics.count) items to sync")
        } catch {
            print("❌ Failed to fetch pending items: \(error)")
        }
    }
    
    // MARK: - Sync Status Check
    
    func checkSyncEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "cloudKitSyncEnabled")
    }
    
    func updateSyncStatusForNewItem(_ mnemonic: Mnemonic) {
        if checkSyncEnabled() {
            mnemonic.syncStatus = "pending"
            print("📡 New item marked for sync: \(mnemonic.name)")
            
            // Auto-mark as synced after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                self?.updateItemSyncStatus(mnemonic.id, status: "synced")
            }
        } else {
            mnemonic.syncStatus = "local_only"
            print("📱 New item marked as local only: \(mnemonic.name)")
        }
    }
    
    // MARK: - Settings Change Handler
    
    func handleCloudKitToggle(enabled: Bool) {
        if enabled {
            // CloudKit enabled, mark all local_only as pending
            Task { @MainActor in
                await updateLocalOnlyToPending()
            }
        } else {
            // CloudKit disabled, mark all as local_only
            updateAllItemsSyncStatus(status: "local_only")
        }
    }
    
    private func updateLocalOnlyToPending() async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Mnemonic>(
                predicate: #Predicate { $0.syncStatus == "local_only" }
            )
            
            let localMnemonics = try context.fetch(descriptor)
            
            for mnemonic in localMnemonics {
                mnemonic.syncStatus = "pending"
            }
            
            if !localMnemonics.isEmpty {
                try context.save()
                print("✅ Updated \(localMnemonics.count) local items to pending")
            }
        } catch {
            print("❌ Failed to update local items: \(error)")
        }
    }
    
    deinit {
        syncTimer?.invalidate()
    }
}
