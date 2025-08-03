//
//  FolderAccessManager.swift
//  UserMusicLibraryManager
//
//  Created by Austin Krum on 8/1/25.
//

import Foundation
import AppKit

class FolderAccessManager: ObservableObject {
    @Published var selectedFolder: URL?

    private let bookmarkKey = "losslessFolderBookmark"

    init() {
        selectedFolder = loadBookmark()
    }

    func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Lossless Folder"

        if panel.runModal() == .OK, let url = panel.url {
            selectedFolder = url
            saveBookmark(for: url)
        }
    }

    private func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }

    private func loadBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }

        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                print("Bookmark is stale.")
                return nil
            }

            if url.startAccessingSecurityScopedResource() {
                return url
            } else {
                print("Could not access folder.")
                return nil
            }
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }
}

