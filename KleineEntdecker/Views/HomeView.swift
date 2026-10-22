import SwiftUI

struct HomeView: View {
    let onSelect: (Game) -> Void

    /// Begrüßt wird nur beim ersten Erscheinen nach dem App-Start.
    private static var didGreetThisSession = false

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.layoutScale) private var scale
    @State private var showParents = false
    @State private var showStarSky = false
    @State private var showNicknamePicker = false
    @State private var isFirstLaunch = false
    @AppStorage(SettingsKey.childName) private var childName = ""
    @AppStorage(SettingsKey.childAdjective) private var childAdjective = "Kleine"
    @AppStorage(SettingsKey.childEmoji) private var childEmoji = ChildProfile.defaultEmoji
    @AppStorage(SettingsKey.didAskNickname) private var didAskNickname = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.95, blue: 0.80), Color(red: 0.85, green: 0.93, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20 * scale) {
                    header
                    gameGrid(Game.basics)
                    Label("Vorschule", systemImage: "graduationcap.fill")
                        .font(.system(size: 22 * scale, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.4))
                        .padding(.top, 8 * scale)
                        .accessibilityAddTraits(.isHeader)
                    gameGrid(Game.preschool)
                }
                .padding(24)
                .frame(maxWidth: 900 * scale)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            if !didAskNickname && LaunchOptions.screenshotScreen == nil {
                didAskNickname = true
                isFirstLaunch = true
                showNicknamePicker = true
            } else if Self.didGreetThisSession {
                // Zurück aus einem Spiel: nicht noch einmal begrüßen.
                Speaker.shared.say(Lines.homeNext)
            } else {
                greet()
            }
            Self.didGreetThisSession = true
        }
        .sheet(isPresented: $showParents) {
            ParentArea()
                .environmentObject(progress)
        }
    }

    private func greet() {
        if let name = ChildProfile.recordedSpokenName(name: childName, adjective: childAdjective) {
            Speaker.shared.say("\(Lines.hello(name)) \(Lines.homeQuestion)")
        } else {
            Speaker.shared.say(Lines.homeGreeting)
        }
    }

    private func gameGrid(_ games: [Game]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150 * scale, maximum: 260 * scale), spacing: 20 * scale)], spacing: 20 * scale) {
            ForEach(games) { game in
                Button {
                    onSelect(game)
                } label: {
                    GameTile(game: game)
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(game.title)
            }
        }
    }

    /// Kopfzeile in zwei Reihen, damit auch auf kleinen iPhones nichts gequetscht wird:
    /// oben Kind + Elternbereich, darunter Huhu und das Sternenhimmel-Banner.
    private var header: some View {
        VStack(spacing: 14 * scale) {
            HStack(alignment: .center, spacing: 12) {
                Button {
                    showNicknamePicker = true
                } label: {
                    HStack(spacing: 10) {
                        Text(childEmoji)
                            .font(.system(size: 52 * scale))
                        Text(ChildProfile.title(name: childName, adjective: childAdjective))
                            .font(.system(size: 30 * scale, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.4))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Namen aussuchen")
                .sheet(isPresented: $showNicknamePicker, onDismiss: { isFirstLaunch = false }) {
                    NicknamePickerView(introduceOwl: isFirstLaunch)
                }
                Spacer(minLength: 8)
                Button {
                    showParents = true
                } label: {
                    Label("Eltern", systemImage: "lock.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                        .fixedSize()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.7)))
                }
            }

            HStack(spacing: 12 * scale) {
                // Huhu, die Eule – tippt das Kind sie an, begrüßt sie es noch einmal.
                Button(action: greet) {
                    Text("🦉")
                        .font(.system(size: 50 * scale))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Huhu, die Eule")

                Button {
                    showStarSky = true
                } label: {
                    StarSkyBanner(starCount: progress.totalStars)
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Huhus Sternenhimmel, \(progress.totalStars) Sterne")
                .sheet(isPresented: $showStarSky) {
                    StarSkyView(starCount: progress.totalStars)
                }
            }
        }
    }
}

/// Breites Banner zum Sternenhimmel – ein kleiner Nachthimmel mit Sternen.
private struct StarSkyBanner: View {
    let starCount: Int

    @Environment(\.layoutScale) private var scale

    var body: some View {
        HStack(spacing: 10) {
            Text("✨")
                .font(.system(size: 26 * scale))
            Text("Sternenhimmel")
                .font(.system(size: 20 * scale, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Text("⭐️ \(starCount)")
                .font(.system(size: 17 * scale, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12 * scale)
        .frame(maxWidth: .infinity, minHeight: 56 * scale)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.12, green: 0.14, blue: 0.38), Color(red: 0.32, green: 0.24, blue: 0.58)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        )
    }
}

struct GameTile: View {
    let game: Game

    @Environment(\.layoutScale) private var scale

    var body: some View {
        VStack(spacing: 8) {
            Text(game.icon)
                .font(.system(size: 64 * scale))
            Text(game.title)
                .font(.system(size: 22 * scale, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
                .frame(minHeight: 56 * scale)
        }
        .padding(.vertical, 18 * scale)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [game.tint.opacity(0.85), game.tint], startPoint: .top, endPoint: .bottom))
                .shadow(color: game.tint.opacity(0.4), radius: 8, y: 5)
        )
    }
}
