import Foundation
import AppKit

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

        // Assign totalTracksInAlbum for each song based on album grouping
        let songsByAlbum = Dictionary(grouping: songs, by: { song in
            song.url.deletingLastPathComponent()
        })
        for (_, albumSongs) in songsByAlbum {
            let total = albumSongs.count
            for song in albumSongs {
                song.applyOverride(Song.UserOverrides(totalTracksInAlbum: total))
            }
        }

        return songs
    }
}
