import StoreKit
import SwiftUI

struct MythsView: View {
    @State private var openID: Int?

    var body: some View {
        NavigationStack {
            Page {
                Text("Mythen-Check").font(.display)
                Text("Stimmt das? Tipp auf eine Aussage für die Auflösung.").foregroundStyle(Theme.muted)
                ForEach(Myth.all) { myth in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { openID = openID == myth.id ? nil : myth.id }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(myth.claim).font(.body.weight(.semibold))
                            if openID == myth.id {
                                Text(myth.verdict.label)
                                    .font(.caption.monospaced().weight(.semibold))
                                    .foregroundStyle(color(for: myth.verdict))
                                Text(myth.explanation).font(.subheadline)
                            } else {
                                Text("Antippen zum Auflösen").font(.subheadline).foregroundStyle(Theme.muted)
                            }
                        }
                        .multilineTextAlignment(.leading)
                        .card()
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                if LaunchOptions.screenshotScreen == "myths" { openID = 1 }
            }
        }
    }

    private func color(for verdict: Myth.Verdict) -> Color {
        switch verdict {
        case .wrong: return Theme.bad
        case .partly: return Theme.beaver
        case .right: return Theme.good
        }
    }
}

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @Environment(Purchases.self) private var purchases
    @State private var showPremium = false
    @State private var showRedeem = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Page {
                Text("Mein Lernprofil").font(.display)

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Eyebrow("Persönlichkeit")
                        Spacer()
                        if model.personality == nil {
                            Text("BEISPIEL").font(.caption.monospaced()).foregroundStyle(Theme.muted)
                        }
                    }
                    ForEach(Trait.displayOrder) { trait in
                        AnimalBarRow(trait: trait, score: model.scores[trait] ?? 50)
                    }
                    if model.personality == nil {
                        Button("Eigene Tiere herausfinden") {
                            model.selectedTab = .start
                            model.homePath = [.testIntro]
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Tipps ansehen") {
                            model.selectedTab = .start
                            model.homePath = [.result]
                        }
                        .font(.subheadline.weight(.medium))
                    }
                }
                .card()

                measurements

                fullVersionCard

                if purchases.isTestEnvironment {
                    testModeCard
                }

                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow("Käufe")
                    Button("Code einlösen") { showRedeem = true }
                    Button("Käufe wiederherstellen") { Task { await purchases.restore() } }
                        .disabled(purchases.isWorking)
                    if let message = purchases.message {
                        Text(message).font(.footnote).foregroundStyle(Theme.muted)
                    }
                }
                .font(.body.weight(.medium))
                .card()

                Text("Deine Daten bleiben auf diesem Gerät. Kein Konto, keine Werbung, kein Tracking.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)

                if model.personality != nil || !model.runs.isEmpty || !model.pendingRuns.isEmpty {
                    Button("Alle Daten löschen", role: .destructive) { confirmReset = true }
                        .font(.subheadline.weight(.medium))
                }
            }
            .sheet(isPresented: $showPremium) { PremiumView() }
            .offerCodeRedemption(isPresented: $showRedeem) { _ in
                Task { await purchases.refresh() }
            }
            .confirmationDialog("Alle Daten löschen?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) { model.resetAll() }
            } message: {
                Text("Persönlichkeitsergebnis und alle Selbstversuche auf diesem Gerät werden entfernt. Deine Vollversion bleibt erhalten.")
            }
        }
    }

    @ViewBuilder
    private var measurements: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Gemessen in Selbstversuchen")
            if !model.runs.isEmpty {
                ForEach(ExperimentKind.allCases) { kind in
                    let runs = model.runs(of: kind)
                    if let last = runs.last {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("**\(kind.shortTitle):** \(scoreLine(last))")
                            Text(Experiments.verdict(for: last).title + averageText(runs))
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                        }
                    }
                }
            } else {
                Text("Noch keine Messung. Hier erscheint, was bei dir tatsächlich wirkt.")
                    .foregroundStyle(Theme.muted)
                Button("Ersten Selbstversuch starten") { model.selectedTab = .lab }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .card()
    }

    private func scoreLine(_ run: ExperimentRun) -> String {
        let parts = run.kind.methods.map { "\($0.resultLabel.lowercased()) \(run.correct($0))/\(run.kind.perMethod)" }
        return parts.joined(separator: ", ") + (run.delayed ? " (nach Pause)" : " (Sofort-Test)")
    }

    private func averageText(_ runs: [ExperimentRun]) -> String {
        guard runs.count > 1, let kind = runs.first?.kind else { return "" }
        let parts = kind.methods.map { method in
            let average = Double(runs.map { $0.correct(method) }.reduce(0, +)) / Double(runs.count)
            return "\(method.resultLabel.lowercased()) \(average.formatted(.number.precision(.fractionLength(1))))"
        }
        return " Durchschnitt aus \(runs.count) Durchgängen: " + parts.joined(separator: ", ") + "."
    }

    private var testModeCard: some View {
        @Bindable var purchases = purchases
        return VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Testmodus")
            Toggle("Vollversion simulieren", isOn: $purchases.simulateFullVersion)
                .font(.body.weight(.medium))
                .tint(Theme.accent)
            Text("Nur in Testversionen (TestFlight) sichtbar. So lässt sich alles ausprobieren, ohne zu kaufen.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .card()
    }

    @ViewBuilder
    private var fullVersionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Vollversion")
            if purchases.hasFullVersion {
                Text("Freigeschaltet. Danke!").font(.subheading)
                Text("Weitere Selbstversuche kommen mit den nächsten Updates.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            } else if purchases.unlocked {
                Text("Im Testmodus freigeschaltet").font(.subheading)
            } else {
                Text("Alle Selbstversuche und dein vollständiges Profil").font(.subheading)
                Button("Mehr erfahren") { showPremium = true }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .card()
    }
}

struct PremiumView: View {
    @Environment(Purchases.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @State private var showRedeem = false

    var body: some View {
        NavigationStack {
            Page {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Lernlabor Vollversion")
                    Text("Finde heraus, was bei dir wirklich wirkt").font(.heading)
                }
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Selbstversuch „Erklären oder Lesen?“ und alle weiteren, die mit Updates dazukommen", systemImage: "testtube.2")
                        Label("Vollständiges Lernprofil aus Persönlichkeit und echten Messungen", systemImage: "person.text.rectangle")
                        Label("Die wichtigsten Lernmethoden mit Übungen", systemImage: "graduationcap")
                    }
                    if purchases.hasFullVersion {
                        Label("Vollversion freigeschaltet", systemImage: "checkmark.seal.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.good)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(purchases.product?.displayPrice ?? "…").font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("einmalig, kein Abo").font(.subheadline).foregroundStyle(Theme.muted)
                        }
                        Button("Vollversion freischalten") { Task { await purchases.buy() } }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(purchases.isWorking || purchases.product == nil)
                    }
                    if let message = purchases.message {
                        Text(message).font(.footnote).foregroundStyle(Theme.muted)
                    }
                }
                .card()

                HStack {
                    Button("Code einlösen") { showRedeem = true }
                    Spacer()
                    Button("Käufe wiederherstellen") { Task { await purchases.restore() } }
                        .disabled(purchases.isWorking)
                }
                .font(.subheadline.weight(.medium))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
            .offerCodeRedemption(isPresented: $showRedeem) { _ in
                Task { await purchases.refresh() }
            }
        }
    }
}
