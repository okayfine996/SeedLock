//
//  MnemonicDetailView.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI
import SwiftData

struct MnemonicDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("biometricsRequired") private var biometricsRequired = false
    @ObservedObject private var languageManager = LanguageManager.shared
    
    @StateObject private var viewModel = MnemonicViewModel()
    
    enum ViewState {
        case locked
        case loading
        case unlocked(phrase: String, countdown: Int)
        case error(message: String)
        
        var isUnlocked: Bool {
            if case .unlocked = self {
                return true
            }
            return false
        }
    }
    
    @State private var viewState: ViewState = .locked
    @State private var countdownTimer: Timer?
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var showCopyToast = false
    
    let mnemonic: Mnemonic
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing16) {
                    // Info Card
                    infoCard
                    
                    // Mnemonic Card
                    mnemonicCard
                    
                    // Screenshot Warning (only when unlocked)
                    if case .unlocked = viewState {
                        screenshotWarning
                    }
                    
                    // Delete Button
                    deleteButton
                }
                .padding(Theme.spacing16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("common.edit".localized) {
                    showEditSheet = true
                }
                .font(.system(size: 17))
                .foregroundColor(.appPrimary)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditMnemonicView(mnemonic: mnemonic)
        }
        .alert("detail.delete_confirmation.title".localized, isPresented: $showDeleteConfirmation) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.delete".localized, role: .destructive) {
                deleteMnemonic()
            }
        } message: {
            Text("detail.delete_confirmation.message".localized)
        }
        .overlay(alignment: .bottom) {
            if showCopyToast {
                copyToastView
            }
        }
        .onDisappear {
            lockMnemonic()
        }
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing16) {
            // Name
            Text(mnemonic.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.appLabel)
            
            // Tags
            if !mnemonic.tags.isEmpty {
                HStack(spacing: Theme.spacing8) {
                    ForEach(mnemonic.tags.prefix(5), id: \.self) { tag in
                        TagChip(text: tag)
                    }
                    
                    if mnemonic.tags.count > 5 {
                        Text("+\(mnemonic.tags.count - 5)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appSecondaryLabel)
                    }
                }
            }
            
            // Timestamps
            VStack(alignment: .leading, spacing: Theme.spacing4) {
                HStack {
                    Text("detail.created".localized)
                    Text(mnemonic.createdAt.formatted(
                        .dateTime
                            .year().month().day()
                            .locale(languageManager.currentLocale)
                    ))
                }
                HStack {
                    Text("detail.last_updated".localized)
                    Text(mnemonic.updatedAt.formatted(
                        .dateTime
                            .year().month().day()
                            .locale(languageManager.currentLocale)
                    ))
                }
            }
            .font(.system(size: 13))
            .foregroundColor(.appSecondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spacing24)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .fill(Color.appSurface)
        )
    }
    
    // MARK: - Mnemonic Card
    
    private var mnemonicCard: some View {
        VStack(spacing: Theme.spacing16) {
            // Title with lock button
            HStack {
                Text("detail.mnemonic_phrase".localized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appLabel)
                
                Spacer()
                
                // Lock/Unlock button
                Button(action: {
                    if case .unlocked = viewState {
                        lockMnemonic()
                    } else {
                        unlockMnemonic()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: viewState.isUnlocked ? "lock.open.fill" : "lock.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            
            switch viewState {
            case .locked:
                // Show placeholder grid when locked
                MnemonicPlaceholderGrid(wordCount: mnemonic.wordCount)
                
            case .loading:
                loadingView
                
            case .unlocked(let phrase, let countdown):
                unlockedView(phrase: phrase, countdown: countdown)
                
            case .error(let message):
                errorView(message: message)
            }
        }
        .padding(Theme.spacing24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .fill(Color.appSurface)
        )
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Theme.spacing16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.appPrimary)
            
            Text("detail.loading".localized)
                .font(.system(size: 15))
                .foregroundColor(.appSecondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacing32)
    }
    
    // MARK: - Unlocked View
    
    private func unlockedView(phrase: String, countdown: Int) -> some View {
        VStack(spacing: Theme.spacing16) {
            // Word grid
            MnemonicWordGrid(phrase: phrase)
            
            // Actions and countdown
            HStack(spacing: Theme.spacing16) {
                // Copy button
                Button(action: copyToClipboard) {
                    HStack(spacing: Theme.spacing8) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                        Text("detail.copy_button".localized)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.appLabel)
                    .padding(.horizontal, Theme.spacing16)
                    .padding(.vertical, Theme.spacing12)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .fill(Color.appBackground)
                    )
                }
                
                Spacer()
                
                // Countdown
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                    Text(String(format: "detail.auto_lock".localized, formatCountdown(countdown)))
                        .font(.system(size: 15))
                }
                .foregroundColor(.appPrimary)
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.spacing16) {
            ZStack {
                Circle()
                    .fill(Color.appDanger.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.appDanger)
            }
            
            Text("detail.error.title".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appDanger)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacing24)
    }
    
    // MARK: - Screenshot Warning
    
    private var screenshotWarning: some View {
        HStack(spacing: Theme.spacing12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
            
            Text("detail.screenshot_warning".localized)
                .font(.system(size: 14))
                .foregroundColor(.orange.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.orange.opacity(0.15))
        )
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button(action: {
            showDeleteConfirmation = true
        }) {
            Text("detail.delete_button".localized)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacing16)
                .background(
                    RoundedRectangle(cornerRadius: Theme.radiusLarge)
                        .fill(Color.appDanger)
                )
        }
    }
    
    // MARK: - Copy Toast
    
    private var copyToastView: some View {
        HStack(spacing: Theme.spacing12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.appSuccess)
            Text("detail.copy_success".localized)
                .font(.system(size: 15))
                .foregroundColor(.appLabel)
        }
        .padding(Theme.spacing16)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.appSurface)
                .shadow(radius: 8)
        )
        .padding(Theme.spacing16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Actions
    
    private func unlockMnemonic() {
        // Check if biometric authentication is required
        if !biometricsRequired {
            // Skip biometric authentication, directly decrypt and show
            viewState = .loading
            Task {
                do {
                    let phrase = try await viewModel.decryptMnemonic(mnemonic)
                    withAnimation {
                        viewState = .unlocked(phrase: phrase, countdown: 60)
                    }
                    startCountdown()
                } catch {
                    withAnimation {
                        viewState = .error(message: "Decryption failed. Please try again.")
                    }
                }
            }
            return
        }
        
        // Require biometric authentication
        viewState = .loading
        
        BiometricService.shared.authenticate(reason: "security.biometric_prompt".localized) { result in
            switch result {
            case .success:
                Task {
                    do {
                        let phrase = try await viewModel.decryptMnemonic(mnemonic)
                        
                        // Log event
                        DiagnosticsLogger.shared.logEvent(.info, title: "Mnemonic Unlocked")
                        
                        withAnimation {
                            viewState = .unlocked(phrase: phrase, countdown: 60)
                        }
                        startCountdown()
                    } catch {
                        withAnimation {
                            viewState = .error(message: "detail.error.message".localized)
                        }
                    }
                }
            case .failure(let error):
                if case .userCancelled = error {
                    withAnimation {
                        viewState = .locked
                    }
                } else {
                    withAnimation {
                        viewState = .error(message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func lockMnemonic() {
        withAnimation {
            viewState = .locked
        }
        stopCountdown()
    }
    
    private func copyToClipboard() {
        if case .unlocked(let phrase, _) = viewState {
            ClipboardService.shared.copy(phrase, clearAfter: 60)
            
            // Log event
            DiagnosticsLogger.shared.logEvent(.warning, title: "Mnemonic Copied to Clipboard")
            
            withAnimation {
                showCopyToast = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showCopyToast = false
                }
            }
        }
    }
    
    private func deleteMnemonic() {
        do {
            try viewModel.deleteMnemonic(mnemonic, context: modelContext)
            dismiss()
        } catch {
            viewState = .error(message: "Failed to delete mnemonic")
        }
    }
    
    // MARK: - Countdown
    
    private func startCountdown() {
        stopCountdown()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if case .unlocked(let phrase, let countdown) = viewState {
                if countdown > 0 {
                    viewState = .unlocked(phrase: phrase, countdown: countdown - 1)
                } else {
                    lockMnemonic()
                }
            }
        }
    }
    
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func formatCountdown(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    NavigationStack {
        MnemonicDetailView(mnemonic: Mnemonic(
            name: "Main ETH Wallet",
            tags: ["Ethereum", "Hot Wallet"],
            encryptedPhrase: Data(),
            note: "Main wallet for Ethereum holdings",
            wordCount: 12
        ))
    }
    .modelContainer(for: Mnemonic.self, inMemory: true)
}
