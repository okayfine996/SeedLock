//
//  BIP39Service.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import Foundation
import CryptoKit

/// Service for generating and validating BIP-39 mnemonic phrases
final class BIP39Service {
    static let shared = BIP39Service()
    
    private init() {}
    
    // MARK: - Word List
    
    private let englishWordList: [String] = {
        // BIP-39 English word list (2048 words)
        // In production, load from a file or embedded resource
        return BIP39WordList.english
    }()
    
    // MARK: - Generate Mnemonic
    
    /// Generates a new BIP-39 mnemonic phrase
    /// - Parameter wordCount: Number of words (12, 15, 18, 21, or 24)
    /// - Returns: Generated mnemonic phrase
    func generateMnemonic(wordCount: Int = 12) throws -> String {
        guard [12, 15, 18, 21, 24].contains(wordCount) else {
            throw BIP39Error.invalidWordCount
        }
        
        // Calculate entropy size (11 bits per word)
        let entropyBits = (wordCount * 11) - (wordCount / 3)
        let entropyBytes = entropyBits / 8
        
        // Generate random entropy
        var entropy = Data(count: entropyBytes)
        let randomResult = entropy.withUnsafeMutableBytes { ptr in
            SecRandomCopyBytes(kSecRandomDefault, entropyBytes, ptr.baseAddress!)
        }
        
        guard randomResult == errSecSuccess else {
            throw BIP39Error.entropyGenerationFailed
        }
        
        // Calculate checksum
        let hash = SHA256.hash(data: entropy)
        let checksumBits = entropyBits / 32
        
        // Combine entropy and checksum
        var bits = entropy.toBinaryString()
        
        let checksumString = Data(hash).toBinaryString()
        bits += String(checksumString.prefix(checksumBits))
        
        // Convert to words
        var words: [String] = []
        for i in stride(from: 0, to: bits.count, by: 11) {
            let endIndex = min(i + 11, bits.count)
            let wordBits = String(bits[bits.index(bits.startIndex, offsetBy: i)..<bits.index(bits.startIndex, offsetBy: endIndex)])
            
            if let index = Int(wordBits, radix: 2), index < englishWordList.count {
                let word = englishWordList[index]
                words.append(word)
            }
        }
        
        let result = words.joined(separator: " ")
        
        return result
    }
    
    // MARK: - Validate Mnemonic
    
    /// Validates a BIP-39 mnemonic phrase
    /// - Parameter mnemonic: The mnemonic phrase to validate
    /// - Returns: Validation result with detailed error information
    func validate(_ mnemonic: String) -> ValidationResult {
        let words = mnemonic
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        // Check word count
        guard [12, 15, 18, 21, 24].contains(words.count) else {
            return .invalid(.invalidWordCount)
        }
        
        // Check all words are in word list
        var unknownWords: [String] = []
        for word in words {
            if !englishWordList.contains(word) {
                unknownWords.append(word)
            }
        }
        
        if !unknownWords.isEmpty {
            return .invalid(.unknownWords(unknownWords))
        }
        
        // Verify checksum
        if !verifyChecksum(words: words) {
            return .invalid(.checksumFailed)
        }
        
        return .valid
    }
    
    // MARK: - Helper Methods
    
    private func verifyChecksum(words: [String]) -> Bool {
        // Convert words to indices
        var indices: [Int] = []
        for word in words {
            if let index = englishWordList.firstIndex(of: word) {
                indices.append(index)
            } else {
                return false
            }
        }
        
        // Convert indices to binary string (each index is 11 bits)
        let bitString = indices.map { index in
            let binary = String(index, radix: 2)
            return String(repeating: "0", count: 11 - binary.count) + binary
        }.joined()
        
        // Calculate expected checksum
        let entropyBits = (words.count * 11) - (words.count / 3)
        let checksumBits = words.count / 3
        
        let entropyString = String(bitString.prefix(entropyBits))
        let checksumString = String(bitString.suffix(checksumBits))
        
        // Convert entropy to data
        guard let entropyData = entropyString.binaryToData() else {
            return false
        }
        
        // Calculate hash
        let hash = SHA256.hash(data: entropyData)
        let calculatedChecksum = Data(hash).toBinaryString().prefix(checksumBits)
        
        return checksumString == calculatedChecksum
    }
    
