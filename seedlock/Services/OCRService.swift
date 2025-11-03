//
//  OCRService.swift
//  seedlock
//
//  Created by Fine Ke on 27/10/2025.
//

import Foundation
import Vision
import UIKit

/// Service for OCR (Optical Character Recognition) to extract text from images
final class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// Recognizes text from an image using advanced OCR
    /// - Parameter image: The image to process
    /// - Returns: Recognized text with multiple candidates
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                // Extract text with multiple candidates for better accuracy
                var allCandidates: [String] = []
                for observation in observations {
                    // Get top 3 candidates for each observation
                    let candidates = observation.topCandidates(3).map { $0.string }
                    allCandidates.append(contentsOf: candidates)
                }
                
                let recognizedText = allCandidates.joined(separator: " ")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // Configure request for maximum accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false // Don't auto-correct BIP39 words
            request.recognitionLanguages = ["en-US"] // BIP39 uses English words
            request.automaticallyDetectsLanguage = false
            
            // Use custom words if available (iOS 16+)
            if #available(iOS 16.0, *) {
                request.customWords = BIP39WordList.english // Use full BIP39 word list for better accuracy
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Extracts mnemonic phrase from recognized text using intelligent matching
    /// - Parameter text: Raw OCR text
    /// - Returns: Cleaned mnemonic phrase (only valid BIP39 words)
    func extractMnemonic(from text: String) -> String {
        // Get all words from text
        let words = text
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        let bip39Words = BIP39WordList.english
        var validWords: [String] = []
        
        for word in words {
            // 1. Exact match
            if bip39Words.contains(word) {
                validWords.append(word)
                continue
            }
            
            // 2. Fix common OCR errors first
            let corrected = correctCommonOCRErrors(word)
            if bip39Words.contains(corrected) {
                validWords.append(corrected)
                continue
            }
            
            // 3. Find best fuzzy match
            if let bestMatch = findBestMatch(for: word, in: bip39Words) {
                validWords.append(bestMatch)
            }
        }
        
        return validWords.joined(separator: " ")
    }
    
    /// Corrects common OCR misrecognition errors
    /// - Parameter word: Word with potential OCR errors
    /// - Returns: Corrected word
    private func correctCommonOCRErrors(_ word: String) -> String {
        let corrections: [Character: Character] = [
            "0": "o",  // Zero to letter O
            "1": "l",  // One to letter L
            "5": "s",  // Five to letter S
            "8": "b",  // Eight to letter B
            "|": "l",  // Pipe to letter L
            "!": "i",  // Exclamation to letter I
        ]
        
        var corrected = word
        for (wrong, right) in corrections {
            corrected = corrected.replacingOccurrences(of: String(wrong), with: String(right))
        }
        
        return corrected
    }
    
    /// Finds the best matching BIP39 word using multiple algorithms
    /// - Parameters:
    ///   - word: The word to match
    ///   - wordList: BIP39 word list
    /// - Returns: Best matching word if found
    private func findBestMatch(for word: String, in wordList: [String]) -> String? {
        var bestMatch: String?
        var bestScore = Int.max
        
        for bip39Word in wordList {
            // Calculate Levenshtein distance
            let distance = word.levenshteinDistance(to: bip39Word)
            
            // Only consider matches within reasonable distance
            guard distance <= 2 else { continue }
            
            // Prefer matches with same length
            let lengthDiff = abs(word.count - bip39Word.count)
            let score = distance * 2 + lengthDiff
            
            if score < bestScore {
                bestScore = score
                bestMatch = bip39Word
            }
        }
        
        // Only return if score is good enough
        return bestScore <= 4 ? bestMatch : nil
    }
    
    /// Recognizes and extracts mnemonic from image in one step
    /// - Parameter image: The image to process
    /// - Returns: Extracted mnemonic phrase
    func recognizeMnemonic(from image: UIImage) async throws -> String {
        let text = try await recognizeText(from: image)
        let mnemonic = extractMnemonic(from: text)
        
        if mnemonic.isEmpty {
            throw OCRError.noMnemonicFound
        }
        
        return mnemonic
    }
}

// MARK: - Errors

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case noMnemonicFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "ocr.error.invalid_image".localized
        case .noTextFound:
            return "ocr.error.no_text".localized
        case .noMnemonicFound:
            return "ocr.error.no_mnemonic".localized
        }
    }
}

// MARK: - String Extension for Levenshtein Distance

extension String {
    /// Calculate Levenshtein distance between two strings (optimized version)
    /// Uses one-dimensional array for better memory efficiency and early termination for speed
    /// - Parameter other: The string to compare with
    /// - Returns: Levenshtein distance between the two strings
    func levenshteinDistance(to other: String) -> Int {
        let m = self.count
        let n = other.count
        
        // Early exit for edge cases
        if m == 0 { return n }
        if n == 0 { return m }
        
        // If length difference is too large, return early
        // This is an optimization since we only care about distances <= 2
        if abs(m - n) > 2 { return abs(m - n) }
        
        // Use one-dimensional arrays for space optimization (O(n) instead of O(m*n))
        var previousRow = [Int](0...n)
        var currentRow = [Int](repeating: 0, count: n + 1)
        
        let selfChars = Array(self)
        let otherChars = Array(other)
        
        for i in 1...m {
            currentRow[0] = i
            
            for j in 1...n {
                let cost = selfChars[i - 1] == otherChars[j - 1] ? 0 : 1
                currentRow[j] = Swift.min(
                    currentRow[j - 1] + 1,      // insertion
                    previousRow[j] + 1,          // deletion
                    previousRow[j - 1] + cost    // substitution
                )
            }
            
            // Swap rows for next iteration
            swap(&previousRow, &currentRow)
        }
        
        return previousRow[n]
    }
}

