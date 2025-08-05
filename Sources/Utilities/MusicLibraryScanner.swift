import Foundation
import AppKit

private struct HashableAlbumKey: Hashable {
    let album: String
    let artist: String
}

class MusicLibraryScanner {
    func scanFolder(_ folderURL: URL) async -> [Song] {
        let fileManager = FileManager.default

        // Get all file URLs before entering async context (Swift 6 fix)
        let fileURLs = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )?.compactMap { $0 as? URL } ?? []

        let audioExtensions = ["mp3", "m4a", "flac", "aac", "wav", "aiff"]
        var songs: [Song] = []

        for url in fileURLs where audioExtensions.contains(url.pathExtension.lowercased()) {
            if let song = try? await AudioMetadataReader.readMetadata(from: url) {
                print("Scanner loaded song:", song.url, "track:", song.trackNumber as Any, "genre:", song.genre as Any, "year:", song.year as Any)
                songs.append(song)
            }
        }

        applyGuessedTotalTrackCounts(to: &songs)

        return songs
    }

    private func applyGuessedTotalTrackCounts(to songs: inout [Song]) {
        let grouped = Dictionary(grouping: songs) {
            HashableAlbumKey(album: $0.effectiveAlbum, artist: $0.effectiveArtist)
        }

        for (_, albumSongs) in grouped {
            let count = albumSongs.count
            for song in albumSongs {
                if song.customTotalTracksInAlbum == nil {
                    song.totalTracksInAlbumGuess = count
                    print("Guessed total tracks for '\(song.effectiveTitle)': \(count)")
                }
            }
        }
    }
}
