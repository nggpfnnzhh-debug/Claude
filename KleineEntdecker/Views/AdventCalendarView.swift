import SwiftUI

/// Huhus Adventskalender: Das Kind sucht die Tür mit der heutigen Zahl und öffnet sie.
struct AdventCalendarView: View {
    let today: Int
    let onClose: () -> Void

    @Environment(\.layoutScale) private var scale
    @State private var opened = AdventCalendar.openedDoors()
    @State private var shownDoor: AdventDoor?
    @State private var lockedTaps = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    private let green = Color(red: 0.12, green: 0.42, blue: 0.25)

    /// Ab dem 24. darf jede Tür auf.
    private var lastOpenable: Int { min(today, 24) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.16, blue: 0.36), Color(red: 0.22, green: 0.18, blue: 0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            SeasonalDecorView(emojis: ["❄️", "⭐️"])

            VStack(spacing: 14 * scale) {
                HStack {
                    RoundIconButton(systemName: "house.fill", tint: green, action: onClose)
                        .accessibilityLabel("Zurück zum Start")
                    Spacer()
                    Text("🎄 Adventskalender")
                        .font(.system(size: 22 * scale, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Spacer()
                    RoundIconButton(systemName: "speaker.wave.2.fill", tint: green, action: speakIntro)
                        .accessibilityLabel("Anweisung wiederholen")
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(AdventCalendar.layout, id: \.self) { number in
                        Button {
                            tap(number)
                        } label: {
                            DoorView(
                                number: number,
                                door: opened.contains(number) ? AdventCalendar.doors[number - 1] : nil,
                                isToday: number == today && !opened.contains(number),
                                highlight: lockedTaps >= 2 && number == today && !opened.contains(number)
                            )
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel(opened.contains(number) ? AdventCalendar.doors[number - 1].title : "Tür \(number)")
                    }
                }
                .frame(maxWidth: 560 * scale)
                Spacer(minLength: 0)
            }
            .padding()

            if let door = shownDoor {
                OpenedDoorView(door: door) {
                    withAnimation(.spring()) { shownDoor = nil }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear(perform: speakIntro)
    }

    private func speakIntro() {
        if today <= 24 && !opened.contains(today) {
            Speaker.shared.say("\(AdventCalendar.intro) \(AdventCalendar.findDoor(today))")
        } else if today <= 24 {
            Speaker.shared.say("\(AdventCalendar.intro) \(AdventCalendar.alreadyOpenedToday)")
        } else {
            Speaker.shared.say(AdventCalendar.intro)
        }
    }

    private func tap(_ number: Int) {
        guard number <= lastOpenable else {
            lockedTaps += 1
            Haptics.soft()
            Speaker.shared.say("\(AdventCalendar.lockedDoor) \(AdventCalendar.sleepsUntil(number - today))")
            return
        }
        let door = AdventCalendar.doors[number - 1]
        if !opened.contains(number) {
            AdventCalendar.markOpened(number)
            opened.insert(number)
            Haptics.success()
        }
        lockedTaps = 0
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { shownDoor = door }
        Speaker.shared.say(door.spoken)
    }
}

private struct DoorView: View {
    let number: Int
    let door: AdventDoor?
    let isToday: Bool
    let highlight: Bool

    @Environment(\.layoutScale) private var scale
    @State private var pulse = false

    private var color: Color {
        let colors = [Color(red: 0.80, green: 0.18, blue: 0.20), Color(red: 0.15, green: 0.50, blue: 0.30), Color(red: 0.85, green: 0.62, blue: 0.15)]
        return colors[number % colors.count]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(door == nil ? color : Color.white)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
            if let door {
                Text(door.emoji)
                    .font(.system(size: 34 * scale))
            } else {
                Text("\(number)")
                    .font(.system(size: 28 * scale, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(highlight ? Color.yellow : Color.white.opacity(isToday ? 0.9 : 0), lineWidth: highlight ? 5 : 3)
        )
        .scaleEffect(highlight && pulse ? 1.08 : 1)
        .onChange(of: highlight) { active in
            if active {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulse = true }
            } else {
                pulse = false
            }
        }
    }
}

/// Die geöffnete Tür groß: Bild, Zahl und die Mitmach-Idee zum Nochmal-Anhören.
private struct OpenedDoorView: View {
    let door: AdventDoor
    let onClose: () -> Void

    @Environment(\.layoutScale) private var scale

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture(perform: onClose)
            VStack(spacing: 18 * scale) {
                Text("\(door.number)")
                    .font(.system(size: 22 * scale, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 44 * scale, height: 44 * scale)
                    .background(Circle().fill(Color(red: 0.80, green: 0.18, blue: 0.20)))
                Button {
                    Speaker.shared.say(door.spoken)
                } label: {
                    VStack(spacing: 6) {
                        Text(door.emoji)
                            .font(.system(size: 120 * scale))
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 22 * scale))
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(door.spoken)
                RoundIconButton(systemName: "checkmark", tint: Color(red: 0.15, green: 0.50, blue: 0.30), size: 72, action: onClose)
                    .accessibilityLabel("Schließen")
            }
            .padding(32)
            .cardBackground(cornerRadius: 36)
            .padding()
        }
    }
}
