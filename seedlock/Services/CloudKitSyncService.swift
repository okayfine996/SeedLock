//
//  CloudKitSyncService.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import Foundation
import CloudKit
import SwiftData

/// Service for managing CloudKit synchronization
final class CloudKitSyncService {
    static let shared = CloudKitSyncService()
    
    private let container = CKContainer.default()
    private var syncEnabled: Bool {
        UserDefaults.standard.bool(forKey: "cloudKitSyncEnabled")
    }
    
    private init() {}
    
    // MARK: - Sync Status
    
    enum SyncStatus {
        case notAvailable
        case available
        case syncing
        case error(String)
    }
    
    /// Check if CloudKit is available
    func checkAvailability(completion: @escaping (SyncStatus) -> Void) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.error(error.localizedDescription))
                    return
                }
                
                switch status {
                case .available:
                    completion(.available)
                case .noAccount:
                    completion(.notAvailable)
                case .restricted:
                    completion(.error("iCloud access is restricted"))
                case .couldNotDetermine:
                    completion(.error("Could not determine iCloud status"))
                case .temporarilyUnavailable:
                    completion(.error("iCloud is temporarily unavailable"))
                @unknown default:
                    completion(.error("Unknown iCloud status"))
                }
            }
        }
    }
    
    /// Enable or disable CloudKit sync
    func setSyncEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "cloudKitSyncEnabled")
        
        if enabled {
            // Trigger initial sync
            triggerSync()
        }
    }
    
    /// Manually trigger a sync
    func triggerSync() {
        guard syncEnabled else { return }
        
        // SwiftData with CloudKit handles sync automatically
        // This is just a placeholder for manual sync triggers if needed
        print("📡 CloudKit sync triggered")
    }
    
    /// Check if user is signed into iCloud
    func isSignedIntoiCloud(completion: @escaping (Bool) -> Void) {
        container.accountStatus { status, _ in
            DispatchQueue.main.async {
                completion(status == .available)
            }
        }
    }
}