    /// Cleans up a mnemonic phrase by removing extra spaces and lowercasing
    /// - Parameter mnemonic: The mnemonic to clean
    /// - Returns: Cleaned mnemonic
    func cleanMnemonic(_ mnemonic: String) -> String {
        let lowercased = mnemonic.lowercased()
        
        // Check if the string ends with a space (user is typing)
        let endsWithSpace = lowercased.hasSuffix(" ")
        
        // Clean up: remove extra spaces, trim, and normalize
        let cleaned = lowercased
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        // If original ended with a space and cleaned string is not empty,
        // preserve that space to allow continued typing
        if endsWithSpace && !cleaned.isEmpty {
            return cleaned + " "
        }
        
        return cleaned
    }
    
    // MARK: - Word Suggestions
    
    /// Suggests BIP39 words based on prefix for autocomplete
    /// - Parameter prefix: The partial word to match
    /// - Returns: Array of matching words (up to 10 suggestions)
    func suggestWords(for prefix: String) -> [String] {
        guard !prefix.isEmpty else { return [] }
        
        let lowercasedPrefix = prefix.lowercased()
        
        // Find words that start with the prefix
        let matches = englishWordList.filter { $0.hasPrefix(lowercasedPrefix) }
        
        // Return up to 10 suggestions for better UI
        return Array(matches.prefix(10))
    }
    
    /// Gets the last incomplete word from a mnemonic phrase
    /// - Parameter phrase: The mnemonic phrase
    /// - Returns: The last word if it's incomplete (not followed by space), nil otherwise
    func getLastIncompleteWord(from phrase: String) -> String? {
        guard !phrase.isEmpty else { return nil }
        
        // If phrase ends with space, no incomplete word
        if phrase.hasSuffix(" ") { return nil }
        
        let words = phrase.split(separator: " ")
        guard let lastWord = words.last else { return nil }
        
        let lastWordString = String(lastWord)
        
        // Check if it's a complete BIP39 word
        if englishWordList.contains(lastWordString.lowercased()) {
            return nil
        }
        
        return lastWordString
    }
}

// MARK: - Validation Result

enum ValidationResult {
    case valid
    case invalid(BIP39Error)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var error: BIP39Error? {
        if case .invalid(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Errors

enum BIP39Error: LocalizedError {
    case invalidWordCount
    case unknownWords([String])
    case checksumFailed
    case entropyGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidWordCount:
            return "Invalid word count. Must be 12, 15, 18, 21, or 24 words."
        case .unknownWords(let words):
            return "Unknown words: \(words.joined(separator: ", "))"
        case .checksumFailed:
            return "Checksum verification failed. Please check the last word."
        case .entropyGenerationFailed:
            return "Failed to generate random entropy"
        }
    }
}

// MARK: - Data Extensions

extension Data {
    func toBinaryString() -> String {
        return self.map { byte in
            let binary = String(byte, radix: 2)
            return String(repeating: "0", count: 8 - binary.count) + binary
        }.joined()
    }
}

extension String {
    func binaryToData() -> Data? {
        var data = Data()
        var currentByte: UInt8 = 0
        var bitCount = 0
        
        for char in self {
            if char == "1" {
                currentByte = (currentByte << 1) | 1
            } else if char == "0" {
                currentByte = currentByte << 1
            } else {
                return nil
            }
            
            bitCount += 1
            
            if bitCount == 8 {
                data.append(currentByte)
                currentByte = 0
                bitCount = 0
            }
        }
        
        return data
    }
}

