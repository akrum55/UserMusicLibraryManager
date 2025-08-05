import Foundation
import AppKit

class Song: Identifiable, Equatable, Hashable {
    let id = UUID()
    let url: URL
    var title: String
    var artist: String
    var album: String
    let duration: TimeInterval?
    let artwork: NSImage?
    var year: Int?
    var playCount: Int?
    var lastPlayedDate: Date?
    var rating: Int?
    // Optional track number if available in metadata
    var trackNumber: Int?
    var genre: String?
    var totalTracksInAlbum: Int?
    /// Holds a guessed or inferred total tracks count for fallback or UI
    var totalTracksInAlbumGuess: Int?

    struct UserOverrides: Codable {
        struct Edits: Codable {
            var title: String?
            var artist: String?
            var album: String?
            var trackNumber: Int?
            var genre: String?
            var year: Int?
            var totalTracksInAlbum: Int?
            var isTotalTracksInAlbumGuessed: Bool?
            var playCount: Int?
            var lastPlayedDate: Date?
            var rating: Int?
        }

        var edits: Edits
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
        playCount: Int? = nil,
        lastPlayedDate: Date? = nil,
        rating: Int? = nil,
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
        self.playCount = playCount
        self.lastPlayedDate = lastPlayedDate
        self.rating = rating
        self.totalTracksInAlbum = totalTracksInAlbum
        self.userOverrides = userOverrides
    }

    var effectiveTitle: String {
        userOverrides?.edits.title ?? title
    }

    var effectiveArtist: String {
        userOverrides?.edits.artist ?? artist
    }

    var effectiveAlbum: String {
        userOverrides?.edits.album ?? album
    }

    var effectiveTrackNumber: Int? {
        userOverrides?.edits.trackNumber ?? trackNumber
    }

    var effectiveGenre: String? {
        userOverrides?.edits.genre
    }

    var effectiveYear: Int? {
        userOverrides?.edits.year
    }

    var effectivePlayCount: Int {
        userOverrides?.edits.playCount ?? 0
    }

    var effectiveLastPlayedDate: Date? {
        userOverrides?.edits.lastPlayedDate
    }

    var effectiveTotalTracksInAlbum: Int? {
        userOverrides?.edits.totalTracksInAlbum ?? totalTracksInAlbum
    }

    var isTotalTracksGuessed: Bool {
        userOverrides?.edits.isTotalTracksInAlbumGuessed ?? false
    }

    var isTotalTracksInAlbumGuessed: Bool {
        return (userOverrides?.edits.totalTracksInAlbum == nil) && (totalTracksInAlbumGuess != nil)
    }
    
    var hasUserDefinedTotalTracks: Bool {
        userOverrides?.edits.totalTracksInAlbum != nil && !(userOverrides?.edits.isTotalTracksInAlbumGuessed ?? false)
    }

    var guessedOrActualTotalTracks: Int? {
        if let manual = userOverrides?.edits.totalTracksInAlbum {
            return manual
        }
        return totalTracksInAlbumGuess
    }

    var customTotalTracksInAlbum: Int? {
        userOverrides?.edits.totalTracksInAlbum
    }
    
    var effectiveRating: Int? {
        userOverrides?.edits.rating
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
        if userOverrides == nil {
            userOverrides = UserOverrides(edits: .init())
        }

        if let newTitle = override.edits.title {
            self.userOverrides?.edits.title = newTitle
        }
        if let newArtist = override.edits.artist {
            self.userOverrides?.edits.artist = newArtist
        }
        if let newAlbum = override.edits.album {
            self.userOverrides?.edits.album = newAlbum
        }
        if let newTrack = override.edits.trackNumber {
            self.userOverrides?.edits.trackNumber = newTrack
        }
        if let newGenre = override.edits.genre {
            self.userOverrides?.edits.genre = newGenre
        }
        if let newYear = override.edits.year {
            self.userOverrides?.edits.year = newYear
        }
        if let newPlayCount = override.edits.playCount {
            self.userOverrides?.edits.playCount = newPlayCount
        }
        if let newLastPlayed = override.edits.lastPlayedDate {
            self.userOverrides?.edits.lastPlayedDate = newLastPlayed
        }
        if let newTotal = override.edits.totalTracksInAlbum {
            self.userOverrides?.edits.totalTracksInAlbum = newTotal
        }
        if let guessed = override.edits.isTotalTracksInAlbumGuessed {
            self.userOverrides?.edits.isTotalTracksInAlbumGuessed = guessed
        }
        if let newRating = override.edits.rating {
            self.userOverrides?.edits.rating = newRating
        }
    }
}
