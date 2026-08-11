import Foundation
import XCTest
@testable import MovoCore

final class ManagedLibraryTests: XCTestCase {
    func testManagedFilenameIsReadableStableAndUnique() {
        let location = ManagedLibraryLocation(rootURL: URL(fileURLWithPath: "/tmp/Movo"))
        let firstID = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
        let secondID = UUID(uuidString: "ABCDEF12-1234-1234-1234-123456789ABC")!

        XCTAssertEqual(
            location.managedFilename(title: "Été / Slow Orbit!", id: firstID, fileExtension: "MP4"),
            "ete-slow-orbit-12345678.mp4"
        )
        XCTAssertNotEqual(
            location.managedFilename(title: "Slow Orbit", id: firstID, fileExtension: "mov"),
            location.managedFilename(title: "Slow Orbit", id: secondID, fileExtension: "mov")
        )
        XCTAssertEqual(
            location.managedFilename(title: "🌌", id: firstID, fileExtension: "mov"),
            "wallpaper-12345678.mov"
        )
    }

    func testManifestRoundTripsAndUpserts() async throws {
        let temporaryURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        let store = ManagedLibraryStore(libraryURL: temporaryURL)
        let item = makeItem(title: "First")
        try await store.save(.init(items: [item]))

        var loaded = try await store.load()
        XCTAssertEqual(loaded.items, [item])

        var renamed = item
        renamed.title = "Renamed"
        loaded = try await store.upsert(renamed)

        XCTAssertEqual(loaded.items.count, 1)
        XCTAssertEqual(loaded.items.first?.title, "Renamed")
        XCTAssertTrue(FileManager.default.fileExists(atPath: temporaryURL.appending(path: "Media").path))
    }

    func testRemoveReturnsRemovedItemAndPersists() async throws {
        let temporaryURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        let store = ManagedLibraryStore(libraryURL: temporaryURL)
        let item = makeItem(title: "Remove Me")
        try await store.save(.init(items: [item]))

        let removed = try await store.remove(id: item.id)

        XCTAssertEqual(removed, item)
        let manifest = try await store.load()
        XCTAssertTrue(manifest.items.isEmpty)
    }

    private func makeItem(title: String) -> WallpaperItem {
        WallpaperItem(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            title: title,
            managedFilename: "first-12345678.mp4",
            importedAt: Date(timeIntervalSince1970: 1_700_000_000),
            media: .init(
                duration: 12,
                dimensions: .init(width: 3_840, height: 2_160),
                framesPerSecond: 60,
                codec: .hevc,
                hasAudio: false,
                fileSize: 42_000_000
            )
        )
    }
}
