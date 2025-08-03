//
//  SongMetadataEditor.swift
//  UserMusicLibraryManager
//
//  Created by Austin Krum on 8/3/25.
//

import SwiftUI

struct SongMetadataEditor: View {
    @Binding var song: Song

    @State private var editedTitle: String = ""
    @State private var editedArtist: String = ""
    @State private var editedAlbum: String = ""
    @State private var editedTrackNumber: Int?

    var body: some View {
        Form {
            Section(header: Text("Metadata Overrides")) {
                TextField("Title", text: Binding(
                    get: { editedTitle },
                    set: { editedTitle = $0 }
                ))
                TextField("Artist", text: Binding(
                    get: { editedArtist },
                    set: { editedArtist = $0 }
                ))
                TextField("Album", text: Binding(
                    get: { editedAlbum },
                    set: { editedAlbum = $0 }
                ))
                Stepper(value: Binding(
                    get: { editedTrackNumber ?? 1 },
                    set: { editedTrackNumber = $0 }
                ), in: 1...99) {
                    Text("Track Number: \(editedTrackNumber ?? 1)")
                }
            }

            Button("Save Changes") {
                song.userOverrides = Song.UserOverrides(
                    title: editedTitle.isEmpty ? nil : editedTitle,
                    artist: editedArtist.isEmpty ? nil : editedArtist,
                    album: editedAlbum.isEmpty ? nil : editedAlbum,
                    trackNumber: editedTrackNumber
                )
            }
        }
        .onAppear {
            editedTitle = song.userOverrides?.title ?? song.title
            editedArtist = song.userOverrides?.artist ?? song.artist
            editedAlbum = song.userOverrides?.album ?? song.album
            editedTrackNumber = song.userOverrides?.trackNumber ?? song.trackNumber
        }
    }
}
