import Foundation
import XCTest
@testable import MovoWallpaperSPI

final class WallpaperCompatibilityTests: XCTestCase {
    private final class LockedCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var storage = 0

        func increment() {
            lock.withLock { storage += 1 }
        }

        var value: Int {
            lock.withLock { storage }
        }
    }

    func testValidatedFingerprintAcceptsReferenceMachine() throws {
        let environment = WallpaperRuntimeEnvironment(fingerprint: .validated)
        XCTAssertNoThrow(try WallpaperCompatibilityGate().validate(environment))
    }

    func testUnknownBuildFailsClosed() {
        let expected = WallpaperRuntimeFingerprint.validated
        let actual = WallpaperRuntimeFingerprint(
            operatingSystemVersion: expected.operatingSystemVersion,
            operatingSystemBuild: "25D999",
            architecture: expected.architecture
        )

        XCTAssertThrowsError(
            try WallpaperCompatibilityGate().validate(WallpaperRuntimeEnvironment(fingerprint: actual))
        ) { error in
            XCTAssertEqual(
                error as? WallpaperCompatibilityFailure,
                .unsupportedOperatingSystemBuild(expected: "25D125", actual: "25D999")
            )
        }
    }

    func testWrongArchitectureFailsClosed() {
        let expected = WallpaperRuntimeFingerprint.validated
        let actual = WallpaperRuntimeFingerprint(
            operatingSystemVersion: expected.operatingSystemVersion,
            operatingSystemBuild: expected.operatingSystemBuild,
            architecture: "x86_64"
        )

        XCTAssertThrowsError(
            try WallpaperCompatibilityGate().validate(WallpaperRuntimeEnvironment(fingerprint: actual))
        ) { error in
            XCTAssertEqual(
                error as? WallpaperCompatibilityFailure,
                .unsupportedArchitecture(expected: "arm64", actual: "x86_64")
            )
        }
    }

    func testLoaderRejectsMissingFrameworkBeforeInspectingClasses() {
        let classLookupCount = LockedCounter()
        let loader = WallpaperRuntimeLoader(
            environment: { WallpaperRuntimeEnvironment(fingerprint: .validated) },
            openImage: { _ in nil },
            lookupClass: { _ in classLookupCount.increment(); return nil }
        )

        XCTAssertThrowsError(try loader.loadValidatedRuntime()) { error in
            XCTAssertEqual(error as? WallpaperCompatibilityFailure, .privateFrameworkUnavailable)
        }
        XCTAssertEqual(classLookupCount.value, 0)
    }

    func testCurrentMachineMatchesValidatedFingerprint() throws {
        try WallpaperCompatibilityGate().validate(.current())
    }
}
