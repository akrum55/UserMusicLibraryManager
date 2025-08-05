// ContentView.swift
import SwiftUI
import AppKit
import Dispatch

@available(macOS 13.0, *)
struct ContentView: View {
    @State private var songs: [Song] = []
    @State private var originalSongs: [Song] = []
    @State private var userOverridesByURL: [URL: Song.UserOverrides] = [:]
    @State private var selectedFolder: URL? = nil
    @State private var selectedSongID: UUID? = nil
    @State private var artwork: NSImage? = nil
    @State private var isEditingMetadata: Bool = false
    @State private var songsVersion = 0
    @State private var showClearTotalTracksOverridesConfirmation = false

    var body: some View {
        NavigationSplitView {
            VStack {
                FolderPickerView(selectedFolder: $selectedFolder)
                SongListView(songs: songs, selectedSongID: $selectedSongID)
                    .id(songsVersion)
            }
        } detail: {
            if let id = selectedSongID,
               let index = songs.firstIndex(where: { $0.id == id }) {
                let song = songs[index]
                ScrollView(.vertical, showsIndicators: true) {
                    let isGuessed = (song.userOverrides?.edits.totalTracksInAlbum == nil) && (song.totalTracksInAlbumGuess != nil)
                    SongDetailView(song: $songs[index], isTotalTracksInAlbumGuessed: isGuessed) {
                        isEditingMetadata = true
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .frame(maxWidth: .infinity)
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
        .toolbar {
            ToolbarItem {
                Button("Clear Song Metadata") {
                    if let id = selectedSongID,
                       let index = songs.firstIndex(where: { $0.id == id }) {
                        let key = songs[index].url.standardizedFileURL
                        userOverridesByURL.removeValue(forKey: key)
                        UserOverridesStore.save(userOverridesByURL)
                        // Revert this song to original scanned state
                        if index < originalSongs.count && originalSongs[index].id == songs[index].id {
                            songs[index] = originalSongs[index]
                        }
                        applyUserOverrides()
                        songsVersion += 1
                        let clearedID = songs[index].id
                        selectedSongID = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            selectedSongID = clearedID
                        }
                    }
                }
                .disabled(selectedSongID == nil)
            }
            ToolbarItem {
                Button("Clear All Overrides") {
                    showClearTotalTracksOverridesConfirmation = true
                }
                .disabled(userOverridesByURL.isEmpty)
            }
        }
        .alert("Are you sure you want to clear all metadata overrides for your library? This cannot be undone.", isPresented: $showClearTotalTracksOverridesConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                userOverridesByURL.removeAll()
                UserOverridesStore.save(userOverridesByURL)
                // Revert all songs to original scanned state
                songs = originalSongs
                songsVersion += 1
                selectedSongID = nil
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .frame(idealWidth: 1000, idealHeight: 700)
        .onChange(of: selectedFolder) { oldFolder, newFolder in
            if let folder = newFolder {
                Task {
                    let scanner = MusicLibraryScanner()
                    let scannedSongs = await scanner.scanFolder(folder)
                    originalSongs = scannedSongs

                    for song in scannedSongs {
                        print("Scanned song URL:", song.url)
                    }

                    let overrides = UserOverridesStore.load()
                    userOverridesByURL = overrides

                    songs = scannedSongs.map { song in
                        let standardizedURL = song.url.standardizedFileURL
                        let modified = song
                        if let override = overrides[standardizedURL] {
                            let modifiedVar = modified
                            modifiedVar.userOverrides = override
                            print("Apply override during map — total tracks override: \(String(describing: override.edits.totalTracksInAlbum))")
                            return modifiedVar
                        }
                        return modified
                    }

                    for song in songs {
                        print("Final song override: \(song.url) track: \(String(describing: song.userOverrides?.edits.trackNumber))")
                    }
                    // Apply existing overrides to all loaded songs
                    applyUserOverrides()
                    songsVersion += 1
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
                let modifiedVar = modified
                modifiedVar.userOverrides = overrides
                // Set all editable fields if the override provides a value
                let edits = overrides.edits
                if let value = edits.title {
                    modifiedVar.title = value
                }
                if let value = edits.artist {
                    modifiedVar.artist = value
                }
                if let value = edits.album {
                    modifiedVar.album = value
                }
                if let value = edits.trackNumber {
                    modifiedVar.trackNumber = value
                }
                if let value = edits.totalTracksInAlbum {
                    modifiedVar.totalTracksInAlbum = value
                }
                if let value = edits.year {
                    modifiedVar.year = value
                }
                if let value = edits.genre {
                    modifiedVar.genre = value
                }
                if let value = edits.playCount {
                    modifiedVar.playCount = value
                }
                if let value = edits.lastPlayedDate {
                    modifiedVar.lastPlayedDate = value
                }
                if let value = edits.rating {
                    modifiedVar.rating = value
                }
                print("Apply override during map — track number override: \(String(describing: overrides.edits.trackNumber))")
                print("Apply override during map — total tracks override: \(String(describing: overrides.edits.totalTracksInAlbum))")
                return modifiedVar
            } else {
                // Also clear userOverrides if not present
                let modified = original
                modified.userOverrides = nil
                return modified
            }
        }
    }
    // Checks if any song in the current list has a user override for totalTracksInAlbum
    private var hasAnyTotalTracksOverrides: Bool {
        // Check in userOverridesByURL
        let hasInOverrides = userOverridesByURL.values.contains { $0.edits.totalTracksInAlbum != nil }
        // Check in the loaded songs array
        let hasInSongs = songs.contains { song in
            song.userOverrides?.edits.totalTracksInAlbum != nil
        }
        return hasInOverrides || hasInSongs
    }
}


@available(macOS 13.0, *)
struct SongListView: View {
    var songs: [Song]
    @Binding var selectedSongID: UUID?

    var body: some View {
        List(selection: $selectedSongID) {
            ForEach(songs, id: \.id) { song in
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
                            let effectiveTotal = song.userOverrides?.edits.totalTracksInAlbum
                                ?? song.totalTracksInAlbumGuess
                                ?? song.totalTracksInAlbum

                            if let totalTracks = effectiveTotal {
                                let isGuessed = (song.userOverrides?.edits.totalTracksInAlbum == nil) && (song.totalTracksInAlbumGuess != nil)
                                let suffix = isGuessed ? "*" : ""
                                Text("Track \(track) of \(totalTracks)\(suffix)")
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
    }
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

@available(macOS 13.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
