import SwiftUI

/// „Wer bist du?“ – das Kind tippt auf ein Tier und bekommt so seinen Namen in der App.
struct NicknamePickerView: View {
    @AppStorage(SettingsKey.childName) private var childName = ""
    @AppStorage(SettingsKey.childAdjective) private var childAdjective = "Kleine"
    @AppStorage(SettingsKey.childEmoji) private var childEmoji = ChildProfile.defaultEmoji
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.95, blue: 0.80), Color(red: 0.85, green: 0.93, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    RoundIconButton(systemName: "xmark", tint: .gray, size: 48) { dismiss() }
                        .accessibilityLabel("Schließen")
                }
                Text("Wer bist du?")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.4))
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 16)], spacing: 16) {
                        ForEach(ChildProfile.nicknames) { nickname in
                            Button {
                                choose(nickname)
                            } label: {
                                NicknameTile(nickname: nickname, isSelected: nickname.name == childName)
                            }
                            .buttonStyle(BouncyButtonStyle())
                            .accessibilityLabel(nickname.title)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(20)
            .frame(maxWidth: 820)
        }
        .onAppear {
            Speaker.shared.say("Wer bist du? Such dir einen Namen aus!")
        }
    }

    private func choose(_ nickname: Nickname) {
        childName = nickname.name
        childAdjective = nickname.adjective
        childEmoji = nickname.emoji
        Haptics.success()
        Speaker.shared.say("Hallo, \(nickname.adjective.lowercased()) \(nickname.name)!")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            dismiss()
        }
    }
}

private struct NicknameTile: View {
    let nickname: Nickname
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(nickname.emoji)
                .font(.system(size: 60))
            Text(nickname.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .cardBackground(cornerRadius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 5)
        )
    }
}
