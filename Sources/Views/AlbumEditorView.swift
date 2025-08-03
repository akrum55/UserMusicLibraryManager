// AlbumEditorView.swift
// (New view to support album-level metadata editing; initial scaffold below)

import SwiftUI

struct AlbumEditorView: View {
    @Binding var albumTitle: String
    @Binding var artistName: String
    var onApplyToAll: (() -> Void)?

    @State private var showConfirmation = false

    var body: some View {
        Form {
            Section(header: Text("Album Metadata")) {
                TextField("Album Title", text: $albumTitle)
                TextField("Artist", text: $artistName)
            }

            if let onApplyToAll = onApplyToAll {
                Section {
                    Button("Apply to All Songs in Album") {
                        onApplyToAll()
                        showConfirmation = true
                    }
                    .alert("Metadata Applied", isPresented: $showConfirmation) {
                        Button("OK", role: .cancel) { }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 200)
    }
}

#Preview {
    struct MockAlbumEditorWrapper: View {
        @State private var title = "Mock Album"
        @State private var artist = "Mock Artist"

        var body: some View {
            AlbumEditorView(
                albumTitle: $title,
                artistName: $artist,
                onApplyToAll: {
                    print("Applied mock metadata to all songs")
                }
            )
        }
    }

    return MockAlbumEditorWrapper()
}
