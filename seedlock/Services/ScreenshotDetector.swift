//
//  ScreenshotDetector.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import UIKit
import SwiftUI

/// Service for detecting screenshots and showing warnings
final class ScreenshotDetector: ObservableObject {
    static let shared = ScreenshotDetector()
    
    @Published var didTakeScreenshot = false
    
    private var screenshotWarningEnabled: Bool {
        UserDefaults.standard.bool(forKey: "screenshotWarningEnabled")
    }
    
    private init() {
        setupObserver()
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
    
    @objc private func screenshotTaken() {
        guard screenshotWarningEnabled else { return }
        
        DispatchQueue.main.async {
            self.didTakeScreenshot = true
        }
    }
    
    func dismissWarning() {
        didTakeScreenshot = false
    }
}

