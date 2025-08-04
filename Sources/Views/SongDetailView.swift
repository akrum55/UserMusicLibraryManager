import AppKit
import SwiftUI
import AVFoundation

struct SongDetailView: View {
    @Binding var song: Song
    var onEditMetadataTapped: () -> Void = {}

    private var songOverrides: Song.UserOverrides? {
        song.userOverrides
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            artworkView

            metadataView
                .padding(.bottom)

            Text("Path: \(song.url.path)")
                .font(.caption)
                .foregroundColor(.gray)

            Button("Edit Metadata") {
                onEditMetadataTapped()
            }
            .padding(.top)

            Spacer()
        }
        .padding()
    }

    private var artworkView: some View {
        Group {
            if let artwork = song.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 200)
            }
        }
    }

    @ViewBuilder
    private var trackView: some View {
        if let trackNumber = song.effectiveTrackNumber {
            if let totalTracks = song.totalTracksInAlbum {
                Text("Track \(trackNumber) of \(totalTracks)")
            } else if let guessedTracks = song.totalTracksInAlbumGuess {
                Text("Track \(trackNumber) of \(guessedTracks)*")
            } else {
                Text("Track \(trackNumber)")
            }
        }
    }

    private var metadataView: some View {
        Group {
            Text("Title: \(song.effectiveTitle)").font(.headline)
            Text("Artist: \(song.effectiveArtist)")
            Text("Album: \(song.effectiveAlbum)")
            if let genre = song.genre {
                Text("Genre: \(genre)")
            }
            if let year = song.year {
                Text("Year: \(year.description)")
            }
            trackView
            if let duration = song.duration {
                Text("Duration: \(formattedDuration(duration))")
            }
            if song.totalTracksInAlbum == nil, song.totalTracksInAlbumGuess != nil {
                Text("* Estimated from imported files")
                    .font(.caption)
                    .foregroundColor(.gray)
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
    SongDetailView(song: .constant(
        Song(
            url: URL(fileURLWithPath: "/tmp/example.flac"),
            title: "Example Title",
            artist: "Example Artist",
            album: "Example Album",
            duration: 215,
            artwork: nil,
            trackNumber: 1,
            genre: "Indie Rock",
            year: 2023,
            totalTracksInAlbum: 10
        )
    ))
}
