// ContentView.swift
import SwiftUI
import AppKit

@available(macOS 13.0, *)
struct ContentView: View {
    @State private var songs: [Song] = []
    @State private var userOverridesByURL: [URL: Song.UserOverrides] = [:]
    @State private var selectedFolder: URL? = nil
    @State private var selectedSongID: UUID? = nil
    @State private var artwork: NSImage? = nil
    @State private var isEditingMetadata: Bool = false
    @State private var songsVersion = 0

    var body: some View {
        NavigationSplitView {
            VStack {
                FolderPickerView(selectedFolder: $selectedFolder)
                List(selection: $selectedSongID) {
                    ForEach(songs) { song in
                        HStack {
                            if let image = song.artwork {
                                Image(nsImage: image)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(5)
                            } else {
                                Color.gray.frame(width: 40, height: 40)
                                    .cornerRadius(5)
                            }
                            VStack(alignment: .leading) {
                                Text(song.effectiveTitle)
                                    .font(.headline)
                                Text("\(song.effectiveArtist) – \(song.effectiveAlbum)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let track = song.effectiveTrackNumber {
                                    let totalTracks = song.userOverrides?.totalTracksInAlbum ?? song.totalTracksInAlbum
                                    if let totalTracks {
                                        Text("Track \(track) of \(totalTracks)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Track \(track)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            Spacer()
                            if let duration = song.duration {
                                Text(formattedDuration(duration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .id(songsVersion)
            }
        } detail: {
            if let id = selectedSongID,
               let index = songs.firstIndex(where: { $0.id == id }) {
                SongDetailView(song: $songs[index]) {
                    isEditingMetadata = true
                }
                .id(songsVersion)
            } else {
                Text("Select a song to view details")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $isEditingMetadata) {
            if let id = selectedSongID,
               let index = songs.firstIndex(where: { $0.id == id }) {
                SongMetadataEditor(songs: $songs, userOverridesByURL: $userOverridesByURL, index: index) { override in
                    let standardizedURL = songs[index].url.standardizedFileURL
                    print("Received override from editor for:", standardizedURL)
                    userOverridesByURL[standardizedURL] = override
                    UserOverridesStore.save(userOverridesByURL)
                    applyUserOverrides()
                    songsVersion += 1
                    selectedSongID = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        selectedSongID = songs[index].id
                    }
                }
            }
        }
        .onChange(of: selectedFolder) { oldFolder, newFolder in
            if let folder = newFolder {
                Task {
                    let scanner = MusicLibraryScanner()
                    let scannedSongs = await scanner.scanFolder(folder)

                    for song in scannedSongs {
                        print("Scanned song URL:", song.url)
                    }

                    let overrides = UserOverridesStore.load()
                    userOverridesByURL = overrides

                    songs = scannedSongs.map { song in
                        let modified = song
                        let standardizedURL = song.url.standardizedFileURL
                        if let override = overrides[standardizedURL] {
                            modified.userOverrides = override
                            print("Apply override during map — track number override: \(String(describing: override.trackNumber))")
                        }
                        return modified
                    }

                    for song in songs {
                        print("Final song override: \(song.url) track: \(String(describing: song.userOverrides?.trackNumber))")
                    }
                }
            }
        }
    }
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    private func applyUserOverrides() {
        songs = songs.map { original in
            let standardizedURL = original.url.standardizedFileURL
            if let overrides = userOverridesByURL[standardizedURL] {
                let modified = original
                modified.userOverrides = overrides
                print("Apply override during map — track number override: \(String(describing: overrides.trackNumber))")
                print("Reapplying override for: \(standardizedURL) track: \(String(describing: overrides.trackNumber))")
                return modified
            } else {
                return original
            }
        }
    }
}

@available(macOS 13.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
