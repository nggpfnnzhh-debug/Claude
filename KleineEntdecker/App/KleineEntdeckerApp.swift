import SwiftUI

@main
struct KleineEntdeckerApp: App {
    @StateObject private var progress: ProgressStore

    init() {
        LaunchOptions.prepareScreenshotModeIfNeeded()
        _progress = StateObject(wrappedValue: ProgressStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modifier(AdaptiveLayoutScale())
                .environmentObject(progress)
                .preferredColorScheme(.light)
        }
    }
}

/// Wechselt zwischen Startbildschirm und Spiel und blendet bei Bedarf die Pausen-Erinnerung ein.
struct RootView: View {
    @State private var activeGame: Game? = LaunchOptions.screenshotGame
    @State private var activeSeconds = 0
    @State private var showBreak = false
    @AppStorage(SettingsKey.breakMinutes) private var breakMinutes = SettingsDefault.breakMinutes
    @Environment(\.scenePhase) private var scenePhase

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if let game = activeGame {
                GameHostView(game: game) {
                    Speaker.shared.stop()
                    withAnimation(.easeInOut) { activeGame = nil }
                }
                .transition(.move(edge: .trailing))
                .zIndex(1)
            } else {
                HomeView { game in
                    withAnimation(.easeInOut) { activeGame = game }
                }
                .transition(.opacity)
            }

            if showBreak {
                BreakView {
                    activeSeconds = 0
                    withAnimation { showBreak = false }
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .onReceive(ticker) { _ in
            guard scenePhase == .active, breakMinutes > 0, !showBreak else { return }
            activeSeconds += 1
            if activeSeconds >= breakMinutes * 60 {
                withAnimation { showBreak = true }
                Speaker.shared.say(Lines.breakTime)
            }
        }
        .onChange(of: breakMinutes) { _ in
            activeSeconds = 0
        }
    }
}
