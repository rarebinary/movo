@preconcurrency import AVFoundation
import Foundation

public enum VideoImportExecutionError: Error, LocalizedError, Sendable {
    case couldNotCreateExportSession
    case unsupportedExportType

    public var errorDescription: String? {
        switch self {
        case .couldNotCreateExportSession:
            "Movo could not prepare this video for efficient playback."
        case .unsupportedExportType:
            "This video cannot be converted to a managed MOV file."
        }
    }
}

public struct VideoImportExecutor: Sendable {
    private let inspector: VideoInspector

    public init(inspector: VideoInspector = .init()) {
        self.inspector = inspector
    }

    public func execute(_ prepared: PreparedVideoImport) async throws -> WallpaperItem {
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: prepared.destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if fileManager.fileExists(atPath: prepared.destinationURL.path) {
            try fileManager.removeItem(at: prepared.destinationURL)
        }

        do {
            switch prepared.plan {
            case .directCopy:
                try fileManager.copyItem(at: prepared.sourceURL, to: prepared.destinationURL)
            case .optimize:
                try await optimize(prepared)
            }

            let managedMetadata = try await inspector.inspect(url: prepared.destinationURL)
            return WallpaperItem(
                id: prepared.id,
                title: prepared.title,
                managedFilename: prepared.destinationURL.lastPathComponent,
                media: managedMetadata
            )
        } catch {
            try? fileManager.removeItem(at: prepared.destinationURL)
            throw error
        }
    }

    private func optimize(_ prepared: PreparedVideoImport) async throws {
        let asset = AVURLAsset(url: prepared.sourceURL)
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHEVCHighestQuality
        ) else {
            throw VideoImportExecutionError.couldNotCreateExportSession
        }
        guard session.supportedFileTypes.contains(.mov) else {
            throw VideoImportExecutionError.unsupportedExportType
        }

        try await session.export(to: prepared.destinationURL, as: .mov)
    }
}
