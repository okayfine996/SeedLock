//
//  MnemonicRowView.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI

struct MnemonicRowView: View {
    let mnemonic: Mnemonic
    let onTap: () -> Void
    @State private var isStarred: Bool
    @AppStorage("cloudKitSyncEnabled") private var cloudKitSyncEnabled = true
    
    init(mnemonic: Mnemonic, onTap: @escaping () -> Void) {
        self.mnemonic = mnemonic
        self.onTap = onTap
        self._isStarred = State(initialValue: mnemonic.isStarred)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.spacing16) {
                // Icon
                iconView
                
                // Content
                VStack(alignment: .leading, spacing: Theme.spacing8) {
                    Text(mnemonic.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.appLabel)
                        .lineLimit(1)
                    
                    if !mnemonic.tags.isEmpty {
                        tagsView
                    }
                }
                
                Spacer()
                
                // Sync status indicator (if CloudKit is enabled)
                if cloudKitSyncEnabled {
                    syncStatusIndicator
                }
                
                // Star button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isStarred.toggle()
                        mnemonic.isStarred = isStarred
                    }
                }) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundColor(isStarred ? .yellow : .appSecondaryLabel)
                        .frame(width: Theme.minTapTarget, height: Theme.minTapTarget)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(Theme.spacing16)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .fill(Color.appSurface.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .stroke(Color.appDivider.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(getIconColor())
                .frame(width: 60, height: 60)
            
            Image(systemName: getIconName())
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var tagsView: some View {
        HStack(spacing: Theme.spacing8) {
            ForEach(mnemonic.tags.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, Theme.spacing12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusSmall)
                            .fill(Color.appPrimary.opacity(0.15))
                    )
                    .frame(maxWidth: 80) // 限制每个 tag 的最大宽度
            }
            
            if mnemonic.tags.count > 3 {
                Text("+\(mnemonic.tags.count - 3)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appSecondaryLabel)
            }
        }
    }
    
    private func getIconName() -> String {
        // Icon selection based on tags or default
        if mnemonic.tags.contains("Bitcoin") || mnemonic.tags.contains("DeFi") {
            return "creditcard.fill"
        } else if mnemonic.tags.contains("Ethereum") {
            return "banknote.fill"
        } else if mnemonic.tags.contains("Trading") {
            return "chart.line.uptrend.xyaxis"
        } else {
            return "key.fill"
        }
    }
    
    private func getIconColor() -> Color {
        // Color variation based on index or tags
        if mnemonic.tags.contains("Ethereum") {
            return Color(hex: "5B8DEE")
        } else if mnemonic.tags.contains("Trading") {
            return Color(hex: "8B5CF6")
        } else {
            return Color.appPrimary
        }
    }
    
    // MARK: - Sync Status Indicator
    
    private var syncStatusIndicator: some View {
        Group {
            switch mnemonic.syncStatus {
            case "synced":
                syncedIndicator
            case "pending":
                pendingIndicator
            case "failed":
                failedIndicator
            case "local_only":
                localOnlyIndicator
            default:
                pendingIndicator
            }
        }
    }
    
    private var syncedIndicator: some View {
        VStack(spacing: 2) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 16))
                .foregroundColor(.appPrimary)
            
            if let lastSynced = mnemonic.lastSyncedAt {
                Text(timeAgoString(from: lastSynced))
                    .font(.system(size: 9))
                    .foregroundColor(.appSecondaryLabel)
            }
        }
    }
    
    private var pendingIndicator: some View {
        Image(systemName: "cloud")
            .font(.system(size: 16))
            .foregroundColor(.appSecondaryLabel)
            .opacity(0.5)
    }
    
    private var failedIndicator: some View {
        Image(systemName: "exclamationmark.icloud")
            .font(.system(size: 16))
            .foregroundColor(.orange)
    }
    
    private var localOnlyIndicator: some View {
        Image(systemName: "iphone")
            .font(.system(size: 16))
            .foregroundColor(.appSecondaryLabel)
    }
    
    // MARK: - Helper Functions
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d"
        }
    }
}

// MARK: - Skeleton Loading View
struct SkeletonRowView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: Theme.spacing16) {
            // Icon skeleton
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.appSurface)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: Theme.spacing8) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.appSurface)
                    .frame(width: 150, height: 18)
                
                // Tags skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.appSurface)
                    .frame(width: 100, height: 14)
            }
            
            Spacer()
        }
        .padding(Theme.spacing16)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.appSurface.opacity(0.3))
        )
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview("Mnemonic Row") {
    let mnemonic = Mnemonic(
        name: "My Main Wallet",
        tags: ["Bitcoin", "DeFi"],
        encryptedPhrase: Data(),
        isStarred: false
    )
    
    return MnemonicRowView(mnemonic: mnemonic) {}
        .padding()
        .background(Color.appBackground)
}

#Preview("Skeleton Row") {
    SkeletonRowView()
        .padding()
        .background(Color.appBackground)
}

