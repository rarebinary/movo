import Darwin
import Foundation

public final class WallpaperRuntimeLoader: @unchecked Sendable {
    public static let frameworkPath = "/System/Library/PrivateFrameworks/WallpaperExtensionKit.framework/WallpaperExtensionKit"

    private static let requiredClassNames = [
        "WallpaperCreationRequestXPC",
        "WallpaperUpdateRequestXPC",
        "WallpaperRemoteContextXPC",
        "WallpaperSnapshotXPC",
        "WallpaperSettingsViewModelsXPC"
    ]

    private let gate: WallpaperCompatibilityGate
    private let environment: @Sendable () -> WallpaperRuntimeEnvironment
    private let openImage: @Sendable (String) -> UnsafeMutableRawPointer?
    private let lookupClass: @Sendable (String) -> AnyClass?
    private var imageHandle: UnsafeMutableRawPointer?

    public init(
        gate: WallpaperCompatibilityGate = WallpaperCompatibilityGate(),
        environment: @escaping @Sendable () -> WallpaperRuntimeEnvironment = WallpaperRuntimeEnvironment.current,
        openImage: @escaping @Sendable (String) -> UnsafeMutableRawPointer? = {
            dlopen($0, RTLD_NOW | RTLD_LOCAL)
        },
        lookupClass: @escaping @Sendable (String) -> AnyClass? = NSClassFromString
    ) {
        self.gate = gate
        self.environment = environment
        self.openImage = openImage
        self.lookupClass = lookupClass
    }

    deinit {
        if let imageHandle { dlclose(imageHandle) }
    }

    public func loadValidatedRuntime() throws {
        try gate.validate(environment())
        guard imageHandle == nil else { return }
        guard let handle = openImage(Self.frameworkPath) else {
            throw WallpaperCompatibilityFailure.privateFrameworkUnavailable
        }
        for className in Self.requiredClassNames where lookupClass(className) == nil {
            dlclose(handle)
            throw WallpaperCompatibilityFailure.requiredRuntimeClassMissing(className)
        }
        imageHandle = handle
    }
}
