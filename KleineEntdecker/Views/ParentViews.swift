import SwiftUI

/// Elternschranke (Apple-Vorgabe für die Kategorie „Kinder"): eine Rechenaufgabe,
/// die ein Vorschulkind nicht lösen kann. Eingabe über eigene Tasten statt Systemtastatur.
struct ParentGateView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var a = Int.random(in: 6...9)
    @State private var b = Int.random(in: 3...9)
    @State private var input = ""
    @State private var showError = false

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "OK"]

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                Button("Abbrechen", action: onCancel)
            }
            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("Nur für Eltern")
                .font(.title2.bold())
            Text("Bitte löse die Aufgabe, um fortzufahren.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text("Wie viel ist \(a) × \(b)?")
                .font(.title.bold())
            Text(input.isEmpty ? " " : input)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .frame(minWidth: 140)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.4), lineWidth: 2))
            Text(showError ? "Leider falsch – hier ist eine neue Aufgabe." : " ")
                .font(.footnote)
                .foregroundColor(.red)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(keys, id: \.self) { key in
                    Button {
                        press(key)
                    } label: {
                        Text(key)
                            .font(.title2.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(key == "⌫" ? "Löschen" : key)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: 420)
        .onAppear { Speaker.shared.stop() }
    }

    private func press(_ key: String) {
        switch key {
        case "⌫":
            if !input.isEmpty { input.removeLast() }
        case "OK":
            check()
        default:
            if input.count < 3 { input.append(key) }
        }
    }

    private func check() {
        if Int(input) == a * b {
            onSuccess()
        } else {
            input = ""
            showError = true
            a = Int.random(in: 6...9)
            b = Int.random(in: 3...9)
        }
    }
}

struct ParentArea: View {
    @State private var unlocked = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if unlocked {
            ParentSettingsView()
        } else {
            ParentGateView(onSuccess: { unlocked = true }, onCancel: { dismiss() })
        }
    }
}

