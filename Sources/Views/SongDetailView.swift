import AppKit
import SwiftUI
import AVFoundation

struct SongDetailView: View {
    @Binding var song: Song
    var onEditMetadataTapped: () -> Void = {}

    var body: some View {
        let title = song.effectiveTitle
        let artist = song.effectiveArtist
        let album = song.effectiveAlbum
        let genre = song.genre
        let year = song.year
        let duration = song.duration
        let trackNumber = song.effectiveTrackNumber
        let totalTracks = song.userOverrides?.totalTracksInAlbum ?? song.totalTracksInAlbum

        VStack(alignment: .leading, spacing: 8) {
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

            Group {
                Text("Title: \(title)").font(.headline)
                Text("Artist: \(artist)")
                Text("Album: \(album)")
                if let genre {
                    Text("Genre: \(genre)")
                }
                if let year {
                    Text("Year: \(year)")
                }
                if let trackNumber {
                    if let totalTracks {
                        Text("Track: \(trackNumber) of \(totalTracks)")
                    } else {
                        Text("Track: \(trackNumber)")
                    }
                }
                if let duration {
                    Text("Duration: \(formattedDuration(duration))")
                }
            }
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
