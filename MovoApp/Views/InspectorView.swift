import SwiftUI

struct InspectorView: View {
    @Bindable var model: WorkspaceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inspectorHeader
            sectionDivider
            framingSection
            sectionDivider
            loopSection
            sectionDivider
            playbackSection
            sectionDivider
            displaysSection
        }
        .padding(16)
        .background(MovoTheme.projectionBlack.opacity(0.98), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .movoHairline(RoundedRectangle(cornerRadius: 16, style: .continuous), opacity: 0.9)
        .shadow(color: .black.opacity(0.48), radius: 24, y: 12)
    }

    private var inspectorHeader: some View {
        HStack {
            Text("Adjustments")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                model.inspectorIsPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MovoTheme.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(MovoTheme.graphiteSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Inspector")
        }
        .padding(.bottom, 12)
    }

    private var framingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Framing")
            Picker("Framing", selection: $model.fitMode) {
                ForEach(WorkspaceModel.FitMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode == .fill ? "rectangle.inset.filled" : "rectangle")
                        .tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Text("Focal Point")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MovoTheme.secondaryText)

            FocalPointControl(point: $model.focalPoint)
                .frame(height: 78)
        }
        .padding(.vertical, 13)
    }

    private var loopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Loop")
            HStack(spacing: 10) {
                Text(model.loopStart, format: .number.precision(.fractionLength(2)))
                    .monospacedDigit()
                    .frame(width: 34, alignment: .leading)
                Slider(value: $model.loopStart, in: 0...max(0, model.loopEnd - 0.05))
                Slider(value: $model.loopEnd, in: min(1, model.loopStart + 0.05)...1)
                Text(model.loopEnd, format: .number.precision(.fractionLength(2)))
                    .monospacedDigit()
                    .frame(width: 34, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(MovoTheme.secondaryText)
        }
        .padding(.vertical, 13)
    }

    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Playback")
            HStack {
                Picker("Speed", selection: $model.playbackSpeed) {
                    Text("0.5×").tag(0.5)
                    Text("0.75×").tag(0.75)
                    Text("1×").tag(1.0)
                    Text("1.25×").tag(1.25)
                    Text("1.5×").tag(1.5)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                Text("Speed")
                    .font(.system(size: 12))
                    .foregroundStyle(MovoTheme.secondaryText)
                Spacer()
                Button {
                    model.togglePreviewPlayback()
                } label: {
                    Image(systemName: model.previewIsPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(model.previewIsPlaying ? "Pause Preview" : "Play Preview")
            }
        }
        .padding(.vertical, 13)
    }

    private var displaysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Displays")
            displayRow(title: "Desktop", systemImage: "display", linked: model.linkDesktopAndLockScreen)
            displayRow(title: "Lock Screen", systemImage: "lock", linked: model.linkDesktopAndLockScreen)

            Toggle("Link Desktop and Lock Screen", isOn: $model.linkDesktopAndLockScreen)
                .font(.system(size: 11, weight: .medium))
            Toggle("Apply to All Displays", isOn: $model.applyToAllDisplays)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.top, 13)
    }

    private func displayRow(title: String, systemImage: String, linked: Bool) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .foregroundStyle(MovoTheme.secondaryText)
                .frame(width: 18)
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Image(systemName: linked ? "link" : "link.badge.plus")
                .foregroundStyle(linked ? MovoTheme.primaryText : MovoTheme.tertiaryText)
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(MovoTheme.graphiteSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .movoHairline(RoundedRectangle(cornerRadius: 8, style: .continuous), opacity: 0.65)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(MovoTheme.primaryText)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(MovoTheme.hairline.opacity(0.75))
            .frame(height: 1)
    }
}
private struct FocalPointControl: View {
    @Binding var point: UnitPoint

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(MovoTheme.graphiteSurface)
                grid
                Circle()
                    .fill(MovoTheme.chrome)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                    .position(x: point.x * proxy.size.width, y: point.y * proxy.size.height)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        point = UnitPoint(
                            x: min(1, max(0, value.location.x / proxy.size.width)),
                            y: min(1, max(0, value.location.y / proxy.size.height))
                        )
                    }
            )
        }
        .movoHairline(RoundedRectangle(cornerRadius: 9, style: .continuous), opacity: 0.65)
        .accessibilityLabel("Focal Point")
        .accessibilityValue("Horizontal (Int(point.x * 100)) percent, vertical (Int(point.y * 100)) percent")
    }

    private var grid: some View {
        Canvas { context, size in
            for fraction in [1.0 / 3.0, 2.0 / 3.0] {
                var vertical = Path()
                vertical.move(to: CGPoint(x: size.width * fraction, y: 0))
                vertical.addLine(to: CGPoint(x: size.width * fraction, y: size.height))
                context.stroke(vertical, with: .color(MovoTheme.hairline.opacity(0.7)), lineWidth: 1)

                var horizontal = Path()
                horizontal.move(to: CGPoint(x: 0, y: size.height * fraction))
                horizontal.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
                context.stroke(horizontal, with: .color(MovoTheme.hairline.opacity(0.7)), lineWidth: 1)
            }
        }
    }
}
