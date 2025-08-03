//
//  SongMetadataEditor.swift
//  UserMusicLibraryManager
//
//  Created by Austin Krum on 8/3/25.
//

import SwiftUI

struct SongMetadataEditor: View {
    @Binding var songs: [Song]
    @Binding var userOverridesByURL: [URL: Song.UserOverrides]
    let index: Int
    @Environment(\.dismiss) private var dismiss
    var onSave: ((Song.UserOverrides) -> Void)? = nil

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
                Text("Editing: \(editedTitle.isEmpty ? songs[index].title : editedTitle)")
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
                    print("Saving override: track number string = \(editedTrackNumberString)")
                    let parsedTrack = Int(editedTrackNumberString)
                    print("Parsed track number = \(String(describing: parsedTrack))")

                    let override = Song.UserOverrides(
                        title: editedTitle.isEmpty ? nil : editedTitle,
                        artist: editedArtist.isEmpty ? nil : editedArtist,
                        album: editedAlbum.isEmpty ? nil : editedAlbum,
                        trackNumber: parsedTrack
                    )
                    onSave?(override)

                    songs[index].userOverrides = override
                    let standardizedURL = songs[index].url.standardizedFileURL
                    userOverridesByURL[standardizedURL] = override

                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!editedTrackNumberString.isEmpty && !isTrackNumberValid)
            }
            .padding(.top)
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
        .onAppear {
            editedTitle = songs[index].userOverrides?.title ?? songs[index].title
            editedArtist = songs[index].userOverrides?.artist ?? songs[index].artist
            editedAlbum = songs[index].userOverrides?.album ?? songs[index].album
            editedTrackNumberString = songs[index].userOverrides?.trackNumber.map { String($0) } ?? songs[index].trackNumber.map { String($0) } ?? ""
        }
    }
}
