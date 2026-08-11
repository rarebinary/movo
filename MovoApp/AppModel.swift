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
    var inspectorIsPresented = false
    var searchRequested = false
    var searchText = ""
    var fitMode: FitMode = .fill { didSet { settingsDidChange() } }
    var playbackSpeed = 1.0 { didSet { settingsDidChange() } }
    var loopStart = 0.0 { didSet { settingsDidChange() } }
    var loopEnd = 1.0 { didSet { settingsDidChange() } }
    var focalPoint = UnitPoint.center { didSet { settingsDidChange() } }
    var linkDesktopAndLockScreen = true
    var applyToAllDisplays = false
    var wallpaperTarget: WallpaperTarget = .both
    var targetPickerIsPresented = false
    var lastNotice: WorkspaceNotice?
    var isImporting = false

    private let libraryLocation: ManagedLibraryLocation
    private let libraryStore: ManagedLibraryStore
    private let importExecutor = VideoImportExecutor()
    private var settingsSaveTask: Task<Void, Never>?
    private var isRestoringSettings = false

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
        restoreSettings(from: wallpaper)
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

    var storageSummary: String {
        guard !wallpapers.isEmpty else { return "No videos imported yet" }
        let bytes = wallpapers.reduce(Int64.zero) { $0 + $1.media.fileSize }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
            + " across \(wallpapers.count) "
            + (wallpapers.count == 1 ? "video" : "videos")
    }

    func revealLibrary() {
        do {
            try FileManager.default.createDirectory(
                at: libraryLocation.mediaDirectoryURL,
                withIntermediateDirectories: true
            )
            NSWorkspace.shared.activateFileViewerSelecting([libraryLocation.mediaDirectoryURL])
        } catch {
            lastNotice = WorkspaceNotice(message: error.localizedDescription, kind: .warning)
        }
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
                    self.lastNotice = WorkspaceNotice(
                        message: prepared.plan.requiresOptimization
                            ? "Optimizing \(prepared.title) for Apple Silicon…"
                            : "Adding \(prepared.title) to your managed library…",
                        kind: .neutral
                    )
                    let item = try await importExecutor.execute(prepared)
                    let manifest = try await libraryStore.upsert(item)
                    wallpapers = manifest.items.sorted { $0.importedAt > $1.importedAt }
                    selectedID = item.id
                    restoreSettings(from: item)
                    importedCount += 1
                } catch {
                    self.lastNotice = WorkspaceNotice(
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

    var wallpaperTargetTitle: String {
        switch wallpaperTarget {
        case .both: "Both"
        case .desktop: "Desktop"
        case .lockScreen: "Lock Screen"
        }
    }

    func deleteSelection(undoManager: UndoManager?) {
        guard let selectedID,
              let item = wallpapers.first(where: { $0.id == selectedID }) else { return }
        let originalURL = managedURL(for: item)

        NSWorkspace.shared.recycle([originalURL]) { [weak self] trashedURLs, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.lastNotice = WorkspaceNotice(
                        message: "Could not move \(item.title) to Trash: \(error.localizedDescription)",
                        kind: .warning
                    )
                    return
                }
                guard let trashedURL = trashedURLs[originalURL] else {
                    self.lastNotice = WorkspaceNotice(message: "Could not confirm the Trash location.", kind: .warning)
                    return
                }

                do {
                    let manifest = try await self.libraryStore.remove(id: item.id)
                    self.wallpapers.removeAll { $0.id == item.id }
                    self.selectedID = self.wallpapers.first?.id
                    if let selection = self.selection { self.restoreSettings(from: selection) }
                    self.lastNotice = WorkspaceNotice(message: "Moved \(item.title) to Trash. Press ⌘Z to undo.", kind: .neutral)

                    if manifest != nil {
                        undoManager?.registerUndo(withTarget: self) { model in
                            model.restoreDeletedItem(item, from: trashedURL, to: originalURL)
                        }
                        undoManager?.setActionName("Delete Wallpaper")
                    }
                } catch {
                    try? FileManager.default.moveItem(at: trashedURL, to: originalURL)
                    self.lastNotice = WorkspaceNotice(message: error.localizedDescription, kind: .warning)
                }
            }
        }
    }

    private func restoreDeletedItem(_ item: WallpaperItem, from trashedURL: URL, to originalURL: URL) {
        Task {
            do {
                try FileManager.default.createDirectory(
                    at: originalURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try FileManager.default.moveItem(at: trashedURL, to: originalURL)
                let manifest = try await libraryStore.upsert(item)
                wallpapers = manifest.items.sorted { $0.importedAt > $1.importedAt }
                selectedID = item.id
                restoreSettings(from: item)
                lastNotice = WorkspaceNotice(message: "Restored \(item.title).", kind: .success)
            } catch {
                lastNotice = WorkspaceNotice(
                    message: "Could not restore \(item.title): \(error.localizedDescription)",
                    kind: .warning
                )
            }
        }
    }

    private func loadLibrary() async {
        do {
            let manifest = try await libraryStore.load()
            wallpapers = manifest.items.sorted { $0.importedAt > $1.importedAt }
            selectedID = wallpapers.first?.id
            if let selection { restoreSettings(from: selection) }
        } catch {
            lastNotice = WorkspaceNotice(
                message: "Movo could not open its managed library: \(error.localizedDescription)",
                kind: .warning
            )
        }
    }

    private func restoreSettings(from wallpaper: WallpaperItem) {
        isRestoringSettings = true
        fitMode = wallpaper.settings.framing == .fill ? .fill : .fit
        playbackSpeed = wallpaper.settings.playbackRate
        focalPoint = UnitPoint(
            x: wallpaper.settings.focalPoint.x,
            y: wallpaper.settings.focalPoint.y
        )
        if let range = wallpaper.settings.loopRange, wallpaper.media.duration > 0 {
            loopStart = max(0, min(1, range.start / wallpaper.media.duration))
            loopEnd = max(loopStart, min(1, range.end / wallpaper.media.duration))
        } else {
            loopStart = 0
            loopEnd = 1
        }
        isRestoringSettings = false
    }

    private func settingsDidChange() {
        guard !isRestoringSettings,
              let selectedID,
              let index = wallpapers.firstIndex(where: { $0.id == selectedID }) else { return }

        let duration = wallpapers[index].media.duration
        wallpapers[index].settings = WallpaperSettings(
            framing: fitMode == .fill ? .fill : .fit,
            focalPoint: .init(x: focalPoint.x, y: focalPoint.y),
            loopRange: .init(start: loopStart * duration, end: loopEnd * duration),
            playbackRate: playbackSpeed
        )
        let updated = wallpapers[index]

        settingsSaveTask?.cancel()
        settingsSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            do {
                _ = try await libraryStore.upsert(updated)
            } catch {
                lastNotice = WorkspaceNotice(message: error.localizedDescription, kind: .warning)
            }
        }
    }
}

private extension VideoImportPlan {
    var requiresOptimization: Bool {
        if case .optimize = self { return true }
        return false
    }
}
