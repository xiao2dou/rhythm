import SwiftUI

struct RhythmMenuBarLabel: View {
    var body: some View {
        RhythmMenuLogo(size: 17)
            .frame(width: 18, height: 18)
            .accessibilityLabel("Rhythm")
    }
}

struct RhythmMenuLogo: View {
    var size: CGFloat = 17

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.19, green: 0.78, blue: 0.70))
            Circle()
                .stroke(Color.black.opacity(0.22), lineWidth: max(0.7, size * 0.05))
            RhythmPulseShape()
                .stroke(
                    Color.white.opacity(0.97),
                    style: StrokeStyle(
                        lineWidth: max(1.8, size * 0.14),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .padding(size * 0.16)
        }
        .frame(width: size, height: size)
    }
}

private struct RhythmPulseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.05, y: midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.30, y: midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.43, y: rect.minY + rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.56, y: rect.maxY - rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.34))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.95, y: midY))
        return path
    }
}
