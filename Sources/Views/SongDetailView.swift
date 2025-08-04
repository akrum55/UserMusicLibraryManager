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

    private var trackView: some View {
        Group {
            if let trackNumber = song.effectiveTrackNumber {
                if let totalTracks = song.effectiveTotalTracksInAlbum {
                    let isGuessed = song.isTotalTracksInAlbumGuessed
                    Text("Track \(trackNumber) of \(totalTracks)\(isGuessed ? "*" : "")")
                } else {
                    Text("Track \(trackNumber)")
                }
            }
        }
    }

    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 4) {
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
            if song.isTotalTracksInAlbumGuessed {
                Text("* Total tracks estimated from imported files")
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

extension Song {
    var isTotalTracksInAlbumGuessed: Bool {
        userOverrides?.edits.isTotalTracksInAlbumGuessed == true
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
