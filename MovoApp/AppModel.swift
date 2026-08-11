import AppKit
import Foundation
import MovoCore
import Observation
import SwiftUI
import UniformTypeIdentifiers

enum MovoSwatch: String, Hashable, Sendable {
    case orbit
    case forest
    case city
    case mountain
    case desert
    case rain
}

@MainActor
@Observable
final class WorkspaceModel {
    var wallpapers: [WallpaperItem] = []
    var selectedID: WallpaperItem.ID?
    var previewIsPlaying = true
    var inspectorIsPresented = true
    var searchRequested = false
    var searchText = ""
    var fitMode: FitMode = .fill
    var playbackSpeed = 1.0
    var loopStart = 0.0
    var loopEnd = 1.0
    var focalPoint = UnitPoint.center
    var linkDesktopAndLockScreen = true
    var applyToAllDisplays = false
    var lastNotice: WorkspaceNotice?
    var isImporting = false

    private let libraryLocation: ManagedLibraryLocation
    private let libraryStore: ManagedLibraryStore
    private let importExecutor = VideoImportExecutor()

    init() {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        let libraryURL = applicationSupport
            .appending(path: "Movo", directoryHint: .isDirectory)
            .appending(path: "Library", directoryHint: .isDirectory)
        libraryLocation = ManagedLibraryLocation(rootURL: libraryURL)
        libraryStore = ManagedLibraryStore(libraryURL: libraryURL)
        Task { await loadLibrary() }
    }

    enum FitMode: String, CaseIterable, Identifiable {
        case fill = "Fill"
        case fit = "Fit"
        var id: Self { self }
    }

    struct WorkspaceNotice: Identifiable, Equatable {
        enum Kind { case neutral, success, warning }
        let id = UUID()
        let message: String
        let kind: Kind
    }

    var selection: WallpaperItem? {
        wallpapers.first { $0.id == selectedID }
    }

    var filteredWallpapers: [WallpaperItem] {
        guard !searchText.isEmpty else { return wallpapers }
        return wallpapers.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    func select(_ wallpaper: WallpaperItem) {
        selectedID = wallpaper.id
        previewIsPlaying = true
    }

    func togglePreviewPlayback() {
        previewIsPlaying.toggle()
    }

    func toggleFavorite() {
        guard let selectedID, let index = wallpapers.firstIndex(where: { $0.id == selectedID }) else { return }
        wallpapers[index].isFavorite.toggle()
        let updated = wallpapers[index]
        Task {
            do {
                _ = try await libraryStore.upsert(updated)
            } catch {
                lastNotice = WorkspaceNotice(message: error.localizedDescription, kind: .warning)
            }
        }
    }

    func managedURL(for wallpaper: WallpaperItem) -> URL {
        libraryLocation.mediaURL(for: wallpaper)
    }

    func presentImporter() {
        let panel = NSOpenPanel()
        panel.title = "Import a Live Wallpaper"
        panel.message = "Choose a MOV or MP4 video up to 180 seconds. Movo always plays wallpapers silently."
        panel.prompt = "Import Video"
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return }
        importVideos(at: panel.urls)
    }

    func importVideos(at urls: [URL]) {
        guard !urls.isEmpty, !isImporting else { return }
        isImporting = true
        lastNotice = WorkspaceNotice(message: "Inspecting media…", kind: .neutral)

        Task {
            defer { isImporting = false }
            var importedCount = 0
            for url in urls {
                do {
                    let prepared = try await VideoImportPlanner.prepare(
                        sourceURL: url,
                        library: libraryLocation,
                        profile: VideoOptimizationProfile(
                            maximumWidth: 3840,
                            maximumHeight: 2160,
                            maximumFramesPerSecond: 60
                        )
                    )
                    lastNotice = WorkspaceNotice(
                        message: prepared.plan.requiresOptimization
                            ? "Optimizing \(prepared.title) for Apple Silicon…"
                            : "Adding \(prepared.title) to your managed library…",
                        kind: .neutral
                    )
                    let item = try await importExecutor.execute(prepared)
                    let manifest = try await libraryStore.upsert(item)
                    wallpapers = manifest.items.sorted { $0.importedAt > $1.importedAt }
                    selectedID = item.id
                    importedCount += 1
                } catch {
                    lastNotice = WorkspaceNotice(
                        message: "Could not import \(url.lastPathComponent): \(error.localizedDescription)",
                        kind: .warning
                    )
                }
            }
            if importedCount > 0 {
                lastNotice = WorkspaceNotice(
                    message: importedCount == 1
                        ? "Video added to your managed library."
                        : "\(importedCount) videos added to your managed library.",
                    kind: .success
                )
            }
        }
    }

    func requestSetWallpaper() {
        guard selection != nil else { return }
        lastNotice = WorkspaceNotice(
            message: "Wallpaper extension integration is not active in this build yet.",
            kind: .warning
        )
    }

    private func loadLibrary() async {
        do {
            let manifest = try await libraryStore.load()
            wallpapers = manifest.items.sorted { $0.importedAt > $1.importedAt }
            selectedID = wallpapers.first?.id
        } catch {
            lastNotice = WorkspaceNotice(
                message: "Movo could not open its managed library: \(error.localizedDescription)",
                kind: .warning
            )
        }
    }
}

private extension VideoImportPlan {
    var requiresOptimization: Bool {
        if case .optimize = self { return true }
        return false
    }
}
