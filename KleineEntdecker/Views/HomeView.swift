import SwiftUI

struct HomeView: View {
    let onSelect: (Game) -> Void

    @EnvironmentObject private var progress: ProgressStore
    @State private var showParents = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.95, blue: 0.80), Color(red: 0.85, green: 0.93, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 20)], spacing: 20) {
                        ForEach(Game.allCases) { game in
                            Button {
                                onSelect(game)
                            } label: {
                                GameTile(game: game, stars: progress.stars(for: game))
                            }
                            .buttonStyle(BouncyButtonStyle())
                            .accessibilityLabel(game.title)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            Speaker.shared.say("Was möchtest du spielen?")
        }
        .sheet(isPresented: $showParents) {
            ParentArea()
                .environmentObject(progress)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("🦉")
                .font(.system(size: 60))
            VStack(alignment: .leading, spacing: 4) {
                Text("Kleine Entdecker")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.4))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("⭐️")
                    Text("\(progress.totalStars)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.4))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(progress.totalStars) Sterne gesammelt")
            }
            Spacer()
            Button {
                showParents = true
            } label: {
                Label("Eltern", systemImage: "lock.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.7)))
            }
        }
    }
}

struct GameTile: View {
    let game: Game
    let stars: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(game.icon)
                .font(.system(size: 64))
            Text(game.title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(stars > 0 ? "⭐️ \(stars)" : " ")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [game.tint.opacity(0.85), game.tint], startPoint: .top, endPoint: .bottom))
                .shadow(color: game.tint.opacity(0.4), radius: 8, y: 5)
        )
    }
}
