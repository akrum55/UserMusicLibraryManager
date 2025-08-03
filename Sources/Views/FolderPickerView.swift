// FolderPickerView.swift
import SwiftUI

struct FolderPickerView: View {
    @Binding var selectedFolder: URL?

    var body: some View {
        VStack(spacing: 20) {
            if let folder = selectedFolder {
                Text("Selected Folder: \(folder.path)")
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else {
                Text("No Folder Selected")
                    .foregroundColor(.secondary)
            }

            Button("Choose Folder") {
                selectFolder()
            }
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            selectedFolder = panel.url
        }
    }
}
