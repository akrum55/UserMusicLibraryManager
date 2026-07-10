// ContentView.swift
import SwiftUI
import AppKit
import Dispatch

@available(macOS 13.0, *)
struct ContentView: View {
    @State private var songs: [Song] = []
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
                        // Reverting is now just dropping the override: applyUserOverrides()
                        // clears it and the effective* getters fall back to the file values.
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
                // With the override dictionary emptied, applyUserOverrides() detaches
                // every override so the songs fall back to their scanned file values.
                applyUserOverrides()
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
                    songs = await scanner.scanFolder(folder)
                    userOverridesByURL = UserOverridesStore.load()

                    // Attach any saved overrides to the freshly scanned songs.
                    // We only set `userOverrides`; the scanned file values on each
                    // Song stay untouched so they remain the source of truth.
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
    /// Attaches the saved override (if any) to each song and clears it otherwise.
    /// It deliberately does NOT copy override values into the song's base stored
    /// properties — those hold the scanned file values and stay untouched, so the
    /// `effective*` getters remain the single source of truth and clearing an
    /// override cleanly reveals the original file value again.
    ///
    /// Reassigning the `songs` array (rather than mutating in place) is what tells
    /// SwiftUI to re-render, since `Song` is a reference type and in-place property
    /// changes on a class don't trigger a view update on their own.
    private func applyUserOverrides() {
        songs = songs.map { song in
            song.userOverrides = userOverridesByURL[song.url.standardizedFileURL]
            return song
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
