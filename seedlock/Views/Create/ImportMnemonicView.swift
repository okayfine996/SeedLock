//
//  ImportMnemonicView.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

/// Item for passing words to review view
struct ReviewItem: Identifiable {
    let id = UUID()
    let words: [String]
}

struct ImportMnemonicView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = MnemonicViewModel()
    
    @State private var phrase: String = ""
    @State private var name: String = ""
    @State private var selectedTags: [String] = []
    @State private var note: String = ""
    @State private var showTagPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // OCR related states
    @State private var selectedImage: PhotosPickerItem?
    @State private var isProcessingImage = false
    @State private var showCameraScanner = false
    
    // Autocomplete states
    @State private var wordSuggestions: [String] = []
    @State private var showSuggestions = false
    
    // Review states
    @State private var showReviewView = false
    @State private var wordsToReview: [String] = []
    @State private var reviewItem: ReviewItem?
    
    // Flag to prevent onChange from cleaning when setting from camera/OCR
    @State private var isSettingFromExternalSource = false
    
    private var wordCount: Int {
        phrase.split(separator: " ").count
    }
    
    private var isValidWordCount: Bool {
        [12, 18, 24].contains(wordCount)
    }
    
    private var isValid: Bool {
        let result = viewModel.validatePhrase(phrase)
        return result.isValid
    }
    
    private var canSave: Bool {
        !name.isEmpty && isValid
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.spacing24) {
                        // Name Input (moved to top)
                        VStack(alignment: .leading, spacing: Theme.spacing12) {
                            Text("import.name.label".localized)
                                .font(.system(size: 17))
                                .foregroundColor(.appLabel)
                            
                            TextField("import.name.placeholder".localized, text: $name)
                                .font(.system(size: 17))
                                .foregroundColor(.appLabel)
                                .padding(Theme.spacing16)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                        .fill(Color.appSurface.opacity(0.6))
                                )
                        }
                        .padding(.horizontal, Theme.spacing16)
                        
                        // Mnemonic Input
                        VStack(alignment: .leading, spacing: Theme.spacing12) {
                            HStack {
                                Text("import.mnemonic.label".localized)
                                    .font(.system(size: 17))
                                    .foregroundColor(.appLabel)
                                
                                Spacer()
                                
                                Button(action: pasteFromClipboard) {
                                    Text("import.paste_button".localized)
                                        .font(.system(size: 17))
                                        .foregroundColor(.appPrimary)
                                }
                            }
                            
                            ZStack(alignment: .topLeading) {
                                if phrase.isEmpty {
                                    Text("import.mnemonic.placeholder".localized)
                                        .font(.system(size: 17))
                                        .foregroundColor(.appSecondaryLabel)
                                        .padding(Theme.spacing16)
                                }
                                
                                TextEditor(text: $phrase)
                                    .font(.system(size: 17))
                                    .foregroundColor(.appLabel)
                                    .frame(height: 180)
                                    .padding(Theme.spacing12)
                                    .scrollContentBackground(.hidden)
                                    .onChange(of: phrase) { _, newValue in
                                        // Only clean if user is typing, not when setting from camera/OCR
                                        if !isSettingFromExternalSource {
                                            phrase = BIP39Service.shared.cleanMnemonic(newValue)
                                        }
                                        updateWordSuggestions()
                                    }
                                
                                // OCR buttons (bottom right)
                                VStack {
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Spacer()
                                        
                                        // Camera scan button
                                        Button(action: { showCameraScanner = true }) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.appPrimary)
                                                    .frame(width: 40, height: 40)
                                                
                                                Image(systemName: "camera")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                            .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                                        }
                                        .disabled(isProcessingImage)
                                        
                                        // Photo library button
                                        PhotosPicker(selection: $selectedImage, matching: .images) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.appPrimary)
                                                    .frame(width: 40, height: 40)
                                                
                                                if isProcessingImage {
                                                    ProgressView()
                                                        .tint(.white)
                                                } else {
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 18, weight: .medium))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                                        }
                                        .disabled(isProcessingImage)
                                        .padding(.trailing, Theme.spacing12)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                    .fill(Color.appSurface.opacity(0.6))
                            )
                            .onChange(of: selectedImage) { _, newItem in
                                Task {
                                    await processSelectedImage(newItem)
                                }
                            }
                            
                            // Word Suggestions (Autocomplete)
                            if showSuggestions && !wordSuggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("import.suggestions.title".localized)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.appSecondaryLabel)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(wordSuggestions, id: \.self) { word in
                                                Button(action: {
                                                    applySuggestion(word)
                                                }) {
                                                    Text(word)
                                                        .font(.system(size: 15))
                                                        .foregroundColor(.appPrimary)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 8)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .fill(Color.appPrimary.opacity(0.1))
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                                                        )
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Validation Message - Enhanced with detailed feedback
                            if !phrase.isEmpty {
                                let validationResult = viewModel.validatePhrase(phrase)
                                
                                switch validationResult {
                                case .valid:
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("import.validation.valid".localized)
                                            .font(.system(size: 15))
                                            .foregroundColor(.green)
                                    }
                                    .padding(.vertical, 8)
                                    
                                case .invalid(let error):
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.red)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(error.errorDescription ?? "Unknown error")
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.red)
                                                
                                                // Show specific unknown words if any
                                                if case .unknownWords(let words) = error {
                                                    Text("Unknown: \(words.joined(separator: ", "))")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.appSecondaryLabel)
                                                        .lineLimit(3)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.spacing16)
                        
                        // Tags
                        VStack(alignment: .leading, spacing: Theme.spacing12) {
                            Text("import.tags.label".localized)
                                .font(.system(size: 17))
                                .foregroundColor(.appLabel)
                            
                            Button(action: {
                                showTagPicker = true
                            }) {
                                HStack(spacing: Theme.spacing12) {
                                    if selectedTags.isEmpty {
                                        Text("import.tags.select".localized)
                                            .font(.system(size: 17))
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
                                        .foregroundColor(.appTertiaryLabel)
                                }
                                .padding(Theme.spacing16)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                        .fill(Color.appSurface.opacity(0.6))
                                )
                            }
                        }
                        .padding(.horizontal, Theme.spacing16)
                        
                        // Note (Optional)
                        VStack(alignment: .leading, spacing: Theme.spacing12) {
                            Text("import.note.label".localized)
                                .font(.system(size: 17))
                                .foregroundColor(.appLabel)
                            
                            ZStack(alignment: .topLeading) {
                                if note.isEmpty {
                                    Text("import.note.placeholder".localized)
                                        .font(.system(size: 17))
                                        .foregroundColor(.appSecondaryLabel)
                                        .padding(Theme.spacing16)
                                }
                                
                                TextEditor(text: $note)
                                    .font(.system(size: 17))
                                    .foregroundColor(.appLabel)
                                    .frame(height: 120)
                                    .padding(Theme.spacing12)
                                    .scrollContentBackground(.hidden)
                                    .onChange(of: note) { _, newValue in
                                        if newValue.count > 200 {
                                            note = String(newValue.prefix(200))
                                        }
                                    }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                    .fill(Color.appSurface.opacity(0.6))
                            )
                        }
                        .padding(.horizontal, Theme.spacing16)
                        
                        // Save Button
                        Button(action: saveMnemonic) {
                            Text("import.save_button".localized)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.spacing16)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                        .fill(canSave ? Color.appPrimary : Color.appPrimary.opacity(0.5))
                                )
                        }
                        .disabled(!canSave)
                        .padding(.horizontal, Theme.spacing16)
                        .padding(.bottom, Theme.spacing32)
                    }
                    .padding(.top, Theme.spacing8)
                }
            }
            .navigationTitle("import.title".localized)
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
        .fullScreenCover(isPresented: $showCameraScanner) {
            CameraScannerView(recognizedText: Binding(
                get: { phrase },
                set: { newValue in
                    // When camera scanner returns text, directly set phrase
                    isSettingFromExternalSource = true
                    let cleanedText = BIP39Service.shared.cleanMnemonic(newValue)
                    phrase = cleanedText
                    // Reset flag after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSettingFromExternalSource = false
                    }
                }
            ))
        }
        .sheet(item: $reviewItem) { item in
            MnemonicReviewView(words: item.words) { confirmedWords in
                // When confirmed in review view, update phrase and save
                phrase = confirmedWords.joined(separator: " ")
                // Save after review confirmation
                performSave()
            }
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func pasteFromClipboard() {
        if let clipboardText = UIPasteboard.general.string {
            isSettingFromExternalSource = true
            let cleanedText = BIP39Service.shared.cleanMnemonic(clipboardText)
            phrase = cleanedText
            // Reset flag after a short delay to allow onChange to work normally
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSettingFromExternalSource = false
            }
        }
    }
    
    private func processSelectedImage(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isProcessingImage = true
        
        do {
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                errorMessage = "ocr.error.load_failed".localized
                showError = true
                isProcessingImage = false
                return
            }
            
            // Perform OCR
            let recognizedPhrase = try await OCRService.shared.recognizeMnemonic(from: uiImage)
            
            // Update UI on main thread
            await MainActor.run {
                // Directly set phrase from OCR result
                isSettingFromExternalSource = true
                phrase = recognizedPhrase
                // Reset flag after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSettingFromExternalSource = false
                }
                
                // Log event
                DiagnosticsLogger.shared.logEvent(.success, title: "OCR Recognition Successful")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                
                // Log error
                DiagnosticsLogger.shared.logEvent(.error, title: "OCR Recognition Failed")
            }
        }
        
        isProcessingImage = false
        
        // Reset selection for next use
        selectedImage = nil
    }
    
    private func saveMnemonic() {
        // Extract words from phrase and show review view
        let cleanedPhrase = BIP39Service.shared.cleanMnemonic(phrase)
        let words = cleanedPhrase.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        
        if !words.isEmpty {
            // Show review view before saving
            wordsToReview = words
            // Create review item with words and show sheet
            reviewItem = ReviewItem(words: words)
        } else {
            // If no words, show error
            errorMessage = "import.error.invalid_phrase".localized
            showError = true
        }
    }
    
    /// Performs the actual save operation after review confirmation
    private func performSave() {
        Task {
            do {
                _ = try await viewModel.createMnemonic(
                    name: name,
                    phrase: phrase,
                    tags: selectedTags,
                    note: note.isEmpty ? nil : note,
                    context: modelContext
                )
                
                // Log event
                DiagnosticsLogger.shared.logEvent(.success, title: "Mnemonic Imported")
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    // MARK: - Autocomplete Helpers
    
    private func updateWordSuggestions() {
        // Get the last incomplete word
        guard let incompleteWord = BIP39Service.shared.getLastIncompleteWord(from: phrase) else {
            withAnimation {
                showSuggestions = false
                wordSuggestions = []
            }
            return
        }
        
        // Get suggestions for this word
        let suggestions = BIP39Service.shared.suggestWords(for: incompleteWord)
        
        withAnimation {
            wordSuggestions = suggestions
            showSuggestions = !suggestions.isEmpty
        }
    }
    
    private func applySuggestion(_ word: String) {
        // Replace the last incomplete word with the suggestion
        let words = phrase.split(separator: " ").dropLast()
        let completedPhrase = words.isEmpty ? word : words.joined(separator: " ") + " " + word
        phrase = completedPhrase + " " // Add space after to continue typing
        
        // Clear suggestions
        withAnimation {
            showSuggestions = false
            wordSuggestions = []
        }
    }
}

#Preview {
    ImportMnemonicView()
        .modelContainer(for: Mnemonic.self, inMemory: true)
}

