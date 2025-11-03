//
//  ScreenshotWarningView.swift
//  seedlock
//
//  Created by Fine Ke on 25/10/2025.
//

import SwiftUI

struct ScreenshotWarningView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.spacing24) {
            // Warning Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }
            
            // Title and Message
            VStack(spacing: Theme.spacing12) {
                Text("screenshot.title".localized)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appLabel)
                
                Text("screenshot.message".localized)
                    .font(.system(size: 15))
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing24)
            }
            
            // Dismiss Button
            Button(action: onDismiss) {
                Text("screenshot.understand".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacing16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusLarge)
                            .fill(Color.orange)
                    )
            }
            .padding(.horizontal, Theme.spacing24)
        }
        .padding(.vertical, Theme.spacing32)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .fill(Color.appSurface)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
        
        ScreenshotWarningView(onDismiss: {})
    }
}

