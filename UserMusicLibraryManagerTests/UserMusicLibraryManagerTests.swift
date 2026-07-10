//
//  UserMusicLibraryManagerTests.swift
//  UserMusicLibraryManagerTests
//
//  Created by Austin Krum on 8/1/25.
//

import Testing
import Foundation
@testable import UserMusicLibraryManager

struct UserMusicLibraryManagerTests {

    /// Builds a Song standing in for a scanned file, with known "file" values.
    private func makeFileSong() -> Song {
        Song(
            url: URL(fileURLWithPath: "/tmp/example.flac"),
            title: "File Title",
            artist: "File Artist",
            album: "File Album",
            duration: 200,
            artwork: nil,
            trackNumber: 3,
            genre: "Rock",
            year: 2020,
            playCount: 5,
            rating: 3
        )
    }

    // With no override attached, every effective* getter reports the scanned
    // file value. This is the fallback the hardening pass made consistent.
    @Test func effectiveValuesFallBackToFileWhenNoOverride() async throws {
        let song = makeFileSong()

        #expect(song.userOverrides == nil)
        #expect(song.effectiveTitle == "File Title")
        #expect(song.effectiveGenre == "Rock")
        #expect(song.effectiveYear == 2020)
        #expect(song.effectiveRating == 3)
        #expect(song.effectivePlayCount == 5)
    }

    // An attached override wins over the file value for the fields it sets.
    @Test func overrideTakesPrecedenceOverFileValue() async throws {
        let song = makeFileSong()
        song.userOverrides = Song.UserOverrides(
            edits: .init(genre: "Jazz", year: 1999, rating: 5)
        )

        #expect(song.effectiveGenre == "Jazz")
        #expect(song.effectiveYear == 1999)
        #expect(song.effectiveRating == 5)
        // A field the override does NOT set still falls back to the file value.
        #expect(song.effectivePlayCount == 5)
    }

    // The core invariant of the fix: attaching an override must NOT mutate the
    // Song's base stored properties. The scanned file values stay pristine so
    // the effective* layer is the single source of truth.
    @Test func attachingOverrideLeavesBaseFileValuesPristine() async throws {
        let song = makeFileSong()
        song.userOverrides = Song.UserOverrides(
            edits: .init(genre: "Jazz", year: 1999)
        )

        #expect(song.genre == "Rock")
        #expect(song.year == 2020)
    }

    // The revert-bug regression test: dropping the override (as Clear Metadata
    // does) makes the effective values fall back to the original file values.
    @Test func clearingOverrideRevertsToFileValues() async throws {
        let song = makeFileSong()
        song.userOverrides = Song.UserOverrides(
            edits: .init(genre: "Jazz", year: 1999, rating: 5)
        )
        #expect(song.effectiveGenre == "Jazz")

        // Simulate Clear Song Metadata: detach the override.
        song.userOverrides = nil

        #expect(song.effectiveGenre == "Rock")
        #expect(song.effectiveYear == 2020)
        #expect(song.effectiveRating == 3)
    }
}
