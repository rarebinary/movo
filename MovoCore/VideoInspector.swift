@preconcurrency import AVFoundation
import CoreMedia
import Foundation

public struct VideoInspector: Sendable {
    public init() {}

    public func inspect(url: URL) async throws -> VideoMetadata {
        try VideoImportValidator.validateFileExtension(of: url)

        guard let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
              resourceValues.isRegularFile == true else {
            throw VideoImportValidationError.unreadableFile
        }

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw VideoImportValidationError.noVideoTrack
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let transformedSize = naturalSize.applying(preferredTransform)
        let width = Int(abs(transformedSize.width).rounded())
        let height = Int(abs(transformedSize.height).rounded())
        let framesPerSecond = Double(try await videoTrack.load(.nominalFrameRate))
        let formatDescriptions = try await videoTrack.load(.formatDescriptions)
        let codec = formatDescriptions.first.map {
            VideoCodec(rawValue: Self.fourCharacterCode(CMFormatDescriptionGetMediaSubType($0)))
        } ?? VideoCodec(rawValue: "unknown")
        let hasAudio = !(try await asset.loadTracks(withMediaType: .audio)).isEmpty

        let metadata = VideoMetadata(
            duration: duration,
            dimensions: .init(width: width, height: height),
            framesPerSecond: framesPerSecond,
            codec: codec,
            hasAudio: hasAudio,
            fileSize: Int64(resourceValues.fileSize ?? 0)
        )
        try VideoImportValidator.validate(metadata: metadata)
        return metadata
    }

    private static func fourCharacterCode(_ code: FourCharCode) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xff),
            UInt8((code >> 16) & 0xff),
            UInt8((code >> 8) & 0xff),
            UInt8(code & 0xff),
        ]
        return String(bytes: bytes, encoding: .macOSRoman) ?? "unknown"
    }
}
