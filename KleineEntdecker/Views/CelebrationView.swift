import SwiftUI

struct CelebrationView: View {
    let tint: Color
    let onAgain: () -> Void
    let onHome: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            ConfettiView()
                .allowsHitTesting(false)

            VStack(spacing: 20) {
                Text("⭐️")
                    .font(.system(size: 130))
                    .scaleEffect(appear ? 1 : 0.2)
                    .rotationEffect(.degrees(appear ? 0 : -180))
                Text("Super gemacht!")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.4))
                    .minimumScaleFactor(0.6)
                HStack(spacing: 28) {
                    RoundIconButton(systemName: "arrow.counterclockwise", tint: tint, size: 84, action: onAgain)
                        .accessibilityLabel("Nochmal spielen")
                    RoundIconButton(systemName: "house.fill", tint: .gray, size: 84, action: onHome)
                        .accessibilityLabel("Zurück zum Start")
                }
            }
            .padding(32)
            .cardBackground(cornerRadius: 36)
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { appear = true }
            Speaker.shared.say("Super gemacht! Du hast einen Stern bekommen!", interrupt: false)
        }
    }
}

struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let emoji = ["🎉", "⭐️", "✨", "🎈", "🌟"].randomElement() ?? "⭐️"
        let x = CGFloat.random(in: 0...1)
        let duration = Double.random(in: 2.0...3.5)
        let delay = Double.random(in: 0...0.8)
        let spin = Double.random(in: -360...360)
    }

    @State private var pieces = (0..<26).map { _ in Piece() }
    @State private var fall = false

    var body: some View {
        GeometryReader { proxy in
            ForEach(pieces) { piece in
                Text(piece.emoji)
                    .font(.system(size: 30))
                    .rotationEffect(.degrees(fall ? piece.spin : 0))
                    .position(
                        x: piece.x * proxy.size.width,
                        y: fall ? proxy.size.height + 60 : -60
                    )
                    .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: fall)
            }
        }
        .ignoresSafeArea()
        .onAppear { fall = true }
    }
}
