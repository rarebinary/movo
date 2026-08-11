import Foundation

public struct WallpaperItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public let managedFilename: String
    public let importedAt: Date
    public var lastUsedAt: Date?
    public var isFavorite: Bool
    public var media: VideoMetadata
    public var settings: WallpaperSettings

    public init(
        id: UUID = UUID(),
        title: String,
        managedFilename: String,
        importedAt: Date = Date(),
        lastUsedAt: Date? = nil,
        isFavorite: Bool = false,
        media: VideoMetadata,
        settings: WallpaperSettings = .init()
    ) {
        self.id = id
        self.title = title
        self.managedFilename = managedFilename
        self.importedAt = importedAt
        self.lastUsedAt = lastUsedAt
        self.isFavorite = isFavorite
        self.media = media
        self.settings = settings
    }
}

public struct WallpaperSettings: Codable, Equatable, Sendable {
    public enum Framing: String, Codable, CaseIterable, Sendable {
        case fill
        case fit
    }

    public struct FocalPoint: Codable, Equatable, Sendable {
        public var x: Double
        public var y: Double

        public init(x: Double = 0.5, y: Double = 0.5) {
            self.x = x
            self.y = y
        }
    }

    public struct LoopRange: Codable, Equatable, Sendable {
        public var start: TimeInterval
        public var end: TimeInterval

        public init(start: TimeInterval, end: TimeInterval) {
            self.start = start
            self.end = end
        }
    }

    public var framing: Framing
    public var focalPoint: FocalPoint
    public var loopRange: LoopRange?
    public var playbackRate: Double

    public init(
        framing: Framing = .fill,
        focalPoint: FocalPoint = .init(),
        loopRange: LoopRange? = nil,
        playbackRate: Double = 1
    ) {
        self.framing = framing
        self.focalPoint = focalPoint
        self.loopRange = loopRange
        self.playbackRate = playbackRate
    }
}

public struct VideoMetadata: Codable, Equatable, Sendable {
    public struct Dimensions: Codable, Equatable, Sendable {
        public let width: Int
        public let height: Int

        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
    }

    public let duration: TimeInterval
    public let dimensions: Dimensions
    public let framesPerSecond: Double
    public let codec: VideoCodec
    public let hasAudio: Bool
    public let fileSize: Int64

    public init(
        duration: TimeInterval,
        dimensions: Dimensions,
        framesPerSecond: Double,
        codec: VideoCodec,
        hasAudio: Bool,
        fileSize: Int64
    ) {
        self.duration = duration
        self.dimensions = dimensions
        self.framesPerSecond = framesPerSecond
        self.codec = codec
        self.hasAudio = hasAudio
        self.fileSize = fileSize
    }
}

public struct VideoCodec: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }

    public static let h264 = VideoCodec(rawValue: "avc1")
    public static let hevc = VideoCodec(rawValue: "hvc1")
    public static let hevcParameterSets = VideoCodec(rawValue: "hev1")

    public var isHardwareFriendly: Bool {
        self == .h264 || self == .hevc || self == .hevcParameterSets
    }
}
