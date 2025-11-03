//
//  SecurityDemoView.swift
//  seedlock
//
//  Interactive security demonstration view
//

import SwiftUI

struct SecurityDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var currentStep = 0
    @State private var showEncryptedData = false
    @State private var animateEncryption = false
    
    let totalSteps = 4
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                progressBar
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Current step content
                        currentStepView
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 100)
                }
                
                // Navigation buttons
                navigationButtons
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("security_demo.title".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.appLabel)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.appSecondaryLabel.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress
                    Rectangle()
                        .fill(Color.appPrimary)
                        .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
                        .animation(.spring(), value: currentStep)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
            
            Text("security_demo.step_counter".localized(currentStep + 1, totalSteps))
                .font(.system(size: 13))
                .foregroundColor(.appSecondaryLabel)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - Current Step View
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 0:
            step1_PlaintextPhrase
        case 1:
            step2_EncryptionProcess
        case 2:
            step3_DataSeparation
        case 3:
            step4_SecurityGuarantee
        default:
            EmptyView()
        }
    }
    
    // MARK: - Step 1: Plaintext Phrase
    
    private var step1_PlaintextPhrase: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "text.alignleft")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            Text("security_demo.step1.title".localized)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("security_demo.step1.description".localized)
                .font(.system(size: 16))
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
            
            // Example mnemonic phrase
            VStack(spacing: 16) {
                Text("security_demo.example_phrase".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appSecondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                MnemonicPhraseCard(
                    words: ["abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract", "absurd", "abuse", "access", "accident"],
                    isPlaintext: true
                )
                
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("security_demo.step1.warning".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryLabel)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Step 2: Encryption Process
    
    private var step2_EncryptionProcess: some View {
        VStack(spacing: 24) {
            // Icon with animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                    .rotationEffect(.degrees(animateEncryption ? 360 : 0))
                    .scaleEffect(animateEncryption ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateEncryption)
            }
            .onAppear {
                animateEncryption = true
            }
            
            Text("security_demo.step2.title".localized)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("security_demo.step2.description".localized)
                .font(.system(size: 16))
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
            
            // Encryption process visualization
            VStack(spacing: 16) {
                // Before encryption
                EncryptionStageCard(
                    icon: "doc.text",
                    title: "security_demo.step2.before".localized,
                    content: "abandon ability able about...",
                    color: .blue,
                    isPlaintext: true
                )
                
                // Encryption symbol
                Image(systemName: "arrow.down")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .padding(.vertical, 8)
                
                // Encryption method
                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .foregroundColor(.green)
                    Text("security_demo.step2.method".localized)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appLabel)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.15))
                .cornerRadius(8)
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.appPrimary)
                    .padding(.vertical, 8)
                
                // After encryption
                EncryptionStageCard(
                    icon: "lock.doc.fill",
                    title: "security_demo.step2.after".localized,
                    content: "A8F2E9D1C4B7...",
                    color: .green,
                    isPlaintext: false
                )
            }
            
            // Show actual encrypted data button
            Button(action: {
                showEncryptedData = true
            }) {
                HStack {
                    Image(systemName: "eye.fill")
                    Text("security_demo.step2.show_encrypted".localized)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.appPrimary)
                .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showEncryptedData) {
            EncryptedDataExampleView()
        }
    }
    
    // MARK: - Step 3: Data Separation
    
    private var step3_DataSeparation: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "rectangle.split.2x1")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
            }
            
            Text("security_demo.step3.title".localized)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("security_demo.step3.description".localized)
                .font(.system(size: 16))
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
            
            // Separation visualization
            VStack(spacing: 20) {
                // Encrypted data goes to CloudKit
                SeparationCard(
                    icon: "cloud.fill",
                    title: "CloudKit",
                    subtitle: "security_demo.step3.cloudkit_subtitle".localized,
                    items: [
                        "security_demo.step3.cloudkit_item1".localized
                    ],
                    color: .blue
                )
                
                Divider()
                    .overlay(Color.appSecondaryLabel)
                
                // Key goes to iCloud Keychain
                SeparationCard(
                    icon: "key.fill",
                    title: "iCloud Keychain",
                    subtitle: "security_demo.step3.keychain_subtitle".localized,
                    items: [
                        "security_demo.step3.keychain_item1".localized,
                        "security_demo.step3.keychain_item2".localized
                    ],
                    color: .purple
                )
            }
            
            // Key insight
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                
                Text("security_demo.step3.insight".localized)
                    .font(.system(size: 14))
                    .foregroundColor(.appLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Step 4: Security Guarantee
    
    private var step4_SecurityGuarantee: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
            
            Text("security_demo.step4.title".localized)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("security_demo.step4.description".localized)
                .font(.system(size: 16))
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
            
            // Guarantees
            VStack(spacing: 12) {
                GuaranteeRow(
                    icon: "eye.slash.fill",
                    text: "security_demo.step4.guarantee1".localized,
                    color: .green
                )
                
                GuaranteeRow(
                    icon: "lock.icloud.fill",
                    text: "security_demo.step4.guarantee2".localized,
                    color: .blue
                )
                
                GuaranteeRow(
                    icon: "shield.checkered",
                    text: "security_demo.step4.guarantee3".localized,
                    color: .purple
                )
                
                GuaranteeRow(
                    icon: "server.rack",
                    text: "security_demo.step4.guarantee4".localized,
                    color: .orange
                )
            }
            
            // Call to action
            VStack(spacing: 12) {
                Text("security_demo.step4.cta".localized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appLabel)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("security_demo.step4.start_using".localized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPrimary)
                        .cornerRadius(12)
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Previous button
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("common.back".localized)
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.appPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appSurface)
                    .cornerRadius(12)
                }
            }
            
            // Next/Done button
            Button(action: {
                if currentStep < totalSteps - 1 {
                    withAnimation {
                        currentStep += 1
                        animateEncryption = false
                    }
                } else {
                    dismiss()
                }
            }) {
                Text(currentStep < totalSteps - 1 ? "security_demo.next".localized : "common.done".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color.appBackground)
    }
}

