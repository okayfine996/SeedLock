//
//  OnboardingView.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // TabView with pages
            TabView(selection: $currentPage) {
                // 1. Welcome - 欢迎页（品牌展示）
                WelcomePageView()
                    .tag(0)
                
                // 2. Security Features - 安全特性（合并 Offline + Features）
                SecurityFeaturesPageView()
                    .tag(1)
                
                // 3. Cloud & Keychain - 可选 iCloud 同步
                CloudKeychainPageView(onComplete: {
                    hasCompletedOnboarding = true
                })
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom page indicator at bottom
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? Color.appPrimary : Color.appSecondaryLabel.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, Theme.spacing24)
            .padding(.bottom, Theme.spacing16)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

#Preview {
    OnboardingView()
}
