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

    struct UserOverrides {
        var title: String?
        var artist: String?
        var album: String?
        var trackNumber: Int?
    }

    var userOverrides: UserOverrides?

    var effectiveTitle: String {
        userOverrides?.title ?? title
    }

    var effectiveArtist: String {
        userOverrides?.artist ?? artist
    }

    var effectiveAlbum: String {
        userOverrides?.album ?? album
    }

    var effectiveTrackNumber: Int? {
        userOverrides?.trackNumber ?? trackNumber
    }
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
