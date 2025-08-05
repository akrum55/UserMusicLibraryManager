import Foundation
import AVFoundation
import AVFoundation.AVMetadataIdentifiers
import AppKit

class AudioMetadataReader {
    static func readMetadata(from url: URL) async throws -> Song {
        if url.pathExtension.lowercased() == "flac" {
            return try await FlacMetadataReader.readMetadata(from: url)
        }

        let asset = AVURLAsset(url: url)
        _ = try await asset.load(.availableMetadataFormats)

        async let title = asset.loadMetadataValue(for: "title")
        async let artist = asset.loadMetadataValue(for: "artist")
        async let album = asset.loadMetadataValue(for: "albumName")
        async let trackNumber = asset.loadMetadataIntValue(for: .iTunesMetadataTrackNumber)
        async let duration = asset.load(.duration).seconds
        async let genre = asset.loadMetadataValue(for: "genre")
        async let totalTracksInAlbum = asset.loadTotalTracksInAlbum()
        let playCount: Int? = nil
        let lastPlayedDate: Date? = nil

        let artwork = try await asset.loadMetadataArtwork()

        return Song(
            url: url,
            title: try await title ?? url.deletingPathExtension().lastPathComponent,
            artist: try await artist ?? "Unknown Artist",
            album: try await album ?? "Unknown Album",
            duration: try? await duration,
            artwork: artwork,
            trackNumber: try await trackNumber,
            genre: try await genre,
            year: nil,
            playCount: playCount,
            lastPlayedDate: lastPlayedDate,
            rating: nil,
            totalTracksInAlbum: try await totalTracksInAlbum
        )
    }
}

extension AVAsset {
    func loadMetadataValue(for commonKey: String) async throws -> String? {
        let items = try await self.load(.commonMetadata)
        if let item = items.first(where: { $0.commonKey?.rawValue == commonKey }) {
            return try await item.load(.stringValue)
        }
        return nil
    }

    func loadMetadataIntValue(for identifier: AVMetadataIdentifier) async throws -> Int? {
        let formats: [AVMetadataFormat] = [.iTunesMetadata, .id3Metadata, .quickTimeMetadata]
        for format in formats {
            let items = try await loadMetadata(for: format)
            if let item = items.first(where: { $0.identifier == identifier }) {
                if let stringValue = try await item.load(.stringValue), let intValue = Int(stringValue) {
                    return intValue
                }
            }
        }
        return nil
    }

    func loadMetadataIntValue(forKey key: String) async throws -> Int? {
        let formats: [AVMetadataFormat] = [.quickTimeMetadata, .iTunesMetadata, .id3Metadata]
        for format in formats {
            let items = try await loadMetadata(for: format)
            if let item = items.first(where: {
                $0.commonKey?.rawValue == key || $0.identifier?.rawValue.lowercased().contains(key.lowercased()) == true
            }) {
                if let stringValue = try await item.load(.stringValue),
                   let intValue = Int(stringValue) {
                    return intValue
                }
            }
        }
        return nil
    }

    func loadTotalTracksInAlbum() async throws -> Int? {
        let quickTimeKeys = ["trackTotal", "track count", "trackcount"]
        // QuickTime/MP4/M4A: try known keys
        for key in quickTimeKeys {
            let value = try await loadMetadataIntValue(forKey: key)
            if let intValue = value, intValue > 0 {
                return intValue
            }
        }

        // ID3: parse "TRCK" frame (format can be "5/12")
        let id3Items = try await loadMetadata(for: .id3Metadata)
        if let trckItem = id3Items.first(where: { $0.identifier?.rawValue.contains("TRCK") == true }) {
            if let stringValue = try await trckItem.load(.stringValue) {
                let components = stringValue.split(separator: "/")
                if components.count == 2, let total = Int(components[1]) {
                    return total
                }
            }
        }

        // Fallback: check iTunes metadata for similar key
        let itunesKeys = ["trackTotal", "track count", "trackcount"]
        for key in itunesKeys {
            let value = try await loadMetadataIntValue(forKey: key)
            if let intValue = value, intValue > 0 {
                return intValue
            }
        }

        return nil
    }

    func loadMetadataDateValue(for identifier: AVMetadataIdentifier) async throws -> Date? {
        let formats: [AVMetadataFormat] = [.iTunesMetadata, .id3Metadata, .quickTimeMetadata]
        for format in formats {
            let items = try await loadMetadata(for: format)
            if let item = items.first(where: { $0.identifier == identifier }) {
                if let stringValue = try await item.load(.stringValue),
                   let timestamp = TimeInterval(stringValue) {
                    return Date(timeIntervalSince1970: timestamp)
                }
            }
        }
        return nil
    }

    func loadMetadataArtwork() async throws -> NSImage? {
        let formats = try await load(.availableMetadataFormats)
        for format in formats {
            let items = try await loadMetadata(for: format)
            if let artworkItem = items.first(where: { $0.commonKey?.rawValue == "artwork" }) {
                if let data = try await artworkItem.load(.dataValue) {
                    return NSImage(data: data)
                }
            }
        }
        return nil
    }
}
