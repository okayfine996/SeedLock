//
//  TermsOfServiceView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {    
                    // Header
                    VStack(alignment: .leading, spacing: Theme.spacing12) {
                        Text("terms.title".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.appLabel)
                        
                        Text("terms.last_updated".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryLabel)
                        
                        Text("terms.intro".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                            .lineSpacing(6)
                            .padding(.top, Theme.spacing8)
                    }
                    .padding(Theme.spacing24)
                    
                    Divider()
                    
                    // Content
                    VStack(alignment: .leading, spacing: Theme.spacing24) {
                        // 1. Acceptance of Terms
                        TermsSection(
                            number: "1",
                            title: "terms.section1.title".localized,
                            content: "terms.section1.content".localized
                        )
                        
                        // 2. Description of Service
                        TermsSection(
                            number: "2",
                            title: "terms.section2.title".localized,
                            content: "terms.section2.content".localized
                        )
                        
                        // 3. User Responsibilities
                        TermsSection(
                            number: "3",
                            title: "terms.section3.title".localized,
                            content: "terms.section3.content".localized
                        )
                        
                        // 4. Critical Risk Warning
                        TermsSection(
                            number: "4",
                            title: "terms.section4.title".localized,
                            content: "terms.section4.content".localized
                        )
                        
                        // 5. Zero-Knowledge Architecture
                        TermsSection(
                            number: "5",
                            title: "terms.section5.title".localized,
                            content: "terms.section5.content".localized
                        )
                        
                        // 6. Data Storage and Backup
                        TermsSection(
                            number: "6",
                            title: "terms.section6.title".localized,
                            content: "terms.section6.content".localized
                        )
                        
                        // 7. No Warranty
                        TermsSection(
                            number: "7",
                            title: "terms.section7.title".localized,
                            content: "terms.section7.content".localized
                        )
                        
                        // 8. Limitation of Liability
                        TermsSection(
                            number: "8",
                            title: "terms.section8.title".localized,
                            content: "terms.section8.content".localized
                        )
                        
                        // 9. Prohibited Uses
                        TermsSection(
                            number: "9",
                            title: "terms.section9_alt.title".localized,
                            content: "terms.section9_alt.content".localized
                        )
                        
                        // 10. Open Source
                        TermsSection(
                            number: "10",
                            title: "terms.section10_alt.title".localized,
                            content: "terms.section10_alt.content".localized
                        )
                        
                        // 11. Changes to Terms
                        TermsSection(
                            number: "11",
                            title: "terms.section11.title".localized,
                            content: "terms.section11.content".localized
                        )
                        
                        // 12. Termination
                        TermsSection(
                            number: "12",
                            title: "terms.section12.title".localized,
                            content: "terms.section12.content".localized
                        )
                        
                        // 13. Governing Law
                        TermsSection(
                            number: "13",
                            title: "terms.section13.title".localized,
                            content: "terms.section13.content".localized
                        )
                        
                        // 14. Contact
                        TermsSection(
                            number: "14",
                            title: "terms.section14.title".localized,
                            content: "terms.section14.content".localized
                        )
                        
                        // Acknowledgment Box
                        VStack(alignment: .leading, spacing: Theme.spacing12) {
                            HStack(spacing: Theme.spacing12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("terms.agreement.title".localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.appLabel)
                                    
                                    Text("terms.agreement.message".localized)
                                        .font(.system(size: 14))
                                        .foregroundColor(.appSecondaryLabel)
                                        .lineSpacing(4)
                                }
                            }
                        }
                        .padding(Theme.spacing16)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    .padding(Theme.spacing24)
                    .padding(.bottom, Theme.spacing32)
                }
            }
        }
        .navigationTitle("terms.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms Section Component

struct TermsSection: View {
    let number: String
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing12) {
            // Section Header
            HStack(spacing: Theme.spacing8) {
                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.appPrimary.opacity(0.15))
                    )
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appLabel)
            }
            
            // Section Content
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.appSecondaryLabel)
                .lineSpacing(6)
                .padding(.leading, 40)
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}

