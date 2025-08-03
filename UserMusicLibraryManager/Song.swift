import Foundation
import AppKit

struct Song: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval?
    let artwork: NSImage?

    // Optional track number if available in metadata
    let trackNumber: Int?
}

extension Song: Equatable {
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.url == rhs.url
    }
}

extension Song: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
