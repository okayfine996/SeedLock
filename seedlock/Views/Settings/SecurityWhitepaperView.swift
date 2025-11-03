//
//  SecurityWhitepaperView.swift
//  seedlock
//
//  Security architecture whitepaper view
//

import SwiftUI

struct SecurityWhitepaperView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Section
                    heroSection
                    
                    // Interactive Demo Button
                    interactiveDemoButton
                    
                    // Core Principle
                    corePrincipleSection
                    
                    // Architecture Diagram
                    architectureDiagramSection
                    
                    // Encryption Details
                    encryptionDetailsSection
                    
                    // Storage Separation
                    storageSeparationSection
                    
                    // Security Guarantees
                    securityGuaranteesSection
                    
                    // Technical Verification
                    technicalVerificationSection
                    
                    // Open Source Commitment
                    openSourceSection
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("whitepaper.title".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.appLabel)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("common.back".localized)
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.appPrimary)
            }
            
            Text("whitepaper.hero.title".localized)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("whitepaper.hero.subtitle".localized)
                .font(.system(size: 16))
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Interactive Demo Button
    
    private var interactiveDemoButton: some View {
        NavigationLink(destination: SecurityDemoView()) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("whitepaper.demo_button.title".localized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("whitepaper.demo_button.subtitle".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.appPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Core Principle
    
    private var corePrincipleSection: some View {
        VStack(spacing: 16) {
            sectionHeader("whitepaper.principle.title".localized, icon: "shield.checkered")
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("whitepaper.principle.statement".localized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.appLabel)
                    
                    Text("whitepaper.principle.explanation".localized)
                        .font(.system(size: 15))
                        .foregroundColor(.appSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    // MARK: - Architecture Diagram
    
    private var architectureDiagramSection: some View {
        VStack(spacing: 16) {
            sectionHeader("whitepaper.architecture.title".localized, icon: "diagram.tree")
            
            VStack(spacing: 16) {
                // Step 1: Your Device
                FlowStep(
                    number: 1,
                    icon: "iphone",
                    title: "whitepaper.flow.step1.title".localized,
                    description: "whitepaper.flow.step1.description".localized,
                    color: .blue
                )
                
                FlowArrow()
                
                // Step 2: Local Encryption
                FlowStep(
                    number: 2,
                    icon: "lock.fill",
                    title: "whitepaper.flow.step2.title".localized,
                    description: "whitepaper.flow.step2.description".localized,
                    color: .green
                )
                
                FlowArrow()
                
                // Step 3: Separation
                HStack(spacing: 12) {
                    FlowStep(
                        number: 3,
                        icon: "cloud.fill",
                        title: "whitepaper.flow.step3a.title".localized,
                        description: "whitepaper.flow.step3a.description".localized,
                        color: .orange,
                        compact: true
                    )
                    
                    FlowStep(
                        number: 3,
                        icon: "key.fill",
                        title: "whitepaper.flow.step3b.title".localized,
                        description: "whitepaper.flow.step3b.description".localized,
                        color: .purple,
                        compact: true
                    )
                }
                
                FlowArrow()
                
                // Step 4: Result
                FlowStep(
                    number: 4,
                    icon: "checkmark.shield.fill",
                    title: "whitepaper.flow.step4.title".localized,
                    description: "whitepaper.flow.step4.description".localized,
                    color: .green
                )
            }
            .padding(20)
            .background(Color.appSurface)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Encryption Details
    
    private var encryptionDetailsSection: some View {
        VStack(spacing: 16) {
            sectionHeader("whitepaper.encryption.title".localized, icon: "lock.square.stack")
            
            VStack(spacing: 12) {
                TechDetailRow(
                    icon: "cpu",
                    title: "whitepaper.encryption.algorithm".localized,
                    value: "AES-256-GCM"
                )
                
                TechDetailRow(
                    icon: "key.horizontal",
                    title: "whitepaper.encryption.key_length".localized,
                    value: "256-bit"
                )
                
                TechDetailRow(
                    icon: "arrow.triangle.branch",
                    title: "whitepaper.encryption.key_derivation".localized,
                    value: "SHA-256"
                )
                
                TechDetailRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "whitepaper.encryption.mode".localized,
                    value: "GCM (Authenticated)"
                )
            }
            .padding(16)
            .background(Color.appSurface)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Storage Separation
    
    private var storageSeparationSection: some View {
        VStack(spacing: 16) {
            sectionHeader("whitepaper.storage.title".localized, icon: "externaldrive.badge.icloud")
            
            VStack(spacing: 12) {
                StorageCard(
                    icon: "cloud.fill",
                    color: .blue,
                    title: "whitepaper.storage.cloudkit.title".localized,
                    items: [
                        "whitepaper.storage.cloudkit.item1".localized,
                        "whitepaper.storage.cloudkit.item2".localized,
                        "whitepaper.storage.cloudkit.item3".localized
                    ]
                )
                
                StorageCard(
                    icon: "key.fill",
                    color: .purple,
                    title: "whitepaper.storage.keychain.title".localized,
                    items: [
                        "whitepaper.storage.keychain.item1".localized,
                        "whitepaper.storage.keychain.item2".localized,
                        "whitepaper.storage.keychain.item3".localized
                    ]
                )
            }
        }
    }
    
    // MARK: - Security Guarantees
    
    private var securityGuaranteesSection: some View {
        VStack(spacing: 16) {
            sectionHeader("whitepaper.guarantees.title".localized, icon: "checkmark.seal.fill")
            
            VStack(spacing: 12) {
                GuaranteeCard(
                    icon: "eye.slash.fill",
                    color: .green,
                    text: "whitepaper.guarantees.item1".localized
                )
                
                GuaranteeCard(
                    icon: "lock.icloud.fill",
                    color: .blue,
                    text: "whitepaper.guarantees.item2".localized
                )
                
                GuaranteeCard(
                    icon: "shield.fill",
                    color: .purple,
                    text: "whitepaper.guarantees.item3".localized
                )
                
                GuaranteeCard(
                    icon: "key.viewfinder",
                    color: .orange,
                    text: "whitepaper.guarantees.item4".localized
                )
            }
        }
    }
    
    // MARK: - Technical Verification
    
    private var technicalVerificationSection: some View {
        VStack(spacing: 16) {
            sectionHeader("whitepaper.verification.title".localized, icon: "checkmark.circle.badge.questionmark")
            
            InfoCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("whitepaper.verification.intro".localized)
                        .font(.system(size: 15))
                        .foregroundColor(.appLabel)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        VerificationMethod(
                            number: "1",
                            text: "whitepaper.verification.method1".localized
                        )
                        
                        VerificationMethod(
                            number: "2",
                            text: "whitepaper.verification.method2".localized
                        )
                        
                        VerificationMethod(
                            number: "3",
                            text: "whitepaper.verification.method3".localized
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Open Source
    
    private var openSourceSection: some View {
        VStack(spacing: 16) {
            sectionHeader("whitepaper.opensource.title".localized, icon: "chevron.left.forwardslash.chevron.right")
            
            InfoCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("whitepaper.opensource.statement".localized)
                        .font(.system(size: 15))
                        .foregroundColor(.appLabel)
                    
                    Text("whitepaper.opensource.commitment".localized)
                        .font(.system(size: 15))
                        .foregroundColor(.appSecondaryLabel)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appPrimary)
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appLabel)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct InfoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface)
            .cornerRadius(12)
    }
}

struct FlowStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    let color: Color
    var compact: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Step Number & Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: compact ? 50 : 60, height: compact ? 50 : 60)
                
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: compact ? 18 : 22))
                        .foregroundColor(color)
                    
                    if !compact {
                        Text("\(number)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(color)
                    }
                }
            }
            
            // Content
            if !compact {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appLabel)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appLabel)
                    
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
        }
    }
}

struct FlowArrow: View {
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "arrow.down")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appPrimary.opacity(0.5))
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TechDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.appPrimary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.appLabel)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appPrimary)
        }
        .padding(.vertical, 4)
    }
}

struct StorageCard: View {
    let icon: String
    let color: Color
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appLabel)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.appSecondaryLabel)
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct GuaranteeCard: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.appLabel)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct VerificationMethod: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appPrimary)
            }
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.appSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        SecurityWhitepaperView()
    }
}

