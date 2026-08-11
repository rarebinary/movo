import Darwin
import Foundation

public struct WallpaperOSVersion: Equatable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init(_ version: OperatingSystemVersion) {
        self.init(
            major: version.majorVersion,
            minor: version.minorVersion,
            patch: version.patchVersion
        )
    }
}

public struct WallpaperRuntimeFingerprint: Equatable, Sendable {
    public static let validated = WallpaperRuntimeFingerprint(
        operatingSystemVersion: WallpaperOSVersion(major: 26, minor: 3, patch: 0),
        operatingSystemBuild: "25D125",
        architecture: "arm64"
    )

    public let operatingSystemVersion: WallpaperOSVersion
    public let operatingSystemBuild: String
    public let architecture: String

    public init(
        operatingSystemVersion: WallpaperOSVersion,
        operatingSystemBuild: String,
        architecture: String
    ) {
        self.operatingSystemVersion = operatingSystemVersion
        self.operatingSystemBuild = operatingSystemBuild
        self.architecture = architecture
    }
}

public enum WallpaperCompatibilityFailure: Error, Equatable, Sendable {
    case unsupportedOperatingSystemVersion(expected: WallpaperOSVersion, actual: WallpaperOSVersion)
    case unsupportedOperatingSystemBuild(expected: String, actual: String)
    case unsupportedArchitecture(expected: String, actual: String)
    case privateFrameworkUnavailable
    case requiredRuntimeClassMissing(String)
    case protocolContractUnverified
}

extension WallpaperCompatibilityFailure: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .unsupportedOperatingSystemVersion(expected, actual):
            "Movo's wallpaper integration was validated on macOS \(expected.major).\(expected.minor), not \(actual.major).\(actual.minor)."
        case let .unsupportedOperatingSystemBuild(expected, actual):
            "Movo's wallpaper integration expects build \(expected), not \(actual)."
        case let .unsupportedArchitecture(expected, actual):
            "Movo's wallpaper integration expects \(expected), not \(actual)."
        case .privateFrameworkUnavailable:
            "WallpaperExtensionKit could not be loaded on this Mac."
        case let .requiredRuntimeClassMissing(name):
            "WallpaperExtensionKit is missing required runtime class \(name)."
        case .protocolContractUnverified:
            "The wallpaper XPC protocol is intentionally disabled until its request envelopes pass the contract tests."
        }
    }
}

public struct WallpaperRuntimeEnvironment: Equatable, Sendable {
    public let fingerprint: WallpaperRuntimeFingerprint

    public init(fingerprint: WallpaperRuntimeFingerprint) {
        self.fingerprint = fingerprint
    }

    public static func current() -> WallpaperRuntimeEnvironment {
        WallpaperRuntimeEnvironment(
            fingerprint: WallpaperRuntimeFingerprint(
                operatingSystemVersion: WallpaperOSVersion(ProcessInfo.processInfo.operatingSystemVersion),
                operatingSystemBuild: operatingSystemBuild(),
                architecture: machineArchitecture()
            )
        )
    }

    private static func operatingSystemBuild() -> String {
        sysctlString(named: "kern.osversion")
    }

    private static func machineArchitecture() -> String {
        sysctlString(named: "hw.machine")
    }

    private static func sysctlString(named name: String) -> String {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else { return "unknown" }
        var bytes = [UInt8](repeating: 0, count: size)
        guard sysctlbyname(name, &bytes, &size, nil, 0) == 0 else { return "unknown" }
        if bytes.last == 0 { bytes.removeLast() }
        return String(decoding: bytes, as: UTF8.self)
    }
}

public struct WallpaperCompatibilityGate: Sendable {
    public let requiredFingerprint: WallpaperRuntimeFingerprint

    public init(requiredFingerprint: WallpaperRuntimeFingerprint = .validated) {
        self.requiredFingerprint = requiredFingerprint
    }

    public func validate(_ environment: WallpaperRuntimeEnvironment) throws {
        let actual = environment.fingerprint
        guard actual.operatingSystemVersion == requiredFingerprint.operatingSystemVersion else {
            throw WallpaperCompatibilityFailure.unsupportedOperatingSystemVersion(
                expected: requiredFingerprint.operatingSystemVersion,
                actual: actual.operatingSystemVersion
            )
        }
        guard actual.operatingSystemBuild == requiredFingerprint.operatingSystemBuild else {
            throw WallpaperCompatibilityFailure.unsupportedOperatingSystemBuild(
                expected: requiredFingerprint.operatingSystemBuild,
                actual: actual.operatingSystemBuild
            )
        }
        guard actual.architecture == requiredFingerprint.architecture else {
            throw WallpaperCompatibilityFailure.unsupportedArchitecture(
                expected: requiredFingerprint.architecture,
                actual: actual.architecture
            )
        }
    }
}
