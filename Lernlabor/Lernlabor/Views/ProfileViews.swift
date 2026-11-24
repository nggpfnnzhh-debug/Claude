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

                if model.personality != nil || !model.runs.isEmpty || model.pendingRun != nil {
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
            if let last = model.runs.last {
                let reread = last.correct(.reread)
                let quiz = last.correct(.quiz)
                Text("**Lesen oder Abfragen:** gelesen \(reread)/8, abgefragt \(quiz)/8 \(last.delayed ? "(nach Pause)" : "(Sofort-Test)").")
                Text(RereadVsQuiz.verdict(reread: reread, quiz: quiz).title + averageText)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            } else {
                Text("Noch keine Messung. Hier erscheint, was bei dir tatsächlich wirkt.")
                    .foregroundStyle(Theme.muted)
                Button("Ersten Selbstversuch starten") { model.selectedTab = .lab }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .card()
    }

    private var averageText: String {
        let runs = model.runs
        guard runs.count > 1 else { return "" }
        let reread = Double(runs.map { $0.correct(.reread) }.reduce(0, +)) / Double(runs.count)
        let quiz = Double(runs.map { $0.correct(.quiz) }.reduce(0, +)) / Double(runs.count)
        return " Durchschnitt aus \(runs.count) Durchgängen: gelesen \(reread.formatted(.number.precision(.fractionLength(1)))), abgefragt \(quiz.formatted(.number.precision(.fractionLength(1))))."
    }

    @ViewBuilder
    private var fullVersionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Vollversion")
            if purchases.hasFullVersion {
                Text("Freigeschaltet. Danke!").font(.subheading)
                Text("Die weiteren Selbstversuche kommen mit den nächsten Updates.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
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
                        Label("Weitere Selbstversuche, zum Beispiel verteilt gegen am Stück, Erklären gegen Lesen, Lerche oder Eule", systemImage: "testtube.2")
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
