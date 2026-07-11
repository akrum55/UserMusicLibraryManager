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

    // MARK: - Override persistence

    // The saved JSON round-trips through disk: encoding to a file and decoding
    // back yields the same edits, keyed by the standardized file URL. Uses a
    // throwaway temp file, so it never touches the real overrides.json.
    @Test func overridesStoreRoundTripsThroughDisk() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("umlm-store-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("overrides.json")

        let key = URL(fileURLWithPath: "/Volumes/Extreme SSD/ipod music/austin/example.flac")
        let overrides: [URL: Song.UserOverrides] = [
            key: Song.UserOverrides(
                edits: .init(title: "New Title", genre: "Jazz", year: 1999,
                             totalTracksInAlbum: 12, rating: 5)
            )
        ]

        UserOverridesStore.save(overrides, to: file)
        #expect(FileManager.default.fileExists(atPath: file.path))

        let loaded = UserOverridesStore.load(from: file)
        #expect(loaded.count == 1)

        let edits = loaded[key.standardizedFileURL]?.edits
        #expect(edits?.title == "New Title")
        #expect(edits?.genre == "Jazz")
        #expect(edits?.year == 1999)
        #expect(edits?.totalTracksInAlbum == 12)
        #expect(edits?.rating == 5)
    }

    // Loading from a path that doesn't exist yields an empty map rather than
    // throwing — the first-launch case.
    @Test func loadingMissingOverridesFileReturnsEmpty() async throws {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("umlm-does-not-exist-\(UUID().uuidString).json")
        let loaded = UserOverridesStore.load(from: missing)
        #expect(loaded.isEmpty)
    }

    // MARK: - Integration: real FLAC scan

    // End-to-end scan of a real album folder, exercising MusicLibraryScanner,
    // the TagLib-backed FlacMetadataReader (Obj-C++ bridge), and the scanner's
    // total-tracks guessing. Self-skips unless a fixture folder is present, so
    // it stays green on machines/CI without the music files. Provide one via the
    // MUSIC_SCAN_FIXTURE env var or a ~/.umlm_scan_fixture folder of audio files.
    @Test(.enabled(if: scanFixtureURL() != nil))
    func scanRealFlacAlbumFolder() async throws {
        let folder = try #require(scanFixtureURL())
        let songs = await MusicLibraryScanner().scanFolder(folder)

        // All four tracks were read from disk.
        #expect(songs.count == 4)

        // Titles match the album's real tags.
        let titles = Set(songs.map { $0.effectiveTitle })
        #expect(titles == ["Paycheck", "Games", "Star Girl", "Chrono Trigger"])

        // Shared album/artist/genre/year read correctly for every track.
        for song in songs {
            #expect(song.effectiveArtist == "Tommy Richman")
            #expect(song.effectiveAlbum == "Paycheck")
            #expect(song.effectiveGenre == "Pop")
            #expect(song.effectiveYear == 2022)
            #expect((song.duration ?? 0) > 0)
            // The scanner guesses total tracks from the count of same-album songs.
            #expect(song.totalTracksInAlbumGuess == 4)
        }

        // Track numbers 1...4 are all present.
        let tracks = songs.compactMap { $0.effectiveTrackNumber }.sorted()
        #expect(tracks == [1, 2, 3, 4])
    }
}

/// Resolves the integration-test music fixture, or nil if none is available.
/// Checks the MUSIC_SCAN_FIXTURE env var first, then ~/.umlm_scan_fixture.
private func scanFixtureURL() -> URL? {
    let fm = FileManager.default
    let candidates: [URL] = {
        if let env = ProcessInfo.processInfo.environment["MUSIC_SCAN_FIXTURE"], !env.isEmpty {
            return [URL(fileURLWithPath: env)]
        }
        return [fm.homeDirectoryForCurrentUser.appendingPathComponent(".umlm_scan_fixture")]
    }()

    for url in candidates {
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return url
        }
    }
    return nil
}
