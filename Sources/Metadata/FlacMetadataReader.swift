import Foundation
import AppKit

class FlacMetadataReader {
    static func readMetadata(from url: URL) async throws -> Song {
        guard let file = taglib_file_new(url.path) else {
            throw NSError(domain: "FlacMetadataReader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to open file"])
        }
        defer { taglib_file_free(file) }

        guard let tag = taglib_file_tag(file) else {
            throw NSError(domain: "FlacMetadataReader", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to read tag"])
        }

        let title = taglib_tag_title(tag).flatMap { String(cString: $0) }
        let artist = taglib_tag_artist(tag).flatMap { String(cString: $0) }
        let album = taglib_tag_album(tag).flatMap { String(cString: $0) }
        let trackNumber = Int(taglib_tag_track(tag))

        let audioProperties = taglib_file_audioproperties(file)
        let duration: TimeInterval? = audioProperties.map { TimeInterval(taglib_audioproperties_length($0)) }

        // Extract FLAC front-cover art via Objective-C++ bridge
        var artwork: NSImage? = nil
        if let imageData = FlacTagsWrapper.frontCoverImageData(fromPath: url.path) {
            artwork = NSImage(data: imageData)
        }

        return Song(
            url: url,
            title: title ?? url.deletingPathExtension().lastPathComponent,
            artist: artist ?? "Unknown Artist",
            album: album ?? "Unknown Album",
            duration: duration,
            artwork: artwork,
            trackNumber: trackNumber
        )
    }
}

