import SwiftUI

struct HomeView: View {
    let onSelect: (Game) -> Void

    @EnvironmentObject private var progress: ProgressStore
    @State private var showParents = false
    @State private var showNicknamePicker = false
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
            if !didAskNickname && LaunchOptions.screenshotScreen == nil {
                didAskNickname = true
                showNicknamePicker = true
            } else if let name = ChildProfile.spokenName(name: childName, adjective: childAdjective) {
                Speaker.shared.say("Hallo \(name)! Was möchtest du spielen?")
            } else {
                Speaker.shared.say("Was möchtest du spielen?")
            }
        }
        .sheet(isPresented: $showParents) {
            ParentArea()
                .environmentObject(progress)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                showNicknamePicker = true
            } label: {
                Text(childEmoji)
                    .font(.system(size: 60))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Namen aussuchen")
            .sheet(isPresented: $showNicknamePicker) {
                NicknamePickerView()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(ChildProfile.title(name: childName, adjective: childAdjective))
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.4))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .onTapGesture { showNicknamePicker = true }
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
