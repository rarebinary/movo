import Foundation

public enum WallpaperTarget: String, Codable, CaseIterable, Sendable {
    case both
    case desktop
    case lockScreen

    public var includesDesktop: Bool {
        self == .both || self == .desktop
    }

    public var includesLockScreen: Bool {
        self == .both || self == .lockScreen
    }
}

public struct DisplayIdentity: Codable, Equatable, Hashable, Identifiable, Sendable {
    public enum ValidationError: Error, Equatable, Sendable {
        case emptyPersistentID
        case emptyName
    }

    public let persistentID: String
    public let name: String
    public let isBuiltIn: Bool

    public var id: String { persistentID }

    public init(persistentID: String, name: String, isBuiltIn: Bool) throws {
        let normalizedID = persistentID.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedID.isEmpty else {
            throw ValidationError.emptyPersistentID
        }
        guard !normalizedName.isEmpty else {
            throw ValidationError.emptyName
        }

        self.persistentID = normalizedID
        self.name = normalizedName
        self.isBuiltIn = isBuiltIn
    }

    public static func == (lhs: DisplayIdentity, rhs: DisplayIdentity) -> Bool {
        lhs.persistentID == rhs.persistentID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(persistentID)
    }

    private enum CodingKeys: String, CodingKey {
        case persistentID
        case name
        case isBuiltIn
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let persistentID = try container.decode(String.self, forKey: .persistentID)
        let name = try container.decode(String.self, forKey: .name)
        let isBuiltIn = try container.decode(Bool.self, forKey: .isBuiltIn)
        do {
            try self.init(persistentID: persistentID, name: name, isBuiltIn: isBuiltIn)
        } catch {
            throw DecodingError.dataCorruptedError(
                forKey: .persistentID,
                in: container,
                debugDescription: "Display identity contains empty required values."
            )
        }
    }
}

public struct WallpaperApplyRequest: Codable, Equatable, Identifiable, Sendable {
    public enum ValidationError: Error, Equatable, Sendable {
        case mediaURLIsNotAFile
    }

    public let id: UUID
    public let wallpaperID: UUID
    public let mediaURL: URL
    public let display: DisplayIdentity
    public let target: WallpaperTarget
    public let requestedAt: Date

    public init(
        id: UUID = UUID(),
        wallpaperID: UUID,
        mediaURL: URL,
        display: DisplayIdentity,
        target: WallpaperTarget,
        requestedAt: Date = Date()
    ) throws {
        guard mediaURL.isFileURL else {
            throw ValidationError.mediaURLIsNotAFile
        }

        self.id = id
        self.wallpaperID = wallpaperID
        self.mediaURL = mediaURL.standardizedFileURL
        self.display = display
        self.target = target
        self.requestedAt = requestedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case wallpaperID
        case mediaURL
        case display
        case target
        case requestedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            try self.init(
                id: container.decode(UUID.self, forKey: .id),
                wallpaperID: container.decode(UUID.self, forKey: .wallpaperID),
                mediaURL: container.decode(URL.self, forKey: .mediaURL),
                display: container.decode(DisplayIdentity.self, forKey: .display),
                target: container.decode(WallpaperTarget.self, forKey: .target),
                requestedAt: container.decode(Date.self, forKey: .requestedAt)
            )
        } catch let error as ValidationError {
            throw DecodingError.dataCorruptedError(
                forKey: .mediaURL,
                in: container,
                debugDescription: String(describing: error)
            )
        }
    }
}

public enum WallpaperApplyPhase: Codable, Equatable, Sendable {
    case queued
    case preparing
    case applying(WallpaperTarget)
    case verifying(WallpaperTarget)
    case completed
    case cancelled
    case failed

    public var isTerminal: Bool {
        switch self {
        case .completed, .cancelled, .failed:
            true
        case .queued, .preparing, .applying, .verifying:
            false
        }
    }
}

public struct WallpaperApplyError: Error, Codable, Equatable, Sendable {
    public enum Code: String, Codable, CaseIterable, Sendable {
        case extensionUnavailable
        case invalidMedia
        case displayUnavailable
        case permissionDenied
        case rendererFailed
        case verificationFailed
        case cancelled
        case unknown
    }

    public let code: Code
    public let phase: WallpaperApplyPhase
    public let target: WallpaperTarget?
    public let displayID: String?
    public let message: String
    public let recoverySuggestion: String?

    public init(
        code: Code,
        phase: WallpaperApplyPhase,
        target: WallpaperTarget? = nil,
        displayID: String? = nil,
        message: String,
        recoverySuggestion: String? = nil
    ) {
        self.code = code
        self.phase = phase
        self.target = target
        self.displayID = displayID
        self.message = message
        self.recoverySuggestion = recoverySuggestion
    }
}

extension WallpaperApplyError: LocalizedError {
    public var errorDescription: String? { message }
}

public enum RendererHealth: Codable, Equatable, Sendable {
    case unknown
    case starting
    case healthy(lastFrameAt: Date)
    case stalled(lastFrameAt: Date?)
    case failed(WallpaperApplyError)

    public var isOperational: Bool {
        switch self {
        case .starting, .healthy:
            true
        case .unknown, .stalled, .failed:
            false
        }
    }
}
