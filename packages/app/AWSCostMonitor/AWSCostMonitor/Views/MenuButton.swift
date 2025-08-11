//
//  MenuButton.swift
//  AWSCostMonitor
//
//  Custom menu button with hover and press effects
//

import SwiftUI

struct MenuButton: View {
    let action: () -> Void
    let label: String
    let systemImage: String
    let shortcut: String?
    @Binding var hoveredItem: String?
    @Binding var pressedItem: String?
    let itemId: String
    
    var body: some View {
        Button(action: {
            // Show press animation
            withAnimation(.easeInOut(duration: 0.1)) {
                pressedItem = itemId
            }
            
            // Execute action after brief delay for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressedItem = nil
                }
            }
        }) {
            HStack {
                Label(label, systemImage: systemImage)
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(pressedItem == itemId ? Color.accentColor.opacity(0.2) :
                          (hoveredItem == itemId ? Color.accentColor.opacity(0.1) : Color.clear))
                    .animation(.easeInOut(duration: 0.1), value: hoveredItem)
                    .animation(.easeInOut(duration: 0.1), value: pressedItem)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredItem = isHovered ? itemId : nil
            }
        }
    }
}