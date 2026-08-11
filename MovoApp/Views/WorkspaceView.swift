import AVFoundation
import MovoCore
import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceView: View {
    @Bindable var model: WorkspaceModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                MovoTheme.windowCanvas.ignoresSafeArea()

                content(proxy: proxy)

                topBar(proxy: proxy)
                    .offset(y: -proxy.safeAreaInsets.top)
                    .zIndex(3)

                if model.inspectorIsPresented, model.selection != nil {
                    InspectorView(model: model)
                        .frame(width: 300)
                        .padding(.top, 92)
                        .padding(.trailing, 20)
                        .padding(.bottom, 154)
                        .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
                        .zIndex(4)
                }

                if let notice = model.lastNotice {
                    NoticeView(notice: notice) {
                        model.lastNotice = nil
                    }
                    .padding(.top, 88)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .transition(.opacity)
                    .zIndex(5)
                }
            }
            .animation(.smooth(duration: reduceMotion ? 0.12 : 0.28), value: model.inspectorIsPresented)
        }
        .frame(minWidth: 960, minHeight: 640)
        .onOpenURL { url in
            model.importVideos(at: [url])
        }
    }

    private func topBar(proxy: GeometryProxy) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 11) {
                MovoMark(size: 30)
                if proxy.size.width >= 1060 {
                    Text("Movo")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .tracking(-0.4)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Movo")

            Spacer(minLength: 18)

            OpticalLabelButton(title: proxy.size.width >= 1120 ? "Built-in Display" : "Display", systemImage: "display") {
                model.inspectorIsPresented = true
            }

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
                .frame(height: OpticalControlSize.regular)
                .background(MovoTheme.opticalWell, in: Capsule())
                .movoHairline(Capsule(), opacity: 0.75)
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
                    .frame(width: OpticalControlSize.regular, height: OpticalControlSize.regular)
                    .background(MovoTheme.graphiteSheen, in: Circle())
                    .movoHairline(Circle(), opacity: 0.75)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.leading, 76)
        .padding(.trailing, 24)
        .padding(.top, 22)
    }

    @ViewBuilder
    private func content(proxy: GeometryProxy) -> some View {
        if model.wallpapers.isEmpty {
            EmptyWorkspaceView(
                importAction: model.presentImporter,
                importURLs: model.importVideos
            )
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 14)
        } else {
            ZStack(alignment: .bottom) {
                PreviewStage(model: model)

                VStack(spacing: 10) {
                    Spacer(minLength: 190)
                    Filmstrip(model: model)
                        .padding(.horizontal, 24)
                    actionDock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 22)
                }
            }
        }
    }

    private var actionDock: some View {
        HStack(alignment: .center, spacing: 16) {
            if let selection = model.selection {
                VStack(alignment: .leading, spacing: 5) {
                    Text(selection.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text("\(selection.media.dimensions.width)×\(selection.media.dimensions.height)")
                        Text("•")
                        Text(selection.media.duration.formattedDuration)
                        Text("•")
                        Text("Managed")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MovoTheme.secondaryText)
                }
                .frame(maxWidth: 250, alignment: .leading)
            }

            Spacer()

            OpticalLabelButton(title: model.wallpaperTargetTitle, systemImage: targetIcon) {
                model.targetPickerIsPresented = true
            }
            .popover(isPresented: $model.targetPickerIsPresented, arrowEdge: .bottom) {
                TargetPopover(model: model)
            }

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
        .padding(.leading, 18)
        .padding(.trailing, 10)
        .frame(maxWidth: 820, minHeight: 62)
        .movoFloatingSurface(Capsule())
        .frame(maxWidth: .infinity)
    }

    private var targetIcon: String {
        switch model.wallpaperTarget {
        case .both: "rectangle.on.rectangle"
        case .desktop: "display"
        case .lockScreen: "lock"
        }
    }
}

private struct TargetPopover: View {
    @Bindable var model: WorkspaceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Apply Wallpaper")
                    .font(.system(size: 15, weight: .semibold))
                Text("Choose where this video should appear.")
                    .font(.system(size: 11))
                    .foregroundStyle(MovoTheme.secondaryText)
            }

            HStack(spacing: 4) {
                ForEach(WallpaperTarget.allCases, id: \.self) { target in
                    Button {
                        model.wallpaperTarget = target
                        model.linkDesktopAndLockScreen = target == .both
                    } label: {
                        Text(label(for: target))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(model.wallpaperTarget == target ? MovoTheme.voidBlack : MovoTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(
                                model.wallpaperTarget == target
                                    ? AnyShapeStyle(MovoTheme.chrome)
                                    : AnyShapeStyle(Color.clear),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(MovoTheme.projectionBlack, in: Capsule())
            .movoHairline(Capsule(), opacity: 0.72)

            VStack(alignment: .leading, spacing: 8) {
                Text("DISPLAY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(MovoTheme.tertiaryText)

                HStack(spacing: 12) {
                    Image(systemName: "display")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(MovoTheme.primaryText)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Built-in Retina Display")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Main display")
                            .font(.system(size: 10))
                            .foregroundStyle(MovoTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MovoTheme.primaryText)
                }
                .padding(12)
                .background(MovoTheme.graphiteSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .movoHairline(RoundedRectangle(cornerRadius: 12, style: .continuous), opacity: 0.7)

                Toggle("Apply to all connected displays", isOn: $model.applyToAllDisplays)
                    .font(.system(size: 11, weight: .medium))
            }
        }
        .padding(16)
        .frame(width: 310)
        .background(MovoTheme.windowCanvas)
        .preferredColorScheme(.dark)
    }

    private func label(for target: WallpaperTarget) -> String {
        switch target {
        case .both: "Both"
        case .desktop: "Desktop"
        case .lockScreen: "Lock Screen"
        }
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

            MovoTheme.stageScrim

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
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .movoHairline(RoundedRectangle(cornerRadius: 22, style: .continuous), opacity: 0.72)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            .frame(width: 154, height: 86)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(model.selectedID == wallpaper.id ? AnyShapeStyle(MovoTheme.chrome) : AnyShapeStyle(MovoTheme.hairline), lineWidth: model.selectedID == wallpaper.id ? 2.5 : 1)
                            }
                            .overlay {
                                if model.selectedID == wallpaper.id {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                                        .padding(4)
                                }
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
        .contentMargins(.horizontal, 10, for: .scrollContent)
        .frame(height: 100)
        .padding(.vertical, 6)
        .background(MovoTheme.floatingSurface.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .movoHairline(RoundedRectangle(cornerRadius: 18, style: .continuous), opacity: 0.55)
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
