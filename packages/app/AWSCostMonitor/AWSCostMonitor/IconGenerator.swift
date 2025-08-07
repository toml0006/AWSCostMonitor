import SwiftUI
import AppKit

// Helper to generate app icon files from CloudIconView
struct IconGenerator {
    static func generateIcons() {
        let sizes = [
            16, 32, 64, 128, 256, 512, 1024
        ]
        
        for size in sizes {
            generateIcon(size: size)
            if size <= 512 {
                generateIcon(size: size * 2, suffix: "@2x")
            }
        }
    }
    
    static func generateIcon(size: Int, suffix: String = "") {
        let actualSize = suffix.isEmpty ? size : size / 2
        let fileName = "icon_\(actualSize)x\(actualSize)\(suffix).png"
        
        // Create the icon view
        let iconView = CloudIconView(size: CGFloat(size))
        
        // Create hosting controller
        let controller = NSHostingController(rootView: iconView)
        let targetSize = NSSize(width: size, height: size)
        controller.view.frame = NSRect(origin: .zero, size: targetSize)
        
        // Render to image
        guard let bitmapRep = controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds) else {
            print("Failed to create bitmap for \(fileName)")
            return
        }
        
        controller.view.cacheDisplay(in: controller.view.bounds, to: bitmapRep)
        
        // Convert to PNG data
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("Failed to create PNG data for \(fileName)")
            return
        }
        
        // Save to file (you would need to adjust the path)
        let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
        let filePath = (desktopPath as NSString).appendingPathComponent(fileName)
        
        do {
            try pngData.write(to: URL(fileURLWithPath: filePath))
            print("Generated \(fileName) at \(filePath)")
        } catch {
            print("Failed to save \(fileName): \(error)")
        }
    }
}

// Call this function to generate all icon files
// IconGenerator.generateIcons()