//
//  PrivacyPolicyView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: Theme.spacing12) {
                        Text("privacy.title".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.appLabel)
                        
                        Text("privacy.last_updated".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryLabel)
                        
                        Text("privacy.intro".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                            .lineSpacing(6)
                            .padding(.top, Theme.spacing8)
                    }
                    .padding(Theme.spacing24)
                    
                    Divider()
                    
                    // Content
                    VStack(alignment: .leading, spacing: Theme.spacing24) {
                        TermsSection(
                            number: "1",
                            title: "privacy.section1.title".localized,
                            content: "privacy.section1.content".localized
                        )
                        
                        TermsSection(
                            number: "2",
                            title: "privacy.section2.title".localized,
                            content: "privacy.section2.content".localized
                        )
                        
                        TermsSection(
                            number: "3",
                            title: "privacy.section3.title".localized,
                            content: "privacy.section3.content".localized
                        )
                        
                        TermsSection(
                            number: "4",
                            title: "privacy.section4.title".localized,
                            content: "privacy.section4.content".localized
                        )
                        
                        TermsSection(
                            number: "5",
                            title: "privacy.section5.title".localized,
                            content: "privacy.section5.content".localized
                        )
                        
                        TermsSection(
                            number: "6",
                            title: "privacy.section6.title".localized,
                            content: "privacy.section6.content".localized
                        )
                        
                        TermsSection(
                            number: "7",
                            title: "privacy.section7.title".localized,
                            content: "privacy.section7.content".localized
                        )
                    }
                    .padding(Theme.spacing24)
                    .padding(.bottom, Theme.spacing32)
                }
            }
        }
        .navigationTitle("privacy.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}

