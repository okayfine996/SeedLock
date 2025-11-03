//
//  CloudKeychainPageView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

struct CloudKeychainPageView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Cloud with Lock Illustration (缩小)
            CloudLockIllustrationView()
                .frame(height: 220)
                .padding(.horizontal, Theme.spacing24)
            
            Spacer()
            
            // Title and Description (紧凑)
            VStack(spacing: Theme.spacing16) {
                Text("onboarding.cloud.title".localized)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                
                Text("onboarding.cloud.subtitle".localized)
                    .font(.system(size: 16))
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, Theme.spacing32)
            }
            
            Spacer()
            
            // Feature Cards (水平滚动)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacing12) {
                    CompactFeatureCard(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: .blue,
                        title: "onboarding.cloud.sync.title".localized
                    )
                    
                    CompactFeatureCard(
                        icon: "key.icloud",
                        iconColor: .blue,
                        title: "onboarding.cloud.keychain.title".localized
                    )
                    
                    CompactFeatureCard(
                        icon: "checkmark.shield.fill",
                        iconColor: .blue,
                        title: "onboarding.cloud.backup.title".localized
                    )
                    
                    CompactFeatureCard(
                        icon: "hand.raised.fill",
                        iconColor: .green,
                        title: "onboarding.cloud.optional.title".localized
                    )
                }
                .padding(.horizontal, Theme.spacing24)
            }
            .padding(.bottom, Theme.spacing16)
            
            // Get Started Button
            Button(action: onComplete) {
                Text("onboarding.cloud.get_started".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacing16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusLarge)
                            .fill(Color.appPrimary)
                    )
            }
            .padding(.horizontal, Theme.spacing24)
            .padding(.bottom, Theme.spacing32)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

// MARK: - Compact Feature Card

struct CompactFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        VStack(spacing: Theme.spacing8) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Title
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appLabel)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100)
        .padding(.vertical, Theme.spacing12)
        .padding(.horizontal, Theme.spacing8)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(Color.appSurface)
        )
    }
}

// MARK: - Cloud Lock Illustration View

struct CloudLockIllustrationView: View {
    @State private var cloudFloat = false
    @State private var lockPulse = false
    @State private var particlesOffset: [CGFloat] = Array(repeating: 0, count: 8)  // 增加粒子数量
    @State private var particlesOpacity: [Double] = Array(repeating: 0, count: 8)
    @State private var hasAppeared = false  // 防止重复触发动画
    
    var body: some View {
        ZStack {
            // Glow effect behind cloud
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.5),
                            Color.blue.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)
                .scaleEffect(lockPulse ? 1.2 : 1.0)
            
            // Animated particles - rising from bottom to cloud
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.8),
                                Color.blue.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: CGFloat.random(in: 4...7), height: CGFloat.random(in: 4...7))
                    .blur(radius: 1)
                    .opacity(particlesOpacity[index])
                    .offset(
                        x: CGFloat.random(in: -40...40),  // 水平随机分布
                        y: particlesOffset[index]  // 垂直上升
                    )
            }
            
            // Main cloud icon (simple SF Symbol style, like other pages)
            Image(systemName: "icloud.fill")
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.8),
                            Color.blue.opacity(0.7),
                            Color.blue.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.blue.opacity(0.5), radius: 25, x: 0, y: 12)
                .scaleEffect(cloudFloat ? 1.05 : 0.95)
                .offset(y: cloudFloat ? -8 : 0)
        }
        .frame(height: 220)
        .task {
            // 使用 .task 代替 .onAppear，更稳定
            guard !hasAppeared else { return }
            hasAppeared = true
            
            // Cloud breathing animation
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                cloudFloat = true
            }
            
            // Lock pulsing animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                lockPulse = true
            }
            
            // Particles rising animation
            animateRisingParticles()
        }
    }
    
    private func animateRisingParticles() {
        for index in 0..<8 {
            // 每个粒子有不同的延迟，形成连续上升效果
            let delay = Double(index) * 0.5
            
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // 无限循环每个粒子的上升动画
                while true {
                    // 重置粒子到底部
                    particlesOffset[index] = 110  // 底部起始位置
                    particlesOpacity[index] = 0
                    
                    // 淡入
                    withAnimation(.easeIn(duration: 0.3)) {
                        particlesOpacity[index] = 1.0
                    }
                    
                    // 上升动画 (从底部到云朵)
                    withAnimation(.easeInOut(duration: 2.5)) {
                        particlesOffset[index] = -80  // 上升到云朵位置
                    }
                    
                    // 等待上升完成
                    try? await Task.sleep(nanoseconds: 2_200_000_000)  // 2.2 秒
                    
                    // 淡出（进入云朵）
                    withAnimation(.easeOut(duration: 0.3)) {
                        particlesOpacity[index] = 0
                    }
                    
                    // 等待淡出完成 + 间隔
                    try? await Task.sleep(nanoseconds: 800_000_000)  // 0.8 秒
                    
                    // 循环间隔（让粒子看起来是连续的）
                    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 秒
                }
            }
        }
    }
}

#Preview {
    CloudKeychainPageView(onComplete: {})
}

