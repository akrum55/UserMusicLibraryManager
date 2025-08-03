import AppKit

extension NSImage {
    /// Crops the image to a centered square using the shortest side
    func croppedToSquare() -> NSImage {
        let size = min(self.size.width, self.size.height)
        let originX = (self.size.width - size) / 2
        let originY = (self.size.height - size) / 2
        let cropRect = NSRect(x: originX, y: originY, width: size, height: size)

        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return self
        }

        return NSImage(cgImage: croppedCGImage, size: NSSize(width: size, height: size))
    }

    /// Resizes the image to the given size
    func resized(to targetSize: NSSize) -> NSImage {
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .copy, fraction: 1.0)
        resizedImage.unlockFocus()
        return resizedImage
    }

    /// Converts the image to JPEG data with the specified compression quality (0.0–1.0)
    func asJPEGData(compression: CGFloat = 0.85) -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compression])
    }
}

