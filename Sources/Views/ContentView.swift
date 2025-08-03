// ContentView.swift
import SwiftUI
import AppKit

@available(macOS 13.0, *)
struct ContentView: View {
    @State private var songs: [Song] = []
    @State private var selectedFolder: URL? = nil
    @State private var selectedSong: Song? = nil
    @State private var artwork: NSImage? = nil

    var body: some View {
        NavigationSplitView {
            VStack {
                FolderPickerView(selectedFolder: $selectedFolder)
                List(selection: $selectedSong) {
                    ForEach(songs, id: \ .url) { song in
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
                                Text(song.title)
                                    .font(.headline)
                                Text("\(song.artist) – \(song.album)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(song.duration) sec")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        } detail: {
            if let song = selectedSong {
                SongDetailView(song: song)
            } else {
                Text("Select a song to view details")
                    .foregroundColor(.secondary)
            }
        }
        .onChange(of: selectedFolder) { newFolder in
            if let folder = newFolder {
                Task {
                    let scanner = MusicLibraryScanner()
                    songs = await scanner.scanFolder(folder)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
