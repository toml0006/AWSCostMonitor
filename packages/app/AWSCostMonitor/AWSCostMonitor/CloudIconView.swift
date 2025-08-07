import SwiftUI

struct CloudIconView: View {
    let size: CGFloat
    
    init(size: CGFloat = 100) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.4, blue: 0.2),  // Orange
                            Color(red: 1.0, green: 0.3, blue: 0.35)  // Pink-red
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // Cloud shape with overlapping circles
            ZStack {
                // Blue cloud part (left)
                Circle()
                    .fill(Color(red: 0.2, green: 0.6, blue: 0.9))
                    .frame(width: size * 0.35, height: size * 0.35)
                    .offset(x: -size * 0.12, y: -size * 0.05)
                
                // Orange/yellow cloud part (middle-top)
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.7, blue: 0.2),
                                Color(red: 1.0, green: 0.5, blue: 0.2)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.38, height: size * 0.38)
                    .offset(x: size * 0.05, y: -size * 0.08)
                
                // Orange cloud part (right)
                Circle()
                    .fill(Color(red: 1.0, green: 0.4, blue: 0.3))
                    .frame(width: size * 0.32, height: size * 0.32)
                    .offset(x: size * 0.18, y: size * 0.02)
                
                // Pink cloud part (bottom)
                Circle()
                    .fill(Color(red: 0.9, green: 0.2, blue: 0.4))
                    .frame(width: size * 0.35, height: size * 0.35)
                    .offset(x: 0, y: size * 0.12)
                
                // Base cloud shape (connecting element)
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.6, blue: 0.2),
                                Color(red: 1.0, green: 0.4, blue: 0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 0.5, height: size * 0.25)
                    .offset(y: size * 0.05)
            }
            .shadow(color: Color.black.opacity(0.2), radius: size * 0.05, x: 0, y: size * 0.03)
        }
    }
}

// Menu bar icon view (creates NSImage for status bar)
struct MenuBarCloudIcon {
    static func createImage(size: CGFloat = 18) -> NSImage? {
        let view = CloudIconView(size: size * 2) // Create at 2x for retina
        
        let controller = NSHostingController(rootView: view)
        let targetSize = NSSize(width: size * 2, height: size * 2)
        controller.view.frame = NSRect(origin: .zero, size: targetSize)
        
        let bitmapRep = controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds)
        guard let bitmap = bitmapRep else { return nil }
        
        controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
        
        let image = NSImage(size: NSSize(width: size, height: size))
        image.addRepresentation(bitmap)
        image.isTemplate = false // Keep colors
        
        return image
    }
    
    static func createTemplateImage(size: CGFloat = 18) -> NSImage? {
        // Simple cloud shape for template (monochrome)
        let image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "AWS Cost Monitor")
        image?.isTemplate = true
        return image
    }
}

// Preview
struct CloudIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CloudIconView(size: 256)
            CloudIconView(size: 128)
            CloudIconView(size: 64)
            CloudIconView(size: 32)
            // Menu bar icon preview
            if let menuBarIcon = MenuBarCloudIcon.createImage(size: 22) {
                Image(nsImage: menuBarIcon)
                    .frame(width: 22, height: 22)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}