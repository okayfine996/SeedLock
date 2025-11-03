//
//  LaunchScreenView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowPulse: Bool = false
    
    var body: some View {
        if isActive {
            // 根据 onboarding 状态决定显示哪个页面
            ContentView()
        } else {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.appBackground,
                        Color.appBackground.opacity(0.9),
                        Color.appPrimary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated particles in background
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: CGFloat.random(in: 4...12))
                        .offset(
                            x: CGFloat.random(in: -200...200),
                            y: CGFloat.random(in: -400...400)
                        )
                        .blur(radius: 2)
                }
                
                VStack(spacing: Theme.spacing32) {
                    Spacer()
                    
                    // Logo and Icon
                    ZStack {
                        // Outer glow rings
                        ForEach(0..<3) { index in
                            Circle()
                                .stroke(
                                    Color.appPrimary.opacity(0.3 - Double(index) * 0.1),
                                    lineWidth: 2
                                )
                                .frame(width: 160 + CGFloat(index * 30))
                                .scaleEffect(glowPulse ? 1.1 : 1.0)
                                .opacity(glowPulse ? 0.3 : 0.6)
                        }
                        
                        // Main circle background
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.appPrimary.opacity(0.3),
                                        Color.appPrimary.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 180, height: 180)
                            .blur(radius: 20)
                            .scaleEffect(glowPulse ? 1.15 : 1.0)
                        
                        // Shield icon with gradient
                        ZStack {
                            // Shield background
                            Image(systemName: "shield.fill")
                                .font(.system(size: 80, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.appPrimary,
                                            Color.appPrimary.opacity(0.8),
                                            Color.blue.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.appPrimary.opacity(0.5), radius: 20, x: 0, y: 10)
                            
                            // Lock icon overlay
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .offset(y: -2)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    }
                    
                    // App name and tagline
                    VStack(spacing: Theme.spacing12) {
                        Text("SeedLock")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.appLabel,
                                        Color.appLabel.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(textOpacity)
                        
                        Text("launch.tagline".localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appSecondaryLabel)
                            .opacity(textOpacity)
                    }
                    
                    Spacer()
                    
                    // Loading indicator
                    VStack(spacing: Theme.spacing12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                            .scaleEffect(1.2)
                        
                        Text("launch.loading".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.appSecondaryLabel)
                    }
                    .opacity(textOpacity)
                    .padding(.bottom, Theme.spacing32 * 2)
                }
            }
            .onAppear {
                startAnimations()
                
                // Dismiss launch screen after animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
    
    private func startAnimations() {
        // Logo scale and fade in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Text fade in
        withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Continuous glow pulse
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = true
        }
    }
}

#Preview {
    LaunchScreenView()
}

