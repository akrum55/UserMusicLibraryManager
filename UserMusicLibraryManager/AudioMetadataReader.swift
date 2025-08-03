import Foundation
import AVFoundation
import AppKit

class AudioMetadataReader {
    static func readMetadata(from url: URL) async throws -> Song {
        if url.pathExtension.lowercased() == "flac" {
            return try await FlacMetadataReader.readMetadata(from: url)
        }

        let asset = AVURLAsset(url: url)
        _ = try await asset.load(.availableMetadataFormats)

        async let title = asset.loadMetadataValue(for: .commonIdentifierTitle)
        async let artist = asset.loadMetadataValue(for: .commonIdentifierArtist)
        async let album = asset.loadMetadataValue(for: .commonIdentifierAlbumName)
        async let trackNumber = asset.loadMetadataIntValue(for: .iTunesMetadataTrackNumber)
        async let duration = asset.load(.duration).seconds

        let artwork = try await asset.loadMetadataArtwork()

        return Song(
            url: url,
            title: try await title ?? url.deletingPathExtension().lastPathComponent,
            artist: try await artist ?? "Unknown Artist",
            album: try await album ?? "Unknown Album",
            duration: try? await duration,
            artwork: artwork,
            trackNumber: try await trackNumber
        )
    }
}

extension AVAsset {
    func loadMetadataValue(for identifier: AVMetadataIdentifier) async throws -> String? {
        let items = try await self.load(.commonMetadata)
        if let item = items.first(where: { $0.identifier == identifier }) {
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