struct ParentSettingsView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.speechEnabled) private var speechEnabled = true
    @AppStorage(SettingsKey.seasonalThemes) private var seasonalThemes = true
    @AppStorage(SettingsKey.breakMinutes) private var breakMinutes = SettingsDefault.breakMinutes
    @AppStorage(SettingsKey.childName) private var childName = ""
    @AppStorage(SettingsKey.childAdjective) private var childAdjective = "Kleine"
    @AppStorage(SettingsKey.childEmoji) private var childEmoji = ChildProfile.defaultEmoji
    @State private var confirmReset = false

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name, z. B. Max", text: $childName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    Picker("Anrede", selection: $childAdjective) {
                        ForEach(ChildProfile.adjectives, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Anzeige")
                        Spacer()
                        Text("\(childEmoji) \(ChildProfile.title(name: childName, adjective: childAdjective))")
                            .foregroundColor(.secondary)
                    }
                    if !childName.isEmpty {
                        Button("Name entfernen", role: .destructive) {
                            childName = ""
                            childEmoji = ChildProfile.defaultEmoji
                        }
                    }
                } header: {
                    Text("Name des Kindes")
                } footer: {
                    Text("Ihr Kind kann sich auch selbst einen Tiernamen aussuchen: auf dem Startbildschirm oben links tippen. Tiernamen spricht Huhu laut aus; ein hier eingetippter Name wird nur angezeigt. Der Name bleibt auf diesem Gerät.")
                }
                .onChange(of: childName) { newValue in
                    if newValue.count > ChildProfile.maxNameLength {
                        childName = String(newValue.prefix(ChildProfile.maxNameLength))
                    }
                }

                Section {
                    ForEach(progress.gamesForTips()) { game in
                        TipsRow(game: game, needsPractice: progress.needsPractice(game))
                    }
                } header: {
                    Text("Ideen zum gemeinsamen Üben")
                } footer: {
                    Text("Die App merkt sich nur auf diesem Gerät, wie oft Ihr Kind beim ersten Versuch richtig liegt, und passt die Schwierigkeit daran an. Kurze Spielrunden sind keine Diagnose – jedes Kind entwickelt sich in seinem eigenen Tempo.")
                }

                Section {
                    Toggle("Sprachausgabe", isOn: $speechEnabled)
                    Toggle("Feste & Jahreszeiten", isOn: $seasonalThemes)
                    Picker("Pausen-Erinnerung", selection: $breakMinutes) {
                        Text("Aus").tag(0)
                        ForEach([10, 15, 20, 30], id: \.self) { minutes in
                            Text("nach \(minutes) Minuten").tag(minutes)
                        }
                    }
                } header: {
                    Text("Einstellungen")
                } footer: {
                    Text("Die Pausen-Erinnerung unterbricht das Spiel freundlich. Weiterspielen ist nur über die Elternschranke möglich. Kurze Einheiten von 10–15 Minuten sind in diesem Alter ideal.\n\n„Feste & Jahreszeiten“ schmückt die App passend zum Datum, z. B. mit fallenden Blättern im Herbst oder Kürbissen zu Halloween, und bringt passende Motive in die Spiele.")
                }

                Section("Was lernt mein Kind?") {
                    ForEach(Game.allCases) { game in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(game.icon)  \(game.title)").font(.headline)
                            Text(game.parentInfo)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    HStack {
                        Text("Gesammelte Sterne")
                        Spacer()
                        Text("\(progress.totalStars) ⭐️").foregroundColor(.secondary)
                    }
                    Button("Fortschritt zurücksetzen", role: .destructive) {
                        confirmReset = true
                    }
                } header: {
                    Text("Fortschritt")
                } footer: {
                    Text("Für jede geschaffte Runde leuchtet ein Stern in Huhus Sternenhimmel – unabhängig davon, wie viele Versuche Ihr Kind gebraucht hat.")
                }

                Section("Datenschutz") {
                    Text("Keine Werbung, keine In-App-Käufe, keine Links nach außen, kein Tracking. Es werden keine Daten erhoben oder übertragen – Fortschritt und Name bleiben auf diesem Gerät.")
                        .font(.subheadline)
                }

                Section("Über die App") {
                    Text("Die Stimme von Huhu ist eine künstliche Stimme, erzeugt mit der Sprachsynthese von Microsoft Azure. Alle Sätze sind fest in der App enthalten – es wird nichts übers Internet geladen.")
                        .font(.subheadline)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Elternbereich")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .confirmationDialog("Fortschritt löschen?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Zurücksetzen", role: .destructive) { progress.reset() }
            } message: {
                Text("Sterne, Schwierigkeitsstufen und Übungsergebnisse werden gelöscht.")
            }
        }
    }
}

/// Fördertipps für ein Spiel. Spiele mit Übungsbedarf stehen oben und sind freundlich markiert.
private struct TipsRow: View {
    let game: Game
    let needsPractice: Bool

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(game.tips, id: \.self) { tip in
                    Label(tip, systemImage: "lightbulb")
                        .font(.subheadline)
                }
            }
            .padding(.vertical, 4)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(game.icon)  \(game.title)")
                if needsPractice {
                    Text("Hier macht gemeinsames Üben gerade besonders Spaß")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

struct BreakView: View {
    let onResume: () -> Void

    @State private var showGate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.22, blue: 0.45), Color(red: 0.35, green: 0.30, blue: 0.60)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("🦉💤")
                    .font(.system(size: 100))
                Text("Zeit für eine Pause!")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("Leg das Gerät zur Seite und spiel etwas anderes. Bis später!")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                Button {
                    showGate = true
                } label: {
                    Label("Eltern: weiterspielen", systemImage: "lock.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().stroke(Color.white.opacity(0.5)))
                }
                .padding(.top, 24)
            }
            .padding(32)
        }
        .sheet(isPresented: $showGate) {
            ParentGateView(
                onSuccess: {
                    showGate = false
                    onResume()
                },
                onCancel: { showGate = false }
            )
        }
    }
}
