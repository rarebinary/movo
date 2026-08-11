import AppKit
import SwiftUI

@main
struct MovoApp: App {
    @State private var model = WorkspaceModel()

    var body: some Scene {
        WindowGroup {
            WorkspaceView(model: model)
                .ignoresSafeArea(.container, edges: .top)
                .background(WindowConfigurator())
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1240, height: 790)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            MovoCommands(model: model)
        }

        Settings {
            SettingsView(model: model)
                .preferredColorScheme(.dark)
                .frame(width: 520, height: 590)
        }

        MenuBarExtra("Movo", systemImage: model.previewIsPlaying ? "rectangle.stack.fill" : "pause.rectangle.fill") {
            MenuBarContent(model: model)
        }
        .menuBarExtraStyle(.menu)
    }
}
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.titlebarSeparatorStyle = .none
        window.minSize = NSSize(width: 960, height: 640)
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.isMovableByWindowBackground = false
        window.tabbingMode = .disallowed
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerCurve = .continuous
            contentView.layer?.cornerRadius = window.styleMask.contains(.fullScreen) ? 0 : 22
            contentView.layer?.masksToBounds = true
        }
    }
}

private struct MovoCommands: Commands {
    let model: WorkspaceModel

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Import Video…") {
                model.presentImporter()
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandMenu("Playback") {
            Button(model.previewIsPlaying ? "Pause Preview" : "Play Preview") {
                model.togglePreviewPlayback()
            }
            .keyboardShortcut(.space, modifiers: [])

            Button("Set Wallpaper") {
                model.requestSetWallpaper()
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(model.selection == nil)
        }

        CommandMenu("Library") {
            Button("Search Library") {
                model.searchRequested.toggle()
            }
            .keyboardShortcut("f", modifiers: .command)

            Divider()

            Button("Move Wallpaper to Trash") {
                model.deleteSelection(undoManager: NSApp.keyWindow?.undoManager)
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(model.selection == nil)
        }
    }
}

private struct MenuBarContent: View {
    let model: WorkspaceModel

    var body: some View {
        if let selection = model.selection {
            Text(selection.title)
        } else {
            Text("No wallpaper selected")
        }

        Divider()

        Button(model.previewIsPlaying ? "Pause" : "Resume") {
            model.togglePreviewPlayback()
        }

        Menu("Recent Wallpapers") {
            ForEach(model.wallpapers.prefix(5)) { wallpaper in
                Button(wallpaper.title) {
                    model.select(wallpaper)
                }
            }
            if model.wallpapers.isEmpty {
                Text("No recent wallpapers")
            }
        }

        Divider()
        Button("Open Movo") { NSApp.activate(ignoringOtherApps: true) }
        SettingsLink { Text("Settings…") }
        Divider()
        Button("Quit Movo") { NSApp.terminate(nil) }
    }
}