// MARK: - Supporting Views

struct MnemonicPhraseCard: View {
    let words: [String]
    let isPlaintext: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    HStack(spacing: 8) {
                        Text("\(index + 1).")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appSecondaryLabel)
                            .frame(width: 20, alignment: .trailing)
                        
                        Text(word)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appLabel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(isPlaintext ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EncryptionStageCard: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    let isPlaintext: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appLabel)
            }
            
            Text(content)
                .font(.system(size: isPlaintext ? 13 : 12, design: isPlaintext ? .default : .monospaced))
                .foregroundColor(isPlaintext ? .appLabel : .appSecondaryLabel)
                .lineLimit(isPlaintext ? 1 : 2)
                .truncationMode(.tail)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SeparationCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appLabel)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryLabel)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(color)
                        
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct GuaranteeRow: View {
    let icon: String
    let text: String
    let color: Color
    
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

// MARK: - Encrypted Data Example View

struct EncryptedDataExampleView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Explanation
                        Text("security_demo.encrypted_example.explanation".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                        
                        // Actual encrypted data example
                        VStack(alignment: .leading, spacing: 12) {
                            Text("security_demo.encrypted_example.title".localized)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appLabel)
                            
                            Text(generateExampleEncryptedData())
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(12)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(8)
                        }
                        
                        // Key points
                        VStack(alignment: .leading, spacing: 12) {
                            KeyPoint(text: "security_demo.encrypted_example.point1".localized)
                            KeyPoint(text: "security_demo.encrypted_example.point2".localized)
                            KeyPoint(text: "security_demo.encrypted_example.point3".localized)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("security_demo.encrypted_example.nav_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
    }
    
    private func generateExampleEncryptedData() -> String {
        // Generate realistic looking encrypted data
        let hex = "A8F2E9D1C4B7A3E8F5D2C9B6E3A7F4D1B8E5C2A9F6D3B0E7C4A1F8D5B2E9C6A3" +
                  "F0D7B4E1C8A5F2D9B6E3A0F7D4B1E8C5A2F9D6B3E0C7A4F1D8B5E2C9A6F3D0B7" +
                  "E4C1A8F5D2B9E6C3A0F7D4B1E8C5A2F9D6B3E0C7A4F1D8B5E2C9A6F3D0B7E4C1"
        return hex
    }
}

struct KeyPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.appPrimary)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.appSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        SecurityDemoView()
    }
}

