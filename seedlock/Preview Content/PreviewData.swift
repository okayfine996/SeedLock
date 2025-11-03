//
//  PreviewData.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import Foundation
import SwiftData

@MainActor
class PreviewData {
    static let shared = PreviewData()
    
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Mnemonic.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            
            // Add sample data
            addSampleData()
        } catch {
            fatalError("Failed to create model container for preview: \(error)")
        }
    }
    
    private func addSampleData() {
        let context = container.mainContext
        
        // Sample mnemonic 1
        let mnemonic1 = Mnemonic(
            name: "My Main Wallet",
            tags: ["Bitcoin", "DeFi"],
            encryptedPhrase: Data(),
            isStarred: false,
            note: "Main wallet for Bitcoin holdings",
            wordCount: 12
        )
        context.insert(mnemonic1)
        
        // Sample mnemonic 2
        let mnemonic2 = Mnemonic(
            name: "Long-term Savings",
            tags: ["Ethereum"],
            encryptedPhrase: Data(),
            isStarred: true,
            note: "Long-term investment wallet",
            wordCount: 12
        )
        context.insert(mnemonic2)
        
        // Sample mnemonic 3 (for showing more items)
        let mnemonic3 = Mnemonic(
            name: "Trading Account",
            tags: ["Bitcoin", "Trading", "Hot Wallet"],
            encryptedPhrase: Data(),
            isStarred: false,
            note: "Active trading wallet",
            wordCount: 24
        )
        context.insert(mnemonic3)
        
        try? context.save()
    }
}

