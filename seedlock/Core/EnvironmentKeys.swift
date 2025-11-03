//
//  EnvironmentKeys.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

// MARK: - CloudKit Sync Enabled

private struct CloudKitSyncEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var cloudKitSyncEnabled: Bool {
        get { self[CloudKitSyncEnabledKey.self] }
        set { self[CloudKitSyncEnabledKey.self] = newValue }
    }
}

