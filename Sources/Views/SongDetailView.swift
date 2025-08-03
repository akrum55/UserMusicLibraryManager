import SwiftUI
import AppKit

struct SongDetailView: View {
    let song: Song

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

            Text("Title: \(song.title)")
                .font(.headline)
            Text("Artist: \(song.artist)")
            Text("Album: \(song.album)")
            if let track = song.trackNumber {
                Text("Track: \(track)")
            }
            if let duration = song.duration {
                Text("Duration: \(formattedDuration(duration))")
            }
            Text("Path: \(song.url.path)")
                .font(.caption)
                .foregroundColor(.gray)

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
