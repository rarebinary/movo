import SwiftUI

enum OpticalControlSize {
    static let compact: CGFloat = 36
    static let regular: CGFloat = 42
    static let hitTarget: CGFloat = 44
}

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
            .frame(minWidth: 132, minHeight: OpticalControlSize.regular)
            .background(MovoTheme.chrome, in: Capsule())
            .overlay(alignment: .top) {
                Capsule()
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
                .frame(width: OpticalControlSize.regular, height: OpticalControlSize.regular)
                .background(isSelected ? AnyShapeStyle(MovoTheme.chrome) : AnyShapeStyle(MovoTheme.graphiteSheen))
                .clipShape(Circle())
                .movoHairline(Circle(), opacity: isSelected ? 0.95 : 0.72)
        }
        .buttonStyle(OpticalPressStyle())
        .help(help)
        .accessibilityLabel(help)
    }
}

struct OpticalLabelButton: View {
    let title: String
    let systemImage: String?
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isSelected ? MovoTheme.voidBlack.opacity(0.7) : MovoTheme.tertiaryText)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isSelected ? MovoTheme.voidBlack : MovoTheme.primaryText)
            .padding(.horizontal, 14)
            .frame(minHeight: OpticalControlSize.regular)
            .background(isSelected ? AnyShapeStyle(MovoTheme.chrome) : AnyShapeStyle(MovoTheme.opticalWell), in: Capsule())
            .movoHairline(Capsule(), opacity: isSelected ? 0.95 : 0.72)
        }
        .buttonStyle(OpticalPressStyle())
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
