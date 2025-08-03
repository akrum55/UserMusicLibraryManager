import Foundation
import AppKit

class Song: Identifiable, Equatable, Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval?
    let artwork: NSImage?

    // Optional track number if available in metadata
    let trackNumber: Int?

    struct UserOverrides: Codable {
        var title: String?
        var artist: String?
        var album: String?
        var trackNumber: Int?
    }

    var userOverrides: UserOverrides?

    init(
        url: URL,
        title: String,
        artist: String,
        album: String,
        duration: TimeInterval?,
        artwork: NSImage?,
        trackNumber: Int?,
        userOverrides: UserOverrides? = nil
    ) {
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artwork = artwork
        self.trackNumber = trackNumber
        self.userOverrides = userOverrides
    }

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

    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
