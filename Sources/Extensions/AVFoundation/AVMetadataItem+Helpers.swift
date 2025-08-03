import AVFoundation

@available(macOS 13.0, *)
extension Array where Element == AVMetadataItem {
    func firstStringValue(for identifier: AVMetadataIdentifier) async throws -> String? {
        guard let item = AVMetadataItem.metadataItems(from: self, filteredByIdentifier: identifier).first else {
            return nil
        }
        return try await item.load(.stringValue)
    }

    func firstIntValue(for identifier: AVMetadataIdentifier) async throws -> Int? {
        guard let item = AVMetadataItem.metadataItems(from: self, filteredByIdentifier: identifier).first else {
            return nil
        }
        return try await item.load(.numberValue)?.intValue
    }
}
