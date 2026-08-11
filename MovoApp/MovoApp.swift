import AppKit
import SwiftUI

@main
struct MovoApp: App {
    @State private var model = WorkspaceModel()

    var body: some Scene {
        WindowGroup {
            WorkspaceView(model: model)
                .background(WindowConfigurator())
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1240, height: 790)
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
        window.backgroundColor = NSColor(MovoTheme.voidBlack)
        window.minSize = NSSize(width: 960, height: 640)
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.isMovableByWindowBackground = false
        window.tabbingMode = .disallowed
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
