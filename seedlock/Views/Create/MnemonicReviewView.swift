//
//  MnemonicReviewView.swift
//  seedlock
//
//  Created by Fine Ke on 27/10/2025.
//

import SwiftUI

/// Identifiable word item for drag and drop
struct WordItem: Identifiable, Equatable {
    let id: UUID
    let word: String
    let originalIndex: Int
    
    init(word: String, originalIndex: Int) {
        self.id = UUID()
        self.word = word
        self.originalIndex = originalIndex
    }
}

/// View for reviewing and reordering recognized mnemonic words
struct MnemonicReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let words: [String]
    let onConfirm: ([String]) -> Void
    
    @State private var wordItems: [WordItem] = []
    
    // Haptic feedback generator for drag interactions
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Info
                    VStack(spacing: Theme.spacing12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("import.review.title".localized)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.appLabel)
                        
                        Text("import.review.description".localized)
                            .font(.system(size: 15))
                            .foregroundColor(.appSecondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacing24)
                        
                        // Word count indicator
                        HStack(spacing: 8) {
                            Image(systemName: "text.word.spacing")
                                .font(.system(size: 14))
                            Text("\(wordItems.count) words")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.appSecondaryLabel)
                        .padding(.horizontal, Theme.spacing16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.appSurface.opacity(0.6))
                        )
                    }
                    .padding(.top, Theme.spacing24)
                    .padding(.bottom, Theme.spacing16)
                    
                    // Words List with Native Drag to Reorder
                    List {
                        ForEach(Array(wordItems.enumerated()), id: \.element.id) { index, item in
                            WordRow(
                                index: index + 1,
                                word: item.word
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onMove { source, destination in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                wordItems.move(fromOffsets: source, toOffset: destination)
                            }
                            // Haptic feedback when reordering
                            impactFeedback.impactOccurred()
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, .constant(.active))
                    
                    // Hint
                    HStack(spacing: 8) {
                        Image(systemName: "hand.draw")
                            .font(.system(size: 14))
                        Text("import.review.drag_hint".localized)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.appSecondaryLabel)
                    .padding(.horizontal, Theme.spacing16)
                    .padding(.vertical, Theme.spacing12)
                    
                    // Action Buttons
                    VStack(spacing: Theme.spacing12) {
                        Button(action: confirm) {
                            Text("import.review.confirm".localized)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.spacing16)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                        .fill(Color.appPrimary)
                                )
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("import.review.cancel".localized)
                                .font(.system(size: 17))
                                .foregroundColor(.appSecondaryLabel)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.spacing16)
                        }
                    }
                    .padding(.horizontal, Theme.spacing16)
                    .padding(.bottom, Theme.spacing24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.appPrimary)
                    }
                }
            }
        }
        .onAppear {
            // Initialize word items with unique IDs
            wordItems = words.enumerated().map { index, word in
                WordItem(word: word, originalIndex: index)
            }
            // Prepare haptic feedback generator for better responsiveness
            impactFeedback.prepare()
        }
    }
    
    // MARK: - Actions
    
    private func confirm() {
        // Haptic feedback for confirmation
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Convert word items back to string array
        let confirmedWords = wordItems.map { $0.word }
        onConfirm(confirmedWords)
        dismiss()
    }
}

// MARK: - Word Row Component

struct WordRow: View {
    let index: Int
    let word: String
    
    var body: some View {
        HStack(spacing: Theme.spacing12) {
            // Index Badge
            Text(String(format: "%02d", index))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.appSecondaryLabel)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.appSurface.opacity(0.6))
                )
            
            // Word
            Text(word)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Drag Handle
//            Image(systemName: "line.3.horizontal")
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(.appTertiaryLabel)
        }
        .padding(.horizontal, Theme.spacing16)
        .padding(.vertical, Theme.spacing12)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.appSurface.opacity(0.6))
        )
    }
}

#Preview {
    MnemonicReviewView(
        words: [
            "abandon", "ability", "able", "about", "above", "absent",
            "absorb", "abstract", "absurd", "abuse", "access", "accident"
        ],
        onConfirm: { words in
            print("Confirmed: \(words.joined(separator: " "))")
        }
    )
}

