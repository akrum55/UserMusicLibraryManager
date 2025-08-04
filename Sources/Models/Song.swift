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
    let year: Int?

    // Optional track number if available in metadata
    let trackNumber: Int?
    let genre: String?
    let totalTracksInAlbum: Int?

    struct UserOverrides: Codable {
        var title: String?
        var artist: String?
        var album: String?
        var trackNumber: Int?
        var genre: String?
        var year: Int?
        var totalTracksInAlbum: Int?
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
        genre: String?,
        year: Int?,
        totalTracksInAlbum: Int? = nil,
        userOverrides: UserOverrides? = nil
    ) {
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artwork = artwork
        self.trackNumber = trackNumber
        self.genre = genre
        self.year = year
        self.totalTracksInAlbum = totalTracksInAlbum
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

    var effectiveGenre: String? {
        userOverrides?.genre
    }

    var effectiveYear: Int? {
        userOverrides?.year
    }

    var effectiveTotalTracksInAlbum: Int? {
        userOverrides?.totalTracksInAlbum
    }

    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

extension Song {
    func applyOverride(_ override: Song.UserOverrides) {
        if let newTitle = override.title {
            self.userOverrides?.title = newTitle
        }
        if let newArtist = override.artist {
            self.userOverrides?.artist = newArtist
        }
        if let newAlbum = override.album {
            self.userOverrides?.album = newAlbum
        }
        if let newTrack = override.trackNumber {
            self.userOverrides?.trackNumber = newTrack
        }
        if let newGenre = override.genre {
            self.userOverrides?.genre = newGenre
        }
        if let newYear = override.year {
            self.userOverrides?.year = newYear
        }
        if let newTotal = override.totalTracksInAlbum {
            self.userOverrides?.totalTracksInAlbum = newTotal
        }
    }
}
