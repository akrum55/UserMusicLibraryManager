import AppKit
import SwiftUI
import AVFoundation

struct SongDetailView: View {
    @Binding var song: Song
    var onEditMetadataTapped: () -> Void = {}

    var body: some View {
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

            Text("Title: \(song.effectiveTitle)")
                .font(.headline)
            Text("Artist: \(song.effectiveArtist)")
            Text("Album: \(song.effectiveAlbum)")
            if let track = song.effectiveTrackNumber {
                Text("Track: \(track)")
            }
            if let duration = song.duration {
                Text("Duration: \(formattedDuration(duration))")
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

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
