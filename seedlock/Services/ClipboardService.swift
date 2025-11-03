//
//  ClipboardService.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import Foundation
import UIKit

/// Service for managing clipboard operations with automatic clearing
final class ClipboardService {
    static let shared = ClipboardService()
    
    private var clearTimer: Timer?
    private var originalContent: String?
    private var ourClipboardContent: String? // Track content we set
    
    private init() {}
    
    // MARK: - Copy with Auto-Clear
    
    /// Copies text to clipboard and schedules automatic clearing
    /// - Parameters:
    ///   - text: The text to copy
    ///   - timeout: Seconds until clipboard is cleared (default 30)
    ///   - completion: Called when clipboard is cleared
    func copy(_ text: String, clearAfter timeout: TimeInterval = 30, completion: (() -> Void)? = nil) {
        // Save original clipboard content
        originalContent = UIPasteboard.general.string
        
        // Copy to clipboard
        UIPasteboard.general.string = text
        
        // Track that we set this content
        ourClipboardContent = text
        
        // Cancel any existing timer
        clearTimer?.invalidate()
        
        // Schedule clearing
        clearTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.clearClipboard()
            completion?()
        }
        
        logInfo("Copied to clipboard (will clear in \(Int(timeout))s)")
    }
    
    // MARK: - Manual Clear
    
    /// Manually clears the clipboard if it contains sensitive data
    func clearClipboard() {
        // Only clear if clipboard still contains our content
        if let ourContent = ourClipboardContent,
           UIPasteboard.general.string == ourContent {
            // Restore original content or clear if there was none
            UIPasteboard.general.string = originalContent ?? ""
            logInfo("Clipboard cleared (sensitive content removed)")
        } else {
            logDebug("Clipboard not cleared (content changed by user)")
        }
        
        // Cleanup
        clearTimer?.invalidate()
        clearTimer = nil
        originalContent = nil
        ourClipboardContent = nil
    }
    
    /// Cancels the scheduled clipboard clearing
    func cancelScheduledClear() {
        clearTimer?.invalidate()
        clearTimer = nil
    }
    
    // MARK: - Status
    
    /// Returns the remaining time until clipboard is cleared
    /// - Returns: Seconds remaining, or nil if no clear is scheduled
    func remainingClearTime() -> TimeInterval? {
        guard let timer = clearTimer, timer.isValid else {
            return nil
        }
        return timer.fireDate.timeIntervalSinceNow
    }
    
    /// Checks if clipboard clear is scheduled
    var isClearScheduled: Bool {
        return clearTimer?.isValid ?? false
    }
}

