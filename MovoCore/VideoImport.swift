import Foundation

public enum VideoImportValidationError: Error, Equatable, Sendable {
    case unsupportedFileExtension(String)
    case unreadableFile
    case noVideoTrack
    case invalidDuration
    case durationExceedsLimit(actual: TimeInterval, maximum: TimeInterval)
    case invalidDimensions
    case invalidFrameRate
}

extension VideoImportValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unsupportedFileExtension:
            "Choose a .mov or .mp4 video."
        case .unreadableFile:
            "Movo could not read this video."
        case .noVideoTrack:
            "This file does not contain a video track."
        case .invalidDuration:
            "This video has an invalid duration."
        case let .durationExceedsLimit(_, maximum):
            "Choose a video that is \(Int(maximum)) seconds or shorter."
        case .invalidDimensions:
            "This video has invalid dimensions."
        case .invalidFrameRate:
            "This video has an invalid frame rate."
        }
    }
}

public enum VideoImportValidator {
    public static let maximumDuration: TimeInterval = 180
    public static let supportedExtensions: Set<String> = ["mov", "mp4"]

    public static func validateFileExtension(of url: URL) throws {
        let fileExtension = url.pathExtension.lowercased()
        guard supportedExtensions.contains(fileExtension) else {
            throw VideoImportValidationError.unsupportedFileExtension(fileExtension)
        }
    }

    public static func validate(metadata: VideoMetadata) throws {
        guard metadata.duration.isFinite, metadata.duration > 0 else {
            throw VideoImportValidationError.invalidDuration
        }
        guard metadata.duration <= maximumDuration else {
            throw VideoImportValidationError.durationExceedsLimit(
                actual: metadata.duration,
                maximum: maximumDuration
            )
        }
        guard metadata.dimensions.width > 0, metadata.dimensions.height > 0 else {
            throw VideoImportValidationError.invalidDimensions
        }
        guard metadata.framesPerSecond.isFinite, metadata.framesPerSecond > 0 else {
            throw VideoImportValidationError.invalidFrameRate
        }
    }
}

public struct VideoOptimizationProfile: Equatable, Sendable {
    public let maximumWidth: Int
    public let maximumHeight: Int
    public let maximumFramesPerSecond: Double

    public init(
        maximumWidth: Int,
        maximumHeight: Int,
        maximumFramesPerSecond: Double = 60
    ) {
        self.maximumWidth = maximumWidth
        self.maximumHeight = maximumHeight
        self.maximumFramesPerSecond = maximumFramesPerSecond
    }
}

public enum VideoOptimizationReason: String, Codable, CaseIterable, Sendable {
    case codecIsNotHardwareFriendly
    case exceedsTargetResolution
    case exceedsFrameRateLimit
}

public enum VideoImportPlan: Equatable, Sendable {
    case directCopy
    case optimize(reasons: Set<VideoOptimizationReason>)
}

public struct PreparedVideoImport: Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let sourceURL: URL
    public let destinationURL: URL
    public let metadata: VideoMetadata
    public let plan: VideoImportPlan

    public init(
        id: UUID,
        title: String,
        sourceURL: URL,
        destinationURL: URL,
        metadata: VideoMetadata,
        plan: VideoImportPlan
    ) {
        self.id = id
        self.title = title
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.metadata = metadata
        self.plan = plan
    }
}

public enum VideoImportPlanner {
    public static func plan(
        metadata: VideoMetadata,
        profile: VideoOptimizationProfile
    ) -> VideoImportPlan {
        var reasons: Set<VideoOptimizationReason> = []

        if !metadata.codec.isHardwareFriendly {
            reasons.insert(.codecIsNotHardwareFriendly)
        }
        if metadata.dimensions.width > profile.maximumWidth
            || metadata.dimensions.height > profile.maximumHeight {
            reasons.insert(.exceedsTargetResolution)
        }
        if metadata.framesPerSecond > profile.maximumFramesPerSecond {
            reasons.insert(.exceedsFrameRateLimit)
        }

        return reasons.isEmpty ? .directCopy : .optimize(reasons: reasons)
    }

    public static func prepare(
        sourceURL: URL,
        title: String? = nil,
        id: UUID = UUID(),
        library: ManagedLibraryLocation,
        profile: VideoOptimizationProfile,
        inspector: VideoInspector = .init()
    ) async throws -> PreparedVideoImport {
        let metadata = try await inspector.inspect(url: sourceURL)
        let plan = plan(metadata: metadata, profile: profile)
        let resolvedTitle = normalizedTitle(title, sourceURL: sourceURL)
        let destinationExtension = switch plan {
        case .directCopy:
            sourceURL.pathExtension.lowercased()
        case .optimize:
            "mov"
        }
        let destinationURL = library.destinationURL(
            title: resolvedTitle,
            id: id,
            fileExtension: destinationExtension
        )

        return PreparedVideoImport(
            id: id,
            title: resolvedTitle,
            sourceURL: sourceURL,
            destinationURL: destinationURL,
            metadata: metadata,
            plan: plan
        )
    }

    private static func normalizedTitle(_ title: String?, sourceURL: URL) -> String {
        if let title {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        let sourceTitle = sourceURL.deletingPathExtension().lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return sourceTitle.isEmpty ? "Untitled Wallpaper" : sourceTitle
    }
}
