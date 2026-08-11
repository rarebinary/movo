import SwiftUI

struct ChromePrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    var isDisabled = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(MovoTheme.voidBlack)
            .padding(.horizontal, 20)
            .frame(height: 42)
            .background(MovoTheme.chrome, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    .mask(Rectangle().frame(height: 12).frame(maxHeight: .infinity, alignment: .top))
            }
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(ChromePressStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }
}
struct OpticalIconButton: View {
    let systemImage: String
    let help: String
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSelected ? MovoTheme.voidBlack : MovoTheme.primaryText)
                .frame(width: 40, height: 40)
                .background(isSelected ? AnyShapeStyle(MovoTheme.chrome) : AnyShapeStyle(MovoTheme.graphiteSheen))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .movoHairline(RoundedRectangle(cornerRadius: 11, style: .continuous), opacity: isSelected ? 0.9 : 0.75)
        }
        .buttonStyle(OpticalPressStyle())
        .help(help)
        .accessibilityLabel(help)
    }
}

private struct ChromePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.08 : 0)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct OpticalPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
