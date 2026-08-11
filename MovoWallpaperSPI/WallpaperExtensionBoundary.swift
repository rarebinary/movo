import Foundation
import OSLog

public final class WallpaperExtensionBoundary: @unchecked Sendable {
    private let runtimeLoader: WallpaperRuntimeLoader
    private let logger = Logger(subsystem: "dev.rarebinary.Movo", category: "WallpaperExtensionBoundary")

    public init(runtimeLoader: WallpaperRuntimeLoader = WallpaperRuntimeLoader()) {
        self.runtimeLoader = runtimeLoader
    }

    public func accept(connection: NSXPCConnection) -> Bool {
        do {
            try runtimeLoader.loadValidatedRuntime()
            logger.notice("Wallpaper runtime fingerprint accepted; XPC remains fail-closed pending verified request envelopes.")
        } catch {
            logger.error("Rejecting wallpaper connection: \(error.localizedDescription, privacy: .public)")
            return false
        }

        // Do not attach a guessed NSXPCInterface. The private protocol's selectors
        // are mapped, but its opaque request/reply envelopes are not yet ABI-safe.
        logger.error("Rejecting wallpaper connection because the protocol contract is not yet verified.")
        return false
    }
}
