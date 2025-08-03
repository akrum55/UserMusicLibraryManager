import Foundation
import AppKit

@available(macOS 13.0, *)
class CacheManager {
    static let shared = CacheManager()

    private let rootCacheFolder: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("YourApp/ArtCache", isDirectory: true)
    }()

    private let cleanupInterval: TimeInterval = 60 * 60 * 24 * 7 // 1 week
    private let lastCleanupKey = "LastCacheCleanupDate"

    func loadOrCacheArtwork(from imageData: Data, artist: String?, album: String?) -> NSImage? {
        guard imageData.count <= 5_000_000 else {
            print("🚫 Skipping artwork (original data too large: \(imageData.count) bytes)")
            return nil
        }

        let cachePath = pathForArtwork(artist: artist, album: album)

        // Use cached image if available
        if FileManager.default.fileExists(atPath: cachePath.path),
           let image = NSImage(contentsOf: cachePath) {
            return image
        }

        guard let image = NSImage(data: imageData) else {
            print("❌ Failed to create NSImage from artwork data")
            return nil
        }

        let square = image.croppedToSquare()
        let resized = square.resized(to: NSSize(width: 300, height: 300))

        guard let jpeg = resized.asJPEGData(compression: 0.85) else {
            print("❌ Failed to convert artwork to JPEG")
            return nil
        }

        guard jpeg.count <= 1_000_000 else {
            print("🚫 Skipping cached JPEG (too large: \(jpeg.count) bytes)")
            return nil
        }

        do {
            try FileManager.default.createDirectory(at: cachePath.deletingLastPathComponent(), withIntermediateDirectories: true)
            try jpeg.write(to: cachePath)
            return resized
        } catch {
            print("❌ Error saving cached artwork: \(error)")
            return nil
        }
    }

    private func pathForArtwork(artist: String?, album: String?) -> URL {
        let safeArtist = (artist ?? "Unknown Artist").replacingOccurrences(of: "/", with: "-")
        let safeAlbum = (album ?? "Unknown Album").replacingOccurrences(of: "/", with: "-")
        return rootCacheFolder
            .appendingPathComponent(safeArtist, isDirectory: true)
            .appendingPathComponent("\(safeAlbum).jpg")
    }

    func cleanOldArtworkIfNeeded() {
        let defaults = UserDefaults.standard
        if let last = defaults.object(forKey: lastCleanupKey) as? Date,
           Date().timeIntervalSince(last) < cleanupInterval {
            return // Not time yet
        }

        DispatchQueue.global(qos: .background).async {
            self.recursiveClean(folder: self.rootCacheFolder)
        }

        defaults.set(Date(), forKey: lastCleanupKey)
    }

    private func recursiveClean(folder: URL) {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return
        }

        for url in items {
            var isDirectory: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    recursiveClean(folder: url)
                    // Remove empty folders
                    if let sub = try? fm.contentsOfDirectory(atPath: url.path), sub.isEmpty {
                        try? fm.removeItem(at: url)
                    }
                } else {
                    let ageLimit = Date().addingTimeInterval(-cleanupInterval)
                    if let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                       let modified = attrs.contentModificationDate,
                       modified < ageLimit {
                        try? fm.removeItem(at: url)
                        print("🧹 Removed old cache file: \(url.lastPathComponent)")
                    }
                }
            }
        }
    }
}


