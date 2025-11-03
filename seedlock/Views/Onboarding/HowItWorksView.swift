//
//  HowItWorksView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

struct HowItWorksView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing24) {
                    InfoSection(
                        title: "how_it_works.encryption.title".localized,
                        icon: "lock.shield",
                        description: "how_it_works.encryption.description".localized
                    )
                    
                    InfoSection(
                        title: "how_it_works.key_storage.title".localized,
                        icon: "key.fill",
                        description: "how_it_works.key_storage.description".localized
                    )
                    
                    InfoSection(
                        title: "how_it_works.zero_knowledge.title".localized,
                        icon: "eye.slash",
                        description: "how_it_works.zero_knowledge.description".localized
                    )
                    
                    InfoSection(
                        title: "how_it_works.bip39.title".localized,
                        icon: "checkmark.shield",
                        description: "how_it_works.bip39.description".localized
                    )
                }
                .padding(Theme.spacing24)
            }
            .background(Color.appBackground)
            .navigationTitle("how_it_works.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Info Section

struct InfoSection: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing12) {
            HStack(spacing: Theme.spacing12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.appPrimary)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.appLabel)
            }
            
            Text(description)
                .font(.system(size: 15))
                .foregroundColor(.appSecondaryLabel)
                .lineSpacing(4)
        }
        .padding(Theme.spacing16)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.appSurface)
        )
    }
}

#Preview {
    HowItWorksView()
}

