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
    @State private var editedGenre: String = ""
    @State private var editedYearString: String = ""
    @State private var editedTotalTracksString: String = ""

    private var isTrackNumberValid: Bool {
        Int(editedTrackNumberString) != nil
    }
    private var isYearValid: Bool {
        editedYearString.isEmpty || Int(editedYearString) != nil
    }
    private var isTotalTracksValid: Bool {
        editedTotalTracksString.isEmpty || Int(editedTotalTracksString) != nil
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
                TextField("Genre", text: $editedGenre)
                TextField("Year", text: $editedYearString)
                if !editedYearString.isEmpty && Int(editedYearString) == nil {
                    Text("Please enter a valid year")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                TextField("Total Tracks in Album", text: $editedTotalTracksString)
                    .overlay(
                        Group {
                            if editedTotalTracksString.isEmpty,
                               songs[index].userOverrides?.edits.totalTracksInAlbum == nil,
                               let guess = songs[index].totalTracksInAlbumGuess {
                                Text("\(guess)*")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    )
                    .onTapGesture {
                        if songs[index].userOverrides?.edits.totalTracksInAlbum == nil,
                           let guess = songs[index].totalTracksInAlbumGuess {
                            if editedTotalTracksString == "\(guess)" {
                                editedTotalTracksString = ""
                            }
                        }
                    }
                if !editedTotalTracksString.isEmpty && Int(editedTotalTracksString) == nil {
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
                    let parsedTrack = Int(editedTrackNumberString)
                    let parsedYear = Int(editedYearString)
                    let parsedTotalTracks = Int(editedTotalTracksString)

                    let override = Song.UserOverrides(
                        edits: .init(
                            title: editedTitle.isEmpty ? nil : editedTitle,
                            artist: editedArtist.isEmpty ? nil : editedArtist,
                            album: editedAlbum.isEmpty ? nil : editedAlbum,
                            trackNumber: parsedTrack,
                            genre: editedGenre.isEmpty ? nil : editedGenre,
                            year: parsedYear,
                            totalTracksInAlbum: parsedTotalTracks
                        )
                    )
                    onSave?(override)

                    songs[index].userOverrides = override
                    let standardizedURL = songs[index].url.standardizedFileURL
                    userOverridesByURL[standardizedURL] = override
                    // Clear the guess if user confirms their own value
                    songs[index].totalTracksInAlbumGuess = nil

                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(
                    (!editedTrackNumberString.isEmpty && !isTrackNumberValid) ||
                    (!editedYearString.isEmpty && !isYearValid) ||
                    (!editedTotalTracksString.isEmpty && !isTotalTracksValid)
                )
            }
            .padding(.top)
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
        .onAppear {
            editedTitle = songs[index].userOverrides?.edits.title ?? songs[index].title
            editedArtist = songs[index].userOverrides?.edits.artist ?? songs[index].artist
            editedAlbum = songs[index].userOverrides?.edits.album ?? songs[index].album
            editedTrackNumberString = songs[index].userOverrides?.edits.trackNumber.map { String($0) } ?? songs[index].trackNumber.map { String($0) } ?? ""
            editedGenre = songs[index].userOverrides?.edits.genre ?? songs[index].genre ?? ""
            editedYearString = songs[index].userOverrides?.edits.year.map { String($0) } ?? ""
            editedTotalTracksString = songs[index].userOverrides?.edits.totalTracksInAlbum.map { String($0) } ?? ""
        }
    }
}

#Preview {
    SongMetadataEditor(
        songs: .constant([
            Song(
                url: URL(fileURLWithPath: "/tmp/example.flac"),
                title: "Example Song",
                artist: "Example Artist",
                album: "Example Album",
                duration: 200,
                artwork: nil,
                trackNumber: 1,
                genre: "Rock",
                year: 2022
            )
        ]),
        userOverridesByURL: .constant([:]),
        index: 0
    )
}
