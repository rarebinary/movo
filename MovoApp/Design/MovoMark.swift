import SwiftUI

struct MovoMark: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            MovoFrame()
                .stroke(MovoTheme.chrome, style: StrokeStyle(lineWidth: max(1.6, size * 0.085), lineCap: .round, lineJoin: .round))
            MovoFrame()
                .stroke(Color.white.opacity(0.22), lineWidth: max(0.5, size * 0.025))
                .offset(x: size * 0.12)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
private struct MovoFrame: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY * 0.82))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.maxY * 0.82))
        return path
    }
}
