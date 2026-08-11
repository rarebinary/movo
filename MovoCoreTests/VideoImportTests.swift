import Foundation
import XCTest
@testable import MovoCore

final class VideoImportTests: XCTestCase {
    func testAcceptsSupportedExtensionsCaseInsensitively() throws {
        XCTAssertNoThrow(try VideoImportValidator.validateFileExtension(of: URL(fileURLWithPath: "/tmp/a.MOV")))
        XCTAssertNoThrow(try VideoImportValidator.validateFileExtension(of: URL(fileURLWithPath: "/tmp/a.mp4")))
    }

    func testRejectsUnsupportedExtension() {
        XCTAssertThrowsError(
            try VideoImportValidator.validateFileExtension(of: URL(fileURLWithPath: "/tmp/a.webm"))
        ) { error in
            XCTAssertEqual(error as? VideoImportValidationError, .unsupportedFileExtension("webm"))
        }
    }

    func testRejectsVideoLongerThanThreeMinutes() {
        let metadata = makeMetadata(duration: 180.001)

        XCTAssertThrowsError(try VideoImportValidator.validate(metadata: metadata)) { error in
            XCTAssertEqual(
                error as? VideoImportValidationError,
                .durationExceedsLimit(actual: 180.001, maximum: 180)
            )
        }
    }

    func testPlansDirectCopyForEfficientVideoEvenWhenItHasAudio() {
        let metadata = makeMetadata(codec: .hevc, hasAudio: true)
        let profile = VideoOptimizationProfile(maximumWidth: 3_840, maximumHeight: 2_160)

        XCTAssertEqual(VideoImportPlanner.plan(metadata: metadata, profile: profile), .directCopy)
    }

    func testPlansOptimizationForAllProblematicTraits() {
        let metadata = makeMetadata(
            dimensions: .init(width: 7_680, height: 4_320),
            framesPerSecond: 120,
            codec: VideoCodec(rawValue: "vp09")
        )
        let profile = VideoOptimizationProfile(maximumWidth: 3_840, maximumHeight: 2_160)

        XCTAssertEqual(
            VideoImportPlanner.plan(metadata: metadata, profile: profile),
            .optimize(reasons: [
                .codecIsNotHardwareFriendly,
                .exceedsTargetResolution,
                .exceedsFrameRateLimit,
            ])
        )
    }

    private func makeMetadata(
        duration: TimeInterval = 30,
        dimensions: VideoMetadata.Dimensions = .init(width: 1_920, height: 1_080),
        framesPerSecond: Double = 30,
        codec: VideoCodec = .h264,
        hasAudio: Bool = false
    ) -> VideoMetadata {
        VideoMetadata(
            duration: duration,
            dimensions: dimensions,
            framesPerSecond: framesPerSecond,
            codec: codec,
            hasAudio: hasAudio,
            fileSize: 10_000_000
        )
    }
}
