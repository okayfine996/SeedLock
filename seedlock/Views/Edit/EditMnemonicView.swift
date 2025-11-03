//
//  EditMnemonicView.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI
import SwiftData

struct EditMnemonicView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("biometricsRequired") private var biometricsRequired = false
    @StateObject private var viewModel = MnemonicViewModel()
    
    let mnemonic: Mnemonic
    
    @State private var name: String
    @State private var selectedTags: [String]
    @State private var note: String
    @State private var showTagPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isUnlocked = false
    @State private var decryptedPhrase: String = ""
    @State private var showingCopiedAlert = false
    
    init(mnemonic: Mnemonic) {
        self.mnemonic = mnemonic
        _name = State(initialValue: mnemonic.name)
        _selectedTags = State(initialValue: mnemonic.tags)
        _note = State(initialValue: mnemonic.note ?? "")
    }
    
    private var canSave: Bool {
        !name.isEmpty && note.count <= 200
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.spacing24) {
                        // Name Input
                        VStack(alignment: .leading, spacing: Theme.spacing8) {
                            Text("edit.name.label".localized)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appLabel)
                            
                            TextField("edit.name.placeholder".localized, text: $name)
                                .textFieldStyle(RoundedTextFieldStyle())
                            
                            if name.isEmpty {
                                Text("edit.name.required".localized)
                                    .font(.system(size: 13))
                                    .foregroundColor(.appDanger)
                            }
                        }
                        
                        // Mnemonic Phrase Section
                        VStack(alignment: .leading, spacing: Theme.spacing12) {
                            Text("edit.mnemonic.label".localized)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appLabel)
                            
                            if isUnlocked && !decryptedPhrase.isEmpty {
                                // Unlocked - Show mnemonic
                                VStack(spacing: Theme.spacing12) {
                                    MnemonicWordGrid(phrase: decryptedPhrase)
                                    
                                    // Action buttons
                                    HStack(spacing: Theme.spacing12) {
                                        Button(action: copyMnemonic) {
                                            HStack(spacing: Theme.spacing8) {
                                                Image(systemName: "doc.on.doc")
                                                    .font(.system(size: 14))
                                                Text("edit.copy_button".localized)
                                                    .font(.system(size: 15, weight: .medium))
                                            }
                                            .foregroundColor(.appPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, Theme.spacing12)
                                            .background(
                                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                                    .fill(Color.appPrimary.opacity(0.15))
                                            )
                                        }
                                        
                                        Button(action: lockMnemonic) {
                                            HStack(spacing: Theme.spacing8) {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 14))
                                                Text("edit.lock_button".localized)
                                                    .font(.system(size: 15, weight: .medium))
                                            }
                                            .foregroundColor(.appSecondaryLabel)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, Theme.spacing12)
                                            .background(
                                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                                    .fill(Color.appSurface)
                                            )
                                        }
                                    }
                                }
                                .padding(Theme.spacing16)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                        .fill(Color.appSurface)
                                )
                            } else {
                                // Locked - Show unlock button
                                Button(action: unlockMnemonic) {
                                    HStack(spacing: Theme.spacing12) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.appPrimary)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("edit.mnemonic.encrypted".localized)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.appLabel)
                                            
                                            Text("edit.mnemonic.unlock_hint".localized)
                                                .font(.system(size: 13))
                                                .foregroundColor(.appSecondaryLabel)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.appSecondaryLabel)
                                    }
                                    .padding(Theme.spacing16)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                            .fill(Color.appSurface)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: Theme.spacing8) {
                            Text("edit.tags.label".localized)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appLabel)
                            
                            Button(action: {
                                showTagPicker = true
                            }) {
                                HStack {
                                    if selectedTags.isEmpty {
                                        Text("edit.tags.placeholder".localized)
                                            .foregroundColor(.appSecondaryLabel)
                                    } else {
                                        FlowLayout(spacing: Theme.spacing8) {
                                            ForEach(selectedTags, id: \.self) { tag in
                                                TagChip(text: tag)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.appSecondaryLabel)
                                }
                                .padding(Theme.spacing16)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                        .fill(Color.appSurface)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Note
                        VStack(alignment: .leading, spacing: Theme.spacing8) {
                            HStack {
                                Text("edit.note.label".localized)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.appLabel)
                                
                                Spacer()
                                
                                Text(String(format: "edit.note.counter".localized, note.count))
                                    .font(.system(size: 13))
                                    .foregroundColor(note.count > 200 ? .appDanger : .appSecondaryLabel)
                            }
                            
                            TextEditor(text: $note)
                                .frame(height: 100)
                                .padding(Theme.spacing12)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                        .fill(Color.appSurface)
                                )
                                .onChange(of: note) { _, newValue in
                                    if newValue.count > 200 {
                                        note = String(newValue.prefix(200))
                                    }
                                }
                        }
                    }
                    .padding(Theme.spacing16)
                }
            }
            .navigationTitle("edit.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("edit.cancel_button".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("edit.save_button".localized) {
                        saveMnemonic()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerView(selectedTags: $selectedTags)
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) {}
            } message: {
                Text(errorMessage)
            }
            .alert("common.success".localized, isPresented: $showingCopiedAlert) {
                Button("common.ok".localized) {}
            } message: {
                Text("edit.copy_success".localized)
            }
        }
    }
    
    // MARK: - Mnemonic Actions
    
    private func unlockMnemonic() {
        // Check if biometric authentication is required
        if biometricsRequired {
            // Require biometric authentication
            BiometricService.shared.authenticate(reason: "security.unlock_mnemonic".localized) { result in
                switch result {
                case .success:
                    decryptAndShowMnemonic()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        } else {
            // Directly unlock without biometric authentication
            decryptAndShowMnemonic()
        }
    }
    
    private func decryptAndShowMnemonic() {
        Task {
            do {
                let phrase = try await viewModel.decryptMnemonic(mnemonic)
                await MainActor.run {
                    decryptedPhrase = phrase
                    isUnlocked = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to decrypt: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func lockMnemonic() {
        decryptedPhrase = ""
        isUnlocked = false
    }
    
    private func copyMnemonic() {
        // Get clipboard timeout from settings (default 60 seconds)
        let timeout = TimeInterval(UserDefaults.standard.integer(forKey: "clipboardTimeout"))
        let clearAfter = timeout > 0 ? timeout : 60
        
        ClipboardService.shared.copy(decryptedPhrase, clearAfter: clearAfter) {
            // Clipboard cleared after timeout
        }
        
        showingCopiedAlert = true
    }
    
    private func saveMnemonic() {
        do {
            try viewModel.updateMnemonic(
                mnemonic,
                name: name,
                tags: selectedTags,
                note: note.isEmpty ? nil : note,
                context: modelContext
            )
            
            // Log event
            DiagnosticsLogger.shared.logEvent(.info, title: "Mnemonic Updated")
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    EditMnemonicView(mnemonic: Mnemonic(
        name: "My Main Wallet",
        tags: ["Bitcoin", "DeFi"],
        encryptedPhrase: Data(),
        note: "My primary wallet"
    ))
    .modelContainer(for: Mnemonic.self, inMemory: true)
}

