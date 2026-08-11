import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceView: View {
    @Bindable var model: WorkspaceModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                MovoTheme.voidBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                    content(proxy: proxy)
                }

                if model.inspectorIsPresented, model.selection != nil {
                    InspectorView(model: model)
                        .frame(width: 300)
                        .padding(.top, 82)
                        .padding(.trailing, 22)
                        .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
                        .zIndex(3)
                }

                if let notice = model.lastNotice {
                    NoticeView(notice: notice) {
                        model.lastNotice = nil
                    }
                    .padding(.top, 82)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .transition(.opacity)
                    .zIndex(4)
                }
            }
            .animation(.smooth(duration: reduceMotion ? 0.12 : 0.28), value: model.inspectorIsPresented)
        }
        .frame(minWidth: 960, minHeight: 640)
        .onOpenURL { url in
            model.importVideos(at: [url])
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 11) {
                MovoMark(size: 30)
                Text("Movo")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .tracking(-0.4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Movo")

            Spacer(minLength: 24)

            Menu {
                Button("Built-in Display") {}
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "display")
                    Text("Built-in Display")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(MovoTheme.secondaryText)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MovoTheme.primaryText)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(MovoTheme.projectionBlack, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .movoHairline(RoundedRectangle(cornerRadius: 11, style: .continuous), opacity: 0.75)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            if model.searchRequested {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(MovoTheme.secondaryText)
                    TextField("Search library", text: $model.searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 150)
                    Button {
                        model.searchRequested = false
                        model.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(MovoTheme.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(MovoTheme.projectionBlack, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .movoHairline(RoundedRectangle(cornerRadius: 11, style: .continuous), opacity: 0.75)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .trailing)))
            } else {
                OpticalIconButton(systemImage: "magnifyingglass", help: "Search Library") {
                    model.searchRequested = true
                }
            }

            OpticalIconButton(systemImage: "plus.square", help: "Import Video") {
                model.presentImporter()
            }

            OpticalIconButton(systemImage: "slider.horizontal.3", help: "Toggle Inspector", isSelected: model.inspectorIsPresented) {
                model.inspectorIsPresented.toggle()
            }

            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MovoTheme.primaryText)
                    .frame(width: 40, height: 40)
                    .background(MovoTheme.graphiteSheen, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .movoHairline(RoundedRectangle(cornerRadius: 11, style: .continuous), opacity: 0.75)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.leading, 28)
        .padding(.trailing, 24)
        .padding(.top, 34)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func content(proxy: GeometryProxy) -> some View {
        if model.wallpapers.isEmpty {
            EmptyWorkspaceView(
                importAction: model.presentImporter,
                importURLs: model.importVideos
            )
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
        } else {
            VStack(spacing: 0) {
                PreviewStage(model: model)
                    .padding(.horizontal, 28)

                Filmstrip(model: model)
                    .padding(.top, 12)
                    .padding(.horizontal, 28)

                bottomBar
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
            }
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .center, spacing: 16) {
            if let selection = model.selection {
                VStack(alignment: .leading, spacing: 5) {
                    Text(selection.title)
                        .font(.system(size: 28, weight: .semibold))
                        .tracking(-0.4)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text("\(selection.media.dimensions.width)×\(selection.media.dimensions.height)")
                        Text("•")
                        Text(selection.media.duration.formattedDuration)
                        Text("•")
                        Text("Managed")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MovoTheme.secondaryText)
                }
            }

            Spacer()

            OpticalIconButton(
                systemImage: model.selection?.isFavorite == true ? "heart.fill" : "heart",
                help: model.selection?.isFavorite == true ? "Remove from Favorites" : "Add to Favorites",
                isSelected: model.selection?.isFavorite == true
            ) {
                model.toggleFavorite()
            }

            OpticalIconButton(systemImage: "info.circle", help: "Wallpaper Information") {}

            OpticalIconButton(systemImage: "trash", help: "Move Wallpaper to Trash") {
                model.deleteSelection(undoManager: undoManager)
            }

            ChromePrimaryButton(title: "Set Wallpaper", systemImage: nil, action: model.requestSetWallpaper, isDisabled: model.selection == nil)
        }
        .frame(minHeight: 64)
    }
}

private struct EmptyWorkspaceView: View {
    let importAction: () -> Void
    let importURLs: ([URL]) -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MovoTheme.graphiteSheen)
                    .frame(width: 116, height: 84)
                    .movoHairline(RoundedRectangle(cornerRadius: 24, style: .continuous), opacity: 0.75)
                Image(systemName: "play.rectangle.on.rectangle")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(MovoTheme.chrome)
            }

            VStack(spacing: 8) {
                Text("Bring motion to your Mac")
                    .font(.system(size: 30, weight: .semibold))
                    .tracking(-0.5)
                Text("Drop a MOV or MP4 here, or choose a video up to 180 seconds.")
                    .font(.system(size: 14))
                    .foregroundStyle(MovoTheme.secondaryText)
            }

            ChromePrimaryButton(title: "Import Video", systemImage: "plus", action: importAction)

            HStack(spacing: 18) {
                Label("Managed copy", systemImage: "tray.full")
                Label("Always silent", systemImage: "speaker.slash")
                Label("Optimized when needed", systemImage: "bolt")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(MovoTheme.tertiaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MovoTheme.projectionBlack)
                .movoHairline(RoundedRectangle(cornerRadius: 18, style: .continuous), opacity: 0.7)
        )
        .contentShape(Rectangle())
        .onDrop(of: [UTType.movie.identifier], isTargeted: nil) { providers in
            guard let provider = providers.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
            }) else { return false }

            provider.loadInPlaceFileRepresentation(
                forTypeIdentifier: UTType.movie.identifier
            ) { url, _, _ in
                guard let url else { return }
                Task { @MainActor in importURLs([url]) }
            }
            return true
        }
    }
}

