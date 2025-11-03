//
//  WelcomePageView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

struct WelcomePageView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isAnimating = false
    @State private var contentOpacity = 0.0
    @State private var hasAppeared = false  // 防止重复触发动画
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo and Title
//            VStack(spacing: Theme.spacing16) {
//                Image(systemName: "shield.fill")
//                    .font(.system(size: 40))
//                    .foregroundStyle(
//                        LinearGradient(
//                            colors: [Color.appPrimary, Color.appPrimary.opacity(0.6)],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .scaleEffect(isAnimating ? 1.0 : 0.8)
//                    .opacity(contentOpacity)
//                
//                Text("Vault")
//                    .font(.system(size: 34, weight: .bold))
//                    .foregroundColor(.appLabel)
//                    .opacity(contentOpacity)
//            }
//            .padding(.top, 60)
            
            Spacer()
            
            // Shield Icon with breathing animation
            ShieldIconView()
                .frame(height: 300)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .opacity(contentOpacity)
            
            Spacer()
            
            // Title and Description
            VStack(spacing: Theme.spacing16) {
                Text("onboarding.welcome.title".localized)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.appLabel)
                    .multilineTextAlignment(.center)
                
                Text("onboarding.welcome.subtitle".localized)
                    .font(.system(size: 17))
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Theme.spacing32)
            .opacity(contentOpacity)
            
            Spacer()
        }
        .onAppear {
            // 只在首次出现时启动动画
            guard !hasAppeared else { return }
            hasAppeared = true
            
            // Fade in animation
            withAnimation(.easeOut(duration: 0.8)) {
                contentOpacity = 1.0
            }
            
            // Start breathing animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Shield Icon View

struct ShieldIconView: View {
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var hasAppeared = false  // 防止重复触发动画
    
    var body: some View {
        ZStack {
            // Outer glow rings (pulsing)
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        Color.appPrimary.opacity(0.6 - Double(index) * 0.2),
                        lineWidth: 3
                    )
                    .frame(width: 250 + CGFloat(index) * 30, height: 250 + CGFloat(index) * 30)
                    .scaleEffect(pulseScale)
                    .opacity(1.0 - Double(index) * 0.3)
            }
            
            // Glowing pulse effect (brighter)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appPrimary.opacity(0.6),
                            Color.appPrimary.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 15)
                .scaleEffect(pulseScale)
            
            // Gradient shield with rotation animation (brighter colors)
            Image(systemName: "shield.fill")
                .font(.system(size: 200))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.cyan.opacity(0.6),
                            Color.blue.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.blue.opacity(0.5), radius: 30, x: 0, y: 15)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            // 只在首次出现时启动动画
            guard !hasAppeared else { return }
            hasAppeared = true
            
            // Subtle rotation animation
            withAnimation(
                .linear(duration: 20)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
            
            // Pulsing animation
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.15
            }
        }
    }
}

#Preview {
    WelcomePageView()
}
