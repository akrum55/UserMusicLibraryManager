//
//  UserOverridesStore.swift
//  UserMusicLibraryManager
//
//  Created by Austin Krum on 8/3/25.
//

import Foundation

struct UserOverridesStore {
    static var overridesURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = appSupport.appendingPathComponent("UserMusicLibraryManager", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("overrides.json")
    }

    static func save(_ overrides: [URL: Song.UserOverrides]) {
        let encodableOverrides = overrides.mapKeys { $0.standardizedFileURL.absoluteString }
        do {
            let data = try JSONEncoder().encode(encodableOverrides)
            try data.write(to: overridesURL)
            print("✅ Saved overrides to disk at \(overridesURL.path)")
        } catch {
            print("❌ Failed to save overrides: \(error)")
        }
    }

    static func load() -> [URL: Song.UserOverrides] {
        do {
            let data = try Data(contentsOf: overridesURL)
            let raw = try JSONDecoder().decode([String: Song.UserOverrides].self, from: data)
            return raw.compactMapKeys { URL(string: $0)?.standardizedFileURL }
        } catch {
            print("⚠️ No existing overrides or failed to load: \(error)")
            return [:]
        }
    }
    static func clearTotalTracksInAlbumOverrides() {
        var current = load()
        for (url, var override) in current {
            if override.totalTracksInAlbum != nil {
                override.totalTracksInAlbum = nil
                current[url] = override
            }
        }
        save(current)
        print("🧹 Cleared totalTracksInAlbum overrides from disk.")
    }
}

// MARK: - Dictionary Key Helpers

extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: self.map { (transform($0.key), $0.value) })
    }

    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = value
            }
        }
        return result
    }
}
