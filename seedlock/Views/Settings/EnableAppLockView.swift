//
//  EnableAppLockView.swift
//  seedlock
//
//  Created by AI Assistant on 25/10/2025.
//

import SwiftUI

struct EnableAppLockView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @Binding var navigateToEnableAppLock: Bool
    
    @State private var isAuthenticating = false
    @State private var authenticationFailed = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Lock Icon
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appPrimary)
                }
                .padding(.bottom, Theme.spacing32)
                
                // Title
                Text("enable_app_lock.title".localized)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appLabel)
                    .padding(.bottom, Theme.spacing12)
                
                // Description
                Text("enable_app_lock.description".localized)
                    .font(.system(size: 17))
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing32)
                    .padding(.bottom, Theme.spacing32 * 1.5)
                
                Spacer()
                
                // Enable Button
                Button(action: enableAppLock) {
                    HStack(spacing: Theme.spacing12) {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "faceid")
                                .font(.system(size: 20))
                            
                            Text("enable_app_lock.button".localized)
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.appPrimary)
                    .cornerRadius(Theme.radiusMedium)
                }
                .disabled(isAuthenticating)
                .padding(.horizontal, Theme.spacing24)
                .padding(.bottom, Theme.spacing16)
                
                // Subtitle
                Text("enable_app_lock.subtitle".localized)
                    .font(.system(size: 13))
                    .foregroundColor(.appTertiaryLabel)
                    .padding(.bottom, Theme.spacing32)
                
                // Error message
                if authenticationFailed {
                    HStack(spacing: Theme.spacing12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(Theme.spacing16)
                    .background(Color.red)
                    .cornerRadius(Theme.radiusMedium)
                    .padding(.horizontal, Theme.spacing24)
                    .padding(.bottom, Theme.spacing32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // User cancelled - disable app lock
                    appLockEnabled = false
                    // Reset navigation state
                    navigateToEnableAppLock = false
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("common.back".localized)
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func enableAppLock() {
        guard !isAuthenticating else { return }
        
        // Check if biometric is available
        guard BiometricService.shared.isBiometricAvailable() else {
            authenticationFailed = true
            errorMessage = "Biometric authentication is not available on this device."
            return
        }
        
        isAuthenticating = true
        authenticationFailed = false
        
        BiometricService.shared.authenticate(reason: "enable_app_lock.button".localized) { result in
            DispatchQueue.main.async {
                isAuthenticating = false
                
                switch result {
                case .success:
                    // Keep App Lock enabled (it's already true from the toggle)
                    // Just log and dismiss
                    
                    // Log event
                    DiagnosticsLogger.shared.logEvent(.success, title: "App Lock Enabled")
                    
                    // Show success feedback with haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Reset navigation state and dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        navigateToEnableAppLock = false
                        dismiss()
                    }
                    
                case .failure(let error):
                    // Authentication failed - disable app lock (reset toggle)
                    appLockEnabled = false
                    
                    // Show error
                    authenticationFailed = true
                    
                    switch error {
                    case .authenticationFailed:
                        errorMessage = "Authentication failed. Please try again."
                    case .userCancelled:
                        errorMessage = "Authentication cancelled."
                        // User cancelled, go back to settings
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            navigateToEnableAppLock = false
                            dismiss()
                        }
                    case .userFallback:
                        errorMessage = "Authentication fallback not supported."
                    case .notAvailable:
                        errorMessage = "Biometric authentication is not available."
                    case .notEnrolled:
                        errorMessage = "No biometric authentication enrolled."
                    case .lockout:
                        errorMessage = "Too many failed attempts. Try again later."
                    case .unknown:
                        errorMessage = "An unknown error occurred."
                    }
                    
                    // Haptic feedback for error
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EnableAppLockView(navigateToEnableAppLock: .constant(true))
    }
}

