import AppKit
import SwiftUI
import AVFoundation

struct SongDetailView: View {
    @Binding var song: Song
    var isTotalTracksInAlbumGuessed: Bool
    var onEditMetadataTapped: () -> Void = {}

    private var songOverrides: Song.UserOverrides? {
        song.userOverrides
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                artworkView

                VStack(alignment: .leading, spacing: 4) {
                    metadataView
                }

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

    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Title: \(song.effectiveTitle)")
                .font(.headline)
            Text("Artist: \(song.effectiveArtist)")
            Text("Album: \(song.effectiveAlbum)")
            Text("Track: \(song.effectiveTrackNumber.map(String.init) ?? "")")
            Text("Duration: \(song.duration.map { formattedDuration($0) } ?? "")")
            Text("Year: \(song.year.map(String.init) ?? "")")
            Text("Genre: \(song.genre ?? "")")
            Text("Play Count: \(song.playCount.map(String.init) ?? "")")
            Text("Last Played: \(song.lastPlayedDate?.formatted(date: .abbreviated, time: .omitted) ?? "")")
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

}

#Preview {
    SongDetailView(
        song: .constant(
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
        ),
        isTotalTracksInAlbumGuessed: true
    )
}
