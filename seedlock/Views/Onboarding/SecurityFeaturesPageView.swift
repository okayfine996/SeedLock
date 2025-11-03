//
//  SecurityFeaturesPageView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

struct SecurityFeaturesPageView: View {
    @State private var hasInitialized = false  // 页面级别的初始化标志
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(minHeight: 20)  // 最小顶部间距
            
            // Security Illustration (三盾牌)
            SecurityFeaturesIllustrationView()
                .frame(height: 240)
                .id("security-illustration")  // 稳定的视图标识
            
            Spacer()
                .frame(minHeight: 20)  // 最小中间间距
            
            // Title and Description
            VStack(spacing: Theme.spacing16) {
                Text("onboarding.security.title".localized)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.appLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("onboarding.security.subtitle".localized)
                    .font(.system(size: 16))
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Theme.spacing24)
            }
            
            Spacer()
                .frame(minHeight: 20)  // 最小中间间距
            
            // Security Features Cards
            VStack(spacing: Theme.spacing12) {
                SecurityFeatureRow(
                    icon: "network.slash",
                    iconColor: .green,
                    text: "onboarding.security.offline.title".localized
                )
                
                SecurityFeatureRow(
                    icon: "lock.shield.fill",
                    iconColor: .blue,
                    text: "onboarding.security.encryption.title".localized
                )
                
                SecurityFeatureRow(
                    icon: "faceid",
                    iconColor: .purple,
                    text: "onboarding.security.biometric.title".localized
                )
                
                SecurityFeatureRow(
                    icon: "eye.slash.fill",
                    iconColor: .green,
                    text: "onboarding.security.no_tracking.title".localized
                )
            }
            .padding(.horizontal, Theme.spacing24)
            .padding(.bottom, Theme.spacing32)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            if !hasInitialized {
                hasInitialized = true
            }
        }
    }
}

// MARK: - Security Feature Row

struct SecurityFeatureRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.spacing12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.appLabel)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding(.horizontal, Theme.spacing16)
        .padding(.vertical, Theme.spacing12)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.appSurface)
        )
    }
}

// MARK: - Security Features Illustration

struct SecurityFeaturesIllustrationView: View {
    @State private var isAnimating = false
    @State private var particlesOffset: [CGSize] = Array(repeating: .zero, count: 6)
    
    var body: some View {
        ZStack {
            // Three layered shields representing security features
            HStack(spacing: -30) {  // 减小负间距，从 -40 改为 -30
                // Left shield - Network slash (Offline)
                ShieldWithIcon(
                    icon: "network.slash",
                    color: Color.green,
                    rotation: -15,
                    scale: 0.9,  // 稍微缩小
                    animationDelay: 0.0
                )
                .offset(x: 0, y: 20)  // 移除 x 偏移
                .offset(y: isAnimating ? -10 : 0)
                .zIndex(1)
                .id("shield-left")
                
                // Center shield - Lock (Encryption) - Largest
                ShieldWithIcon(
                    icon: "lock.shield.fill",
                    color: Color.blue,
                    rotation: 0,
                    scale: 1.1,  // 从 1.2 减小到 1.1
                    animationDelay: 0.2
                )
                .offset(y: isAnimating ? -15 : 0)
                .zIndex(3)
                .id("shield-center")
                
                // Right shield - Key (Your control)
                ShieldWithIcon(
                    icon: "key.fill",
                    color: Color.green,
                    rotation: 15,
                    scale: 0.9,  // 稍微缩小
                    animationDelay: 0.4
                )
                .offset(x: 0, y: 20)  // 移除 x 偏移
                .offset(y: isAnimating ? -10 : 0)
                .zIndex(2)
                .id("shield-right")
            }
            
            // Animated particles/sparkles
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(Color.appPrimary.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(particlesOffset[index])
                    .blur(radius: 1)
            }
        }
        .frame(height: 240)
        .padding(.horizontal, Theme.spacing24)  // 添加水平内边距
        .task {
            // 使用 .task 代替 .onAppear，只运行一次
            guard !isAnimating else { return }
            
            // Floating animation for shields
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
            
            // Particles floating animation
            animateParticles()
        }
    }
    
    private func animateParticles() {
        for index in 0..<6 {
            let randomX = CGFloat.random(in: -100...100)  // 减小粒子范围
            let randomY = CGFloat.random(in: -80...80)
            
            withAnimation(
                .easeInOut(duration: Double.random(in: 2...4))
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.3)
            ) {
                particlesOffset[index] = CGSize(width: randomX, height: randomY)
            }
        }
    }
}

// MARK: - Shield With Icon

struct ShieldWithIcon: View {
    let icon: String
    let color: Color
    var rotation: Double = 0
    var scale: Double = 1.0
    var animationDelay: Double = 0.0
    
    @State private var isGlowing = false
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Glow effect behind shield
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.5),
                            color.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160 * scale, height: 160 * scale)
                .blur(radius: 10)
                .scaleEffect(isGlowing ? 1.2 : 1.0)
            
            // Shield background
            Image(systemName: "shield.fill")
                .font(.system(size: 100 * scale))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            color.opacity(0.9),
                            color.opacity(0.7),
                            color.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.5), radius: 20, x: 0, y: 10)
                .scaleEffect(isGlowing ? 1.05 : 1.0)
            
            // Icon overlay
            Image(systemName: icon)
                .font(.system(size: 40 * scale, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                .scaleEffect(iconScale)
        }
        .rotationEffect(.degrees(rotation))
        .task {
            // 使用 .task 代替 .onAppear，只运行一次
            guard !isGlowing else { return }
            
            // Glow pulsing animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
                .delay(animationDelay)
            ) {
                isGlowing = true
            }
            
            // Icon breathing animation
            try? await Task.sleep(nanoseconds: UInt64(animationDelay * 1_000_000_000 + 500_000_000))
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                iconScale = 1.1
            }
        }
    }
}

#Preview {
    SecurityFeaturesPageView()
}

