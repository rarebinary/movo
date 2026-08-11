import SwiftUI

enum MovoTheme {
    static let voidBlack = Color(red: 0.035, green: 0.039, blue: 0.047)
    static let projectionBlack = Color(red: 0.051, green: 0.059, blue: 0.071)
    static let graphiteSurface = Color(red: 0.075, green: 0.086, blue: 0.102)
    static let raisedGraphite = Color(red: 0.102, green: 0.118, blue: 0.137)
    static let hairline = Color(red: 0.204, green: 0.224, blue: 0.251)
    static let primaryText = Color(red: 0.957, green: 0.961, blue: 0.965)
    static let secondaryText = Color(red: 0.639, green: 0.659, blue: 0.686)
    static let tertiaryText = Color(red: 0.455, green: 0.478, blue: 0.510)
    static let success = Color(red: 0.467, green: 0.710, blue: 0.541)
    static let warning = Color(red: 0.820, green: 0.659, blue: 0.369)

    static let windowCanvas = LinearGradient(
        stops: [
            .init(color: Color(red: 0.025, green: 0.028, blue: 0.033), location: 0),
            .init(color: voidBlack, location: 0.46),
            .init(color: Color(red: 0.052, green: 0.058, blue: 0.067), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let stageScrim = LinearGradient(
        stops: [
            .init(color: .black.opacity(0.72), location: 0),
            .init(color: .black.opacity(0.08), location: 0.24),
            .init(color: .clear, location: 0.55),
            .init(color: .black.opacity(0.78), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let chrome = LinearGradient(
        stops: [
            .init(color: Color(red: 0.435, green: 0.455, blue: 0.486), location: 0),
            .init(color: Color(red: 0.941, green: 0.949, blue: 0.961), location: 0.34),
            .init(color: Color(red: 0.722, green: 0.741, blue: 0.773), location: 0.68),
            .init(color: Color(red: 0.494, green: 0.518, blue: 0.549), location: 1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let graphiteSheen = LinearGradient(
        colors: [raisedGraphite, projectionBlack, Color(red: 0.114, green: 0.125, blue: 0.145)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let opticalWell = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.10), location: 0),
            .init(color: raisedGraphite.opacity(0.94), location: 0.18),
            .init(color: projectionBlack.opacity(0.96), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let floatingSurface = Color(red: 0.055, green: 0.061, blue: 0.071).opacity(0.96)
}
extension View {
    func movoHairline<S: Shape>(_ shape: S, opacity: Double = 1) -> some View {
        overlay(shape.stroke(MovoTheme.hairline.opacity(opacity), lineWidth: 1))
    }

    func movoFloatingSurface<S: Shape>(_ shape: S) -> some View {
        background(MovoTheme.floatingSurface, in: shape)
            .movoHairline(shape, opacity: 0.9)
            .shadow(color: .black.opacity(0.48), radius: 22, y: 12)
    }
}
