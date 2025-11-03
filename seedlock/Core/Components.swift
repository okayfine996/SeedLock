//
//  Components.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI

// MARK: - Custom Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 15))
            .padding(Theme.spacing16)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .fill(Color.appSurface)
            )
            .foregroundColor(.appLabel)
    }
}

// MARK: - Tag Chips

struct TagChipSmall: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.appLabel)
            .padding(.horizontal, Theme.spacing12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusSmall)
                    .fill(Color.appSurface)
            )
    }
}

struct TagChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.appPrimary)
            .padding(.horizontal, Theme.spacing16)
            .padding(.vertical, Theme.spacing8)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .fill(Color.appPrimary.opacity(0.15))
            )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Safely get width, ensuring it's not NaN or infinite
        let proposedWidth = proposal.replacingUnspecifiedDimensions().width
        let maxWidth = proposedWidth.isNaN || proposedWidth.isInfinite ? 300 : proposedWidth
        
        let result = FlowResult(in: maxWidth, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Safely get bounds width
        let maxWidth = bounds.width.isNaN || bounds.width.isInfinite ? 300 : bounds.width
        let result = FlowResult(in: maxWidth, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            guard index < result.frames.count else { continue }
            let frame = result.frames[index]
            let x = bounds.minX + frame.minX
            let y = bounds.minY + frame.minY
            
            // Ensure position is valid
            if !x.isNaN && !y.isNaN {
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            }
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            // Guard against invalid maxWidth
            guard maxWidth > 0 && !maxWidth.isNaN && !maxWidth.isInfinite else {
                self.size = .zero
                return
            }
            
            // Return early if no subviews
            guard !subviews.isEmpty else {
                self.size = CGSize(width: maxWidth, height: 0)
                return
            }
            
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                // Validate size before using it
                let width = size.width.isNaN || size.width < 0 ? 0 : size.width
                let height = size.height.isNaN || size.height < 0 ? 0 : size.height
                
                if currentX + width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: width, height: height))
                
                lineHeight = max(lineHeight, height)
                currentX += width + spacing
            }
            
            // Calculate final size with validation
            let finalHeight = lineHeight > 0 ? currentY + lineHeight : 0
            self.size = CGSize(
                width: maxWidth,
                height: max(0, finalHeight)
            )
        }
    }
}

