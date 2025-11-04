//
//  CreateMnemonicView.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI
import SwiftData

struct CreateMnemonicView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = MnemonicViewModel()
    
    @State private var name: String = ""
    @State private var selectedTags: [String] = []
    @State private var note: String = ""
    @State private var selectedWordCount: Int = 12
    @State private var selectedLanguage: String = "English"
    @State private var generatedPhrase: String = ""
    @State private var hasGenerated: Bool = false
    @State private var showSaveConfirmation = false
    @State private var showSuccessAlert = false
    @State private var showTagPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let wordCountOptions = [12, 15, 18, 21, 24]
    private let languageOptions = ["English"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.spacing24) {
                    // Name Input
                    VStack(alignment: .leading, spacing: Theme.spacing8) {
                        Text("create.name.label".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appLabel)
                        
                        TextField("create.name.placeholder".localized, text: $name)
                            .textFieldStyle(RoundedTextFieldStyle())
                        
                        if name.isEmpty && hasGenerated {
                            Text("create.name.required".localized)
                                .font(.system(size: 13))
                                .foregroundColor(.appDanger)
                        }
                    }
                    
                    // Generator Section
                    VStack(alignment: .leading, spacing: Theme.spacing16) {
                        // Mnemonic Length
                        VStack(alignment: .leading, spacing: Theme.spacing12) {
                            Text("create.length.label".localized)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appLabel)
                            
                            HStack(spacing: Theme.spacing12) {
                                ForEach(wordCountOptions, id: \.self) { count in
                                    Button(action: {
                                        selectedWordCount = count
                                    }) {
                                        Text("\(count)")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(selectedWordCount == count ? .white : .appLabel)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, Theme.spacing12)
                                            .background(
                                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                                    .fill(selectedWordCount == count ? Color.appPrimary : Color.appSurface)
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Generate Button
                        Button(action: {
                            generateMnemonic()
                        }) {
                            HStack(spacing: Theme.spacing8) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: hasGenerated ? "arrow.clockwise" : "wand.and.stars")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text("create.generate_button".localized)
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacing16)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                    .fill(viewModel.isLoading ? Color.appPrimary.opacity(0.6) : Color.appPrimary)
                            )
                        }
                        .disabled(viewModel.isLoading)
                    }
                    
                    // Preview Section
                    VStack(alignment: .leading, spacing: Theme.spacing12) {
                        HStack {
                            Text("create.preview.title".localized)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.appLabel)
                            
                            // Debug indicator
                            if hasGenerated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 14))
                            }
                        }
                        
                        if hasGenerated {
                            VStack(alignment: .leading, spacing: Theme.spacing12) {
                                // Simple list view for debugging
                                let words = generatedPhrase.components(separatedBy: " ").filter { !$0.isEmpty }
                                
                                if words.isEmpty {
                                    Text("⚠️ No words found!")
                                        .foregroundColor(.red)
                                } else {
                                    // Try grid first
                                    MnemonicWordGrid(phrase: generatedPhrase)
                                }
                            }
                            .padding(Theme.spacing16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundColor(.appDivider)
                            )
                            .transition(.opacity.combined(with: .scale))
                        } else {
                            VStack(spacing: Theme.spacing8) {
                                Image(systemName: "lock.shield")
                                    .font(.system(size: 32))
                                    .foregroundColor(.appSecondaryLabel.opacity(0.5))
                                
                                Text("create.preview.empty".localized)
                                    .font(.system(size: 15))
                                    .foregroundColor(.appSecondaryLabel)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundColor(.appDivider)
                            )
                        }
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: Theme.spacing8) {
                        Text("create.tags.label".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appLabel)
                        
                        Button(action: {
                            showTagPicker = true
                        }) {
                            HStack(spacing: Theme.spacing12) {
                                if selectedTags.isEmpty {
                                    Text("create.tags.select".localized)
                                        .font(.system(size: 15))
                                        .foregroundColor(.appSecondaryLabel)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: Theme.spacing8) {
                                            ForEach(selectedTags, id: \.self) { tag in
                                                Text(tag)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, Theme.spacing12)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: Theme.radiusLarge)
                                                            .fill(Color.appPrimary)
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appSecondaryLabel)
                            }
                            .padding(Theme.spacing16)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                    .fill(Color.appSurface)
                            )
                        }
                    }
                    
                    // Note
                    VStack(alignment: .leading, spacing: Theme.spacing8) {
                        Text("create.note.label".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appLabel)
                        
                        ZStack(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("create.note.placeholder".localized)
                                    .font(.system(size: 15))
                                    .foregroundColor(.appSecondaryLabel)
                                    .padding(.horizontal, Theme.spacing16)
                                    .padding(.vertical, Theme.spacing12)
                            }
                            
                            TextEditor(text: $note)
                                .frame(height: 120)
                                .padding(.horizontal, Theme.spacing12)
                                .padding(.vertical, Theme.spacing8)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                        .fill(Color.appSurface)
                                )
                                .scrollContentBackground(.hidden)
                                .onChange(of: note) { _, newValue in
                                    if newValue.count > 200 {
                                        note = String(newValue.prefix(200))
                                    }
                                }
                        }
                    }
                    
                    // Save Button
                    Button(action: {
                        showSaveConfirmation = true
                    }) {
                        Text("common.save".localized)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacing16)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                    .fill(canSave ? Color.appPrimary : Color.appSecondaryLabel.opacity(0.3))
                            )
                    }
                    .disabled(!canSave)
                    .padding(.bottom, Theme.spacing32)
                }
                .padding(Theme.spacing16)
                .padding(.top, Theme.spacing8)
                }
            }
            .navigationTitle("create.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
        .sheet(isPresented: $showTagPicker) {
            TagPickerView(selectedTags: $selectedTags)
        }
        .alert("create.save_confirmation.title".localized, isPresented: $showSaveConfirmation) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.save".localized) {
                saveMnemonic()
            }
        } message: {
            Text("create.save_confirmation.message".localized)
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if showSuccessAlert {
                SuccessAlertView(onDismiss: {
                    showSuccessAlert = false
                    dismiss()
                })
            }
        }
    }
    
    private var canSave: Bool {
        !name.isEmpty && hasGenerated && note.count <= 200
    }
    
    private func generateMnemonic() {
        do {
            let phrase = try viewModel.generatePhrase(wordCount: selectedWordCount)
            
            withAnimation(.easeInOut(duration: 0.3)) {
                generatedPhrase = phrase
                hasGenerated = true
            }
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func saveMnemonic() {
        Task {
            do {
                _ = try await viewModel.createMnemonic(
                    name: name,
                    phrase: generatedPhrase,
                    tags: selectedTags,
                    note: note.isEmpty ? nil : note,
                    context: modelContext
                )
                // Show success alert
                withAnimation {
                    showSuccessAlert = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Success Alert View

struct SuccessAlertView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissing by tapping backdrop
                }
            
            // Alert Card
            VStack(spacing: Theme.spacing24) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, Theme.spacing16)
                
                // Title and Message
                VStack(spacing: Theme.spacing12) {
                    Text("create.success.title".localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.appLabel)
                    
                    Text("create.success.message".localized)
                        .font(.system(size: 15))
                        .foregroundColor(.appSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.spacing24)
                }
                
                // Done Button
                Button(action: onDismiss) {
                    Text("common.done".localized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacing16)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                                .fill(Color.appPrimary)
                        )
                }
                .padding(.horizontal, Theme.spacing24)
                .padding(.bottom, Theme.spacing24)
            }
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusLarge)
                    .fill(Color.appSurface)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

#Preview {
    CreateMnemonicView()
        .modelContainer(for: Mnemonic.self, inMemory: true)
}