private struct PreviewStage: View {
    @Bindable var model: WorkspaceModel

    var body: some View {
        ZStack {
            if let selection = model.selection {
                SilentLoopingVideo(
                    url: model.managedURL(for: selection),
                    isPlaying: model.previewIsPlaying,
                    videoGravity: model.fitMode == .fill ? .resizeAspectFill : .resizeAspect
                )
            } else {
                WallpaperPlaceholder(swatch: .orbit)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.12), .black.opacity(0.42)],
                startPoint: .top,
                endPoint: .bottom
            )

            if !model.previewIsPlaying {
                Button {
                    model.togglePreviewPlayback()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(MovoTheme.voidBlack)
                        .frame(width: 60, height: 60)
                        .background(MovoTheme.chrome, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play Preview")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .movoHairline(RoundedRectangle(cornerRadius: 18, style: .continuous), opacity: 0.8)
        .aspectRatio(16 / 9, contentMode: .fit)
        .frame(maxHeight: .infinity)
        .onTapGesture(count: 2) { model.togglePreviewPlayback() }
    }
}

private struct Filmstrip: View {
    @Bindable var model: WorkspaceModel

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 10) {
                ForEach(model.filteredWallpapers) { wallpaper in
                    Button {
                        model.select(wallpaper)
                    } label: {
                        VideoThumbnail(url: model.managedURL(for: wallpaper))
                            .frame(width: 164, height: 92)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(model.selectedID == wallpaper.id ? AnyShapeStyle(MovoTheme.chrome) : AnyShapeStyle(MovoTheme.hairline), lineWidth: model.selectedID == wallpaper.id ? 2.5 : 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(wallpaper.title)
                    .accessibilityAddTraits(model.selectedID == wallpaper.id ? .isSelected : [])
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .frame(height: 96)
    }
}

struct WallpaperPlaceholder: View {
    let swatch: MovoSwatch

    var body: some View {
        ZStack {
            gradient
            Canvas { context, size in
                let horizon = size.height * 0.62
                context.fill(
                    Path(CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon)),
                    with: .linearGradient(
                        Gradient(colors: [.black.opacity(0.2), .black.opacity(0.82)]),
                        startPoint: CGPoint(x: 0, y: horizon),
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
                for index in 0..<22 {
                    let x = (CGFloat(index * 83 % 101) / 101) * size.width
                    let y = (CGFloat(index * 47 % 73) / 73) * horizon
                    let diameter = CGFloat(1 + index % 3)
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)), with: .color(.white.opacity(0.25)))
                }
            }
        }
    }

    private var gradient: LinearGradient {
        let colors: [Color] = switch swatch {
        case .orbit: [.black, Color(red: 0.12, green: 0.16, blue: 0.22), Color(red: 0.32, green: 0.35, blue: 0.38)]
        case .forest: [Color(red: 0.03, green: 0.08, blue: 0.06), Color(red: 0.14, green: 0.22, blue: 0.16), .black]
        case .city: [Color(red: 0.08, green: 0.07, blue: 0.09), Color(red: 0.35, green: 0.20, blue: 0.14), Color(red: 0.08, green: 0.12, blue: 0.16)]
        case .mountain: [Color(red: 0.10, green: 0.12, blue: 0.15), Color(red: 0.40, green: 0.39, blue: 0.36), Color(red: 0.13, green: 0.14, blue: 0.16)]
        case .desert: [Color(red: 0.15, green: 0.09, blue: 0.06), Color(red: 0.58, green: 0.32, blue: 0.15), Color(red: 0.12, green: 0.08, blue: 0.06)]
        case .rain: [Color(red: 0.02, green: 0.08, blue: 0.09), Color(red: 0.12, green: 0.24, blue: 0.25), .black]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct NoticeView: View {
    let notice: WorkspaceModel.WorkspaceNotice
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(notice.message)
                .font(.system(size: 12, weight: .medium))
            Button(action: dismiss) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .foregroundStyle(MovoTheme.primaryText)
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(MovoTheme.raisedGraphite, in: Capsule())
        .movoHairline(Capsule(), opacity: 0.9)
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
    }

    private var icon: String {
        switch notice.kind {
        case .neutral: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch notice.kind {
        case .neutral: MovoTheme.secondaryText
        case .success: MovoTheme.success
        case .warning: MovoTheme.warning
        }
    }
}

private extension TimeInterval {
    var formattedDuration: String {
        let seconds = max(0, Int(self.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
