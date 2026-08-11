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
}
extension View {
    func movoHairline<S: Shape>(_ shape: S, opacity: Double = 1) -> some View {
        overlay(shape.stroke(MovoTheme.hairline.opacity(opacity), lineWidth: 1))
    }
}
