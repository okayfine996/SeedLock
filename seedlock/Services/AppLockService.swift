//
//  AppLockService.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import Foundation
import SwiftUI
import LocalAuthentication

/// Service for managing app-level lock and authentication
final class AppLockService: ObservableObject {
    static let shared = AppLockService()
    
    @Published var isLocked: Bool = false
    @Published var shouldShowLockScreen: Bool = false
    
    private var lockTimer: Timer?
    private var inactiveTime: Date? // Time when app lost focus (lock screen, background, etc.)
    
    // UIWindow overlay for lock screen (appears above all modals)
    private var lockWindow: UIWindow?
    
    private var appLockEnabled: Bool {
        UserDefaults.standard.bool(forKey: "appLockEnabled")
    }
    
    private var lockTimeoutInterval: TimeInterval {
        // Default to 3 seconds if not set
        let seconds = UserDefaults.standard.integer(forKey: "appLockTimeoutSeconds")
        return seconds > 0 ? TimeInterval(seconds) : 3.0
    }
    
    private var hasUnlockedThisSession = false
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // App loses focus (lock screen, notification center, app switcher, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // App regains focus
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // App enters background (switched to another app)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // App returns from background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - App Lifecycle
    
    @objc private func appWillResignActive() {
        // Called when app loses focus (lock screen, notification center, app switcher, etc.)
        guard appLockEnabled else { return }
        
        inactiveTime = Date()
        isLocked = true
        
        logDebug("App will resign active - recording inactive time")
    }
    
    @objc private func appDidBecomeActive() {
        // Called when app regains focus (unlock screen, return from notification center, etc.)
        guard appLockEnabled else { return }
        
        // If app just launched (first time becoming active)
        if !hasUnlockedThisSession {
            shouldShowLockScreen = true
            isLocked = true
            showLockWindow()
            logDebug("App first launch - showing lock screen")
            return
        }
        
        // Check if app was inactive long enough to require re-authentication
        if let inactiveTime = inactiveTime {
            let timeInterval = Date().timeIntervalSince(inactiveTime)
            logDebug("App was inactive for \(Int(timeInterval)) seconds")
            
            // Require authentication if inactive for more than configured timeout
            // (covers lock screen, app switcher, etc.)
            if timeInterval > lockTimeoutInterval {
                shouldShowLockScreen = true
                isLocked = true
                showLockWindow()
                logInfo("Inactive too long (\(Int(timeInterval))s > \(Int(lockTimeoutInterval))s) - showing lock screen")
            }
        }
    }
    
    @objc private func appDidEnterBackground() {
        // Called when app fully enters background (switched to another app)
        guard appLockEnabled else { return }
        
        inactiveTime = Date()
        isLocked = true
        
        logDebug("App entered background")
    }
    
    @objc private func appWillEnterForeground() {
        // Called when app returns from background
        guard appLockEnabled else { return }
        
        // Always require authentication when returning from background
        shouldShowLockScreen = true
        isLocked = true
        showLockWindow()
        
        logDebug("App will enter foreground - showing lock screen")
    }
    
    // MARK: - Session Management
    
    /// Unlock the app after successful authentication
    func unlock() {
        isLocked = false
        shouldShowLockScreen = false
        hasUnlockedThisSession = true
        inactiveTime = nil
        hideLockWindow()
        
        logSuccess("App unlocked successfully")
    }
    
    /// Lock the app immediately
    func lock() {
        guard appLockEnabled else { return }
        isLocked = true
        shouldShowLockScreen = true
        showLockWindow()
    }
    
    /// Authenticate user to unlock the app
    func authenticate(completion: @escaping (Bool) -> Void) {
        BiometricService.shared.authenticate(reason: "security.app_lock_prompt".localized) { result in
            switch result {
            case .success:
                self.unlock()
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
    
    /// Check if app lock is enabled
    func isAppLockEnabled() -> Bool {
        return appLockEnabled
    }
    
    /// Set the lock timeout interval (in seconds)
    /// - Parameter seconds: Number of seconds of inactivity before requiring re-authentication
    func setLockTimeout(seconds: Int) {
        UserDefaults.standard.set(seconds, forKey: "appLockTimeoutSeconds")
        logInfo("Lock timeout set to \(seconds) seconds")
    }
    
    /// Get the current lock timeout interval (in seconds)
    /// - Returns: Number of seconds before lock is triggered
    func getLockTimeout() -> Int {
        return Int(lockTimeoutInterval)
    }
    
    // MARK: - Window Management
    
    /// Show lock screen in a separate window above all content (including modals)
    private func showLockWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // If window already exists, just make it visible
            if let existingWindow = self.lockWindow {
                existingWindow.isHidden = false
                return
            }
            
            // Get the active window scene
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                logWarning("No active window scene found")
                return
            }
            
            // Create new window
            let window = UIWindow(windowScene: windowScene)
            
            // Set window level to appear above everything (including alerts and modals)
            window.windowLevel = .alert + 1
            
            // Create hosting controller with AppLockView
            let lockView = AppLockView()
            let hostingController = UIHostingController(rootView: lockView)
            hostingController.view.backgroundColor = .clear
            
            // Set as root view controller
            window.rootViewController = hostingController
            
            // Store window reference
            self.lockWindow = window
            
            // Make window visible
            window.makeKeyAndVisible()
            
            logDebug("Lock window created and shown")
        }
    }
    
    /// Hide lock window
    private func hideLockWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Animate window dismissal
            UIView.animate(withDuration: 0.3, animations: {
                self.lockWindow?.alpha = 0
            }) { _ in
                self.lockWindow?.isHidden = true
                self.lockWindow?.resignKey()
                self.lockWindow = nil
                
                logDebug("Lock window hidden and removed")
            }
        }
    }
}

