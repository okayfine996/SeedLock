//
//  MnemonicWordGrid.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI

struct MnemonicWordGrid: View {
    let phrase: String
    
    private var words: [String] {
        phrase.components(separatedBy: " ").filter { !$0.isEmpty }
    }
    
    private var columns: [GridItem] {
        // 统一使用 2 列布局，更宽松美观
        let cols = 2
        return Array(repeating: GridItem(.flexible(), spacing: Theme.spacing12), count: cols)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.spacing12) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                WordCell(index: index + 1, word: word)
            }
        }
    }
}

struct WordCell: View {
    let index: Int
    let word: String
    
    var body: some View {
        HStack(spacing: Theme.spacing8) {
            // Index
            Text(String(format: "%02d", index))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.appSecondaryLabel)
                .frame(width: 24, alignment: .trailing)
            
            // Word
            Text(word)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.appLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Theme.spacing8)
        .padding(.horizontal, Theme.spacing12)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusSmall)
                .fill(Color.appSurface)
        )
        .frame(minHeight: 36)
    }
}

struct MnemonicPlaceholderGrid: View {
    let wordCount: Int
    
    private var columns: [GridItem] {
        // 统一使用 2 列布局，更宽松美观
        let cols = 2
        return Array(repeating: GridItem(.flexible(), spacing: Theme.spacing12), count: cols)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.spacing12) {
            ForEach(1...wordCount, id: \.self) { index in
                PlaceholderCell(index: index)
            }
        }
    }
}

struct PlaceholderCell: View {
    let index: Int
    
    var body: some View {
        HStack(spacing: Theme.spacing8) {
            // Index
            Text(String(format: "%02d", index))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.appSecondaryLabel)
                .frame(width: 24, alignment: .trailing)
            
            // Placeholder
            Text("••••••")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appSecondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Theme.spacing8)
        .padding(.horizontal, Theme.spacing12)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusSmall)
                .fill(Color.appSurface.opacity(0.5))
        )
    }
}

#Preview("Unlocked - 12 words") {
    MnemonicWordGrid(phrase: "abandon ability able about above absent absorb abstract absurd abuse access accident")
        .padding()
        .background(Color.appBackground)
}

#Preview("Locked - 12 words") {
    MnemonicPlaceholderGrid(wordCount: 12)
        .padding()
        .background(Color.appBackground)
}

#Preview("Locked - 24 words") {
    MnemonicPlaceholderGrid(wordCount: 24)
        .padding()
        .background(Color.appBackground)
}

