//
//  AppLockView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

struct AppLockView: View {
    @StateObject private var appLockService = AppLockService.shared
    @State private var isAuthenticating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: Theme.spacing32) {
                Spacer()
                
                // App Icon/Logo
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appPrimary)
                }
                
                // Title
                VStack(spacing: Theme.spacing12) {
                    Text("Seedlock")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.appLabel)
                    
                    Text("app_lock.unlock_prompt".localized)
                        .font(.system(size: 17))
                        .foregroundColor(.appSecondaryLabel)
                }
                
                Spacer()
                
                // Unlock Button
                Button(action: authenticateUser) {
                    HStack(spacing: Theme.spacing12) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "faceid")
                                .font(.system(size: 24))
                            Text("app_lock.unlock_button".localized)
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacing16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusLarge)
                            .fill(Color.appPrimary)
                    )
                }
                .disabled(isAuthenticating)
                .padding(.horizontal, Theme.spacing32)
                .padding(.bottom, Theme.spacing32)
            }
        }
        .alert("app_lock.auth_failed.title".localized, isPresented: $showError) {
            Button("app_lock.auth_failed.retry".localized, role: .cancel) {
                authenticateUser()
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Auto-trigger authentication on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authenticateUser()
            }
        }
    }
    
    private func authenticateUser() {
        isAuthenticating = true
        
        appLockService.authenticate { success in
            isAuthenticating = false
            
            if success {
                // Log event
                DiagnosticsLogger.shared.logEvent(.success, title: "App Unlocked")
            } else {
                errorMessage = "Please try again to unlock the app."
                showError = true
            }
        }
    }
}

#Preview {
    AppLockView()
}

