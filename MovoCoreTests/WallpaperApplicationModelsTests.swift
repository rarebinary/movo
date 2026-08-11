import Foundation
import XCTest
@testable import MovoCore

final class WallpaperApplicationModelsTests: XCTestCase {
    func testTargetsDescribeIncludedSurfaces() {
        XCTAssertTrue(WallpaperTarget.both.includesDesktop)
        XCTAssertTrue(WallpaperTarget.both.includesLockScreen)
        XCTAssertTrue(WallpaperTarget.desktop.includesDesktop)
        XCTAssertFalse(WallpaperTarget.desktop.includesLockScreen)
        XCTAssertFalse(WallpaperTarget.lockScreen.includesDesktop)
        XCTAssertTrue(WallpaperTarget.lockScreen.includesLockScreen)
    }

    func testDisplayIdentityNormalizesAndRejectsEmptyValues() throws {
        let display = try DisplayIdentity(
            persistentID: "  built-in:main  ",
            name: "  Built-in Retina Display  ",
            isBuiltIn: true
        )

        XCTAssertEqual(display.id, "built-in:main")
        XCTAssertEqual(display.name, "Built-in Retina Display")
        XCTAssertThrowsError(
            try DisplayIdentity(persistentID: "   ", name: "Display", isBuiltIn: false)
        ) { error in
            XCTAssertEqual(error as? DisplayIdentity.ValidationError, .emptyPersistentID)
        }
        XCTAssertThrowsError(
            try DisplayIdentity(persistentID: "external:1", name: "\n", isBuiltIn: false)
        ) { error in
            XCTAssertEqual(error as? DisplayIdentity.ValidationError, .emptyName)
        }
    }

    func testDisplayIdentityRejectsInvalidDecodedState() {
        let data = Data(#"{"persistentID":"","name":"Display","isBuiltIn":false}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(DisplayIdentity.self, from: data))
    }

    func testDisplayIdentityRemainsStableWhenPresentationNameChanges() throws {
        let original = try DisplayIdentity(
            persistentID: "external:studio",
            name: "Studio Display",
            isBuiltIn: false
        )
        let renamed = try DisplayIdentity(
            persistentID: "external:studio",
            name: "Écran du studio",
            isBuiltIn: false
        )

        XCTAssertEqual(original, renamed)
        XCTAssertEqual(Set([original, renamed]).count, 1)
    }

    func testApplyRequestIsImmutableValueThatRoundTrips() throws {
        let request = try makeRequest(target: .both)

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(WallpaperApplyRequest.self, from: encoded)

        XCTAssertEqual(decoded, request)
        XCTAssertEqual(decoded.mediaURL.path, "/tmp/Movo/Media/slow-orbit.mov")
    }

    func testApplyRequestRejectsRemoteMediaURL() throws {
        let display = try DisplayIdentity(
            persistentID: "built-in:main",
            name: "Built-in Retina Display",
            isBuiltIn: true
        )

        XCTAssertThrowsError(
            try WallpaperApplyRequest(
                wallpaperID: UUID(),
                mediaURL: XCTUnwrap(URL(string: "https://example.com/wallpaper.mov")),
                display: display,
                target: .desktop
            )
        ) { error in
            XCTAssertEqual(error as? WallpaperApplyRequest.ValidationError, .mediaURLIsNotAFile)
        }
    }

    func testApplyPhasesExposeTerminalStateAndRoundTripAssociatedTarget() throws {
        let activePhase = WallpaperApplyPhase.applying(.lockScreen)
        let terminalPhases: [WallpaperApplyPhase] = [.completed, .cancelled, .failed]

        XCTAssertFalse(WallpaperApplyPhase.queued.isTerminal)
        XCTAssertFalse(activePhase.isTerminal)
        XCTAssertTrue(terminalPhases.allSatisfy(\.isTerminal))

        let encoded = try JSONEncoder().encode(activePhase)
        XCTAssertEqual(try JSONDecoder().decode(WallpaperApplyPhase.self, from: encoded), activePhase)
    }

    func testStructuredApplyErrorRoundTripsAndProvidesLocalizedMessage() throws {
        let error = WallpaperApplyError(
            code: .displayUnavailable,
            phase: .verifying(.both),
            target: .both,
            displayID: "external:studio",
            message: "The selected display is not connected.",
            recoverySuggestion: "Reconnect the display and try again."
        )

        let encoded = try JSONEncoder().encode(error)
        let decoded = try JSONDecoder().decode(WallpaperApplyError.self, from: encoded)

        XCTAssertEqual(decoded, error)
        XCTAssertEqual(decoded.errorDescription, "The selected display is not connected.")
    }

    func testRendererHealthSeparatesOperationalAndFailedStates() throws {
        let healthy = RendererHealth.healthy(lastFrameAt: Date(timeIntervalSince1970: 1_700_000_000))
        let failure = WallpaperApplyError(
            code: .rendererFailed,
            phase: .applying(.desktop),
            message: "The renderer stopped unexpectedly."
        )
        let failed = RendererHealth.failed(failure)

        XCTAssertTrue(RendererHealth.starting.isOperational)
        XCTAssertTrue(healthy.isOperational)
        XCTAssertFalse(RendererHealth.unknown.isOperational)
        XCTAssertFalse(RendererHealth.stalled(lastFrameAt: nil).isOperational)
        XCTAssertFalse(failed.isOperational)

        let encoded = try JSONEncoder().encode(failed)
        XCTAssertEqual(try JSONDecoder().decode(RendererHealth.self, from: encoded), failed)
    }

    private func makeRequest(target: WallpaperTarget) throws -> WallpaperApplyRequest {
        try WallpaperApplyRequest(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            wallpaperID: UUID(uuidString: "ABCDEF12-1234-1234-1234-123456789ABC")!,
            mediaURL: URL(fileURLWithPath: "/tmp/Movo/Media/slow-orbit.mov"),
            display: DisplayIdentity(
                persistentID: "built-in:main",
                name: "Built-in Retina Display",
                isBuiltIn: true
            ),
            target: target,
            requestedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
