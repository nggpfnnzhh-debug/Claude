import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var pendingTest: ExperimentKind?

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.homePath) {
            Page {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lernlabor").font(.display)
                    Text("Finde mit kleinen Versuchen an dir selbst heraus, wie du am besten lernst.")
                        .foregroundStyle(Theme.muted)
                }

                ForEach(model.pendingRuns.filter { Date.now >= $0.dueDate }) { pending in
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow("Wartet auf dich")
                        Text("Dein Selbstversuch „\(pending.kind.shortTitle)“ ist bereit für den Test.")
                        Button("Jetzt testen") { pendingTest = pending.kind }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .card()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Schritt 1")
                    NavigationLink(value: HomeRoute.testIntro) {
                        EntryRow(title: "Lerne deine Tiere kennen",
                                 subtitle: model.personality == nil ? "20 Aussagen zu deiner Persönlichkeit" : "Erledigt. Nochmal machen?",
                                 meta: "4 Min") {
                            AnimalIcon(trait: .conscientiousness, size: 30)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Schritt 2")
                    Button { model.selectedTab = .lab } label: {
                        EntryRow(title: "Selbstversuche im Labor",
                                 subtitle: "Was bleibt bei dir besser hängen?",
                                 meta: "10 Min") {
                            Image(systemName: "testtube.2").font(.title).foregroundStyle(Theme.accent)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Zwischendurch")
                    Button { model.selectedTab = .knowledge } label: {
                        EntryRow(title: "Mythen-Check",
                                 subtitle: "8 Lern-Mythen, was die Forschung sagt",
                                 meta: "3 Min") {
                            Image(systemName: "lightbulb").font(.title).foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .testIntro: TestIntroView()
                case .test: PersonalityTestView()
                case .result: PersonalityResultView()
                }
            }
            .fullScreenCover(item: $pendingTest) { kind in
                ExperimentFlowView(kind: kind, pending: model.pending(kind))
            }
        }
    }
}
