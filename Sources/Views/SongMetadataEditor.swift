//
//  SongMetadataEditor.swift
//  UserMusicLibraryManager
//
//  Created by Austin Krum on 8/3/25.
//

import SwiftUI

struct SongMetadataEditor: View {
    @Binding var song: Song
    @Environment(\.dismiss) private var dismiss

    @State private var editedTitle: String = ""
    @State private var editedArtist: String = ""
    @State private var editedAlbum: String = ""
    @State private var editedTrackNumberString: String = ""

    private var isTrackNumberValid: Bool {
        Int(editedTrackNumberString) != nil
    }

    var body: some View {
        Form {
            Section {
                Text("Editing: \(editedTitle.isEmpty ? song.title : editedTitle)")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 5)
            }
            Section(header: Text("Metadata Overrides")) {
                TextField("Title", text: $editedTitle)
                TextField("Artist", text: $editedArtist)
                TextField("Album", text: $editedAlbum)
                TextField("Track Number", text: $editedTrackNumberString)
                if !editedTrackNumberString.isEmpty && Int(editedTrackNumberString) == nil {
                    Text("Please enter a valid number")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("OK") {
                    let trackNumber = Int(editedTrackNumberString)
                    song.userOverrides = Song.UserOverrides(
                        title: editedTitle.isEmpty ? nil : editedTitle,
                        artist: editedArtist.isEmpty ? nil : editedArtist,
                        album: editedAlbum.isEmpty ? nil : editedAlbum,
                        trackNumber: trackNumber
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isTrackNumberValid)
            }
            .padding(.top)
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
        .onAppear {
            editedTitle = song.userOverrides?.title ?? song.title
            editedArtist = song.userOverrides?.artist ?? song.artist
            editedAlbum = song.userOverrides?.album ?? song.album
            editedTrackNumberString = song.userOverrides?.trackNumber.map { String($0) } ?? song.trackNumber.map { String($0) } ?? ""
        }
    }
}
