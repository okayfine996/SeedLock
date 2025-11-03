//
//  ContentView.swift
//  seedlock
//
//  Created by Fine Ke on 20/10/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @StateObject private var appLockService = AppLockService.shared
    @StateObject private var screenshotDetector = ScreenshotDetector.shared
    
    var body: some View {
        ZStack {
            // Main Content
            Group {
                if hasCompletedOnboarding {
                    NavigationStack {
                        HomeView()
                    }
                } else {
                    OnboardingView()
                }
            }
            .onAppear {
                // Check if we need to show lock screen on app launch
                if appLockEnabled && !appLockService.shouldShowLockScreen {
                    appLockService.lock()
                }
            }
            
            // Note: App Lock is now shown via UIWindow overlay (appears above all modals)
            // No need for ZStack overlay here anymore
            
            // Screenshot Warning
            if screenshotDetector.didTakeScreenshot {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            screenshotDetector.dismissWarning()
                        }
                    
                    ScreenshotWarningView {
                        screenshotDetector.dismissWarning()
                    }
                }
                .transition(.opacity)
                .zIndex(998)
            }
        }
    }
}

#Preview("Main") {
    ContentView()
        .modelContainer(for: Mnemonic.self, inMemory: true)
}

#Preview("Onboarding") {
    OnboardingView()
}
