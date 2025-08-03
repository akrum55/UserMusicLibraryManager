// ContentView.swift
import SwiftUI
import AppKit

@available(macOS 13.0, *)
struct ContentView: View {
    @State private var songs: [Song] = []
    @State private var selectedFolder: URL? = nil
    @State private var selectedSong: Song? = nil
    @State private var artwork: NSImage? = nil
    @State private var isEditingMetadata: Bool = false

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
                            if let duration = song.duration {
                                Text(formattedDuration(duration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        } detail: {
            if let song = selectedSong {
                VStack {
                    SongDetailView(song: song)
                    Button("Edit Metadata") {
                        isEditingMetadata = true
                    }
                    .padding(.top)
                }
            } else {
                Text("Select a song to view details")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $isEditingMetadata) {
            if let binding = Binding($selectedSong) {
                SongMetadataEditor(song: binding)
            }
        }
        .onChange(of: selectedFolder) { oldFolder, newFolder in
            if let folder = newFolder {
                Task {
                    let scanner = MusicLibraryScanner()
                    songs = await scanner.scanFolder(folder)
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

#Preview {
    ContentView()
}
