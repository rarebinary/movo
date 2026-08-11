import SwiftUI

struct SettingsView: View {
    @Bindable var model: WorkspaceModel
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("pauseInLowPowerMode") private var pauseInLowPowerMode = true
    @AppStorage("pauseBelowTwentyPercent") private var pauseBelowTwentyPercent = true
    @AppStorage("pauseForFullscreenApps") private var pauseForFullscreenApps = true
    @AppStorage("pauseWhenDesktopHidden") private var pauseWhenDesktopHidden = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                MovoMark(size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Movo Settings")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Playback, energy, and local storage")
                        .font(.system(size: 12))
                        .foregroundStyle(MovoTheme.secondaryText)
                }
                Spacer()
            }
            .padding(22)

            ScrollView {
                VStack(spacing: 22) {
                    settingsSection("General") {
                        settingToggle("Launch at Login", detail: "Open Movo quietly when you sign in", isOn: $launchAtLogin)
                        settingToggle("Show Menu Bar Control", detail: "Keep playback and recent wallpapers nearby", isOn: .constant(true))
                    }

                    settingsSection("Energy") {
                        settingToggle("Pause in Low Power Mode", detail: "Resume automatically when Low Power Mode ends", isOn: $pauseInLowPowerMode)
                        settingToggle("Pause Below 20% Battery", detail: "Continue again after charging", isOn: $pauseBelowTwentyPercent)
                        settingToggle("Pause for Full-Screen Apps", detail: "Only pause the display occupied by the app", isOn: $pauseForFullscreenApps)
                        settingToggle("Pause When Desktop Is Hidden", detail: "Avoid rendering behind covered windows", isOn: $pauseWhenDesktopHidden)
                    }

                    settingsSection("Library") {
                        settingsRow(icon: "internaldrive", title: "Managed Storage", detail: "No videos imported yet") {
                            Button("Reveal") {}
                                .buttonStyle(.bordered)
                        }
                        settingsRow(icon: "clock.arrow.circlepath", title: "Automatic Cleanup", detail: "Manual") {
                            Picker("Cleanup", selection: .constant("Manual")) {
                                Text("Manual").tag("Manual")
                                Text("30 days").tag("30 days")
                                Text("90 days").tag("90 days")
                            }
                            .labelsHidden()
                            .frame(width: 110)
                        }
                    }

                    settingsSection("Wallpaper Extension") {
                        settingsRow(icon: "puzzlepiece.extension", title: "Extension Status", detail: "Not integrated in this build") {
                            Text("Unavailable")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(MovoTheme.warning)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }
        }
        .background(MovoTheme.voidBlack)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MovoTheme.secondaryText)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(MovoTheme.graphiteSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .movoHairline(RoundedRectangle(cornerRadius: 13, style: .continuous), opacity: 0.65)
        }
    }

    private func settingToggle(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        settingsRow(icon: nil, title: title, detail: detail) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    private func settingsRow<Trailing: View>(icon: String?, title: String, detail: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(MovoTheme.secondaryText)
                    .frame(width: 22)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(MovoTheme.tertiaryText)
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 54)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MovoTheme.hairline.opacity(0.42))
                .frame(height: 1)
                .padding(.leading, icon == nil ? 14 : 48)
        }
    }
}
