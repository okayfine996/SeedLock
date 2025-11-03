//
//  TagPickerView.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI

struct TagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedTags: [String]
    
    @State private var searchText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @AppStorage("customTags") private var customTagsData: Data = Data()
    
    // Common tag suggestions
    private let defaultTags = [
        "Bitcoin", "Ethereum", "DeFi", "Trading",
        "Savings", "Investment", "Hot Wallet", "Cold Storage",
        "Exchange", "Personal", "Business", "Test"
    ]
    
    // Load custom tags from UserDefaults
    private var customTags: [String] {
        get {
            if let decoded = try? JSONDecoder().decode([String].self, from: customTagsData) {
                return decoded
            }
            return []
        }
    }
    
    // All available tags (default + custom)
    private var allTags: [String] {
        var tags = defaultTags
        tags.append(contentsOf: customTags)
        return Array(Set(tags)).sorted() // Remove duplicates and sort
    }
    
    private var filteredSuggestions: [String] {
        if searchText.isEmpty {
            return allTags.filter { !selectedTags.contains($0) }
        } else {
            return allTags.filter {
                $0.localizedCaseInsensitiveContains(searchText) && !selectedTags.contains($0)
            }
        }
    }
    
    private var canCreateNew: Bool {
        !searchText.isEmpty &&
        !selectedTags.contains(searchText) &&
        !allTags.contains(searchText) &&
        searchText.count <= 16
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search/Create Input
                    VStack(spacing: Theme.spacing12) {
                        TextField("tags.search_placeholder".localized, text: $searchText)
                            .textFieldStyle(RoundedTextFieldStyle())
                        
                        // Validation hint
                        if searchText.count > 16 {
                            HStack {
                                Image(systemName: "exclamationmark.circle")
                                Text("tags.max_length_error".localized)
                                Spacer()
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.appDanger)
                        }
                        
                        // Selected tags count
                        if selectedTags.count >= 5 {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("tags.max_selected".localized)
                                Spacer()
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.appWarning)
                        }
                    }
                    .padding(Theme.spacing16)
                    .background(Color.appSurface.opacity(0.5))
                    
                    // Selected Tags
                    if !selectedTags.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.spacing12) {
                            Text(String(format: "tags.selected_count".localized, selectedTags.count))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.appSecondaryLabel)
                            
                            FlowLayout(spacing: Theme.spacing8) {
                                ForEach(selectedTags, id: \.self) { tag in
                                    RemovableTagChip(text: tag) {
                                        selectedTags.removeAll { $0 == tag }
                                    }
                                }
                            }
                        }
                        .padding(Theme.spacing16)
                    }
                    
                    Divider()
                    
                    // Suggestions List
                    ScrollView {
                        VStack(spacing: 0) {
                            // Create new tag option
                            if canCreateNew {
                                Button(action: {
                                    addTag(searchText)
                                    searchText = ""
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.appPrimary)
                                        Text(String(format: "tags.create_new".localized, searchText))
                                            .foregroundColor(.appLabel)
                                        Spacer()
                                    }
                                    .padding(Theme.spacing16)
                                }
                                .disabled(selectedTags.count >= 5)
                                
                                Divider()
                            }
                            
                            // Suggested tags
                            ForEach(filteredSuggestions, id: \.self) { tag in
                                Button(action: {
                                    addTag(tag)
                                    searchText = ""
                                }) {
                                    HStack {
                                        Image(systemName: "tag")
                                            .foregroundColor(.appSecondaryLabel)
                                        Text(tag)
                                            .foregroundColor(.appLabel)
                                        Spacer()
                                    }
                                    .padding(Theme.spacing16)
                                }
                                .disabled(selectedTags.count >= 5)
                                
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("tags.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else { return }
        
        if trimmed.count > 16 {
            errorMessage = "tags.max_length_error".localized
            showError = true
            return
        }
        
        if selectedTags.count >= 5 {
            errorMessage = "tags.max_count_error".localized
            showError = true
            return
        }
        
        if !selectedTags.contains(trimmed) {
            selectedTags.append(trimmed)
        }
        
        // Save custom tag if it's not in default tags
        if !defaultTags.contains(trimmed) && !customTags.contains(trimmed) {
            saveCustomTag(trimmed)
        }
    }
    
    private func saveCustomTag(_ tag: String) {
        var tags = customTags
        if !tags.contains(tag) {
            tags.append(tag)
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(tags) {
                customTagsData = encoded
            }
        }
    }
}

struct RemovableTagChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
            }
        }
        .foregroundColor(.appPrimary)
        .padding(.horizontal, Theme.spacing12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusSmall)
                .fill(Color.appPrimary.opacity(0.15))
        )
    }
}

#Preview {
    TagPickerView(selectedTags: .constant(["Bitcoin", "DeFi"]))
}

