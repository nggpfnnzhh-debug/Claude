import Foundation
import Observation
import UserNotifications

enum AppTab: Hashable {
    case start, lab, knowledge, profile
}

enum HomeRoute: Hashable {
    case testIntro, test, result
}

/// Hält Persönlichkeitsergebnis und Selbstversuche. Alles bleibt auf dem Gerät (UserDefaults).
@Observable
@MainActor
final class AppModel {
    var selectedTab: AppTab = .start
    var homePath: [HomeRoute] = []

    private(set) var personality: PersonalityResult?
    /// Gelernt, aber noch nicht getestet (höchstens einer pro Selbstversuch)
    private(set) var pendingRuns: [ExperimentRun] = []
    private(set) var runs: [ExperimentRun] = []

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let persists: Bool

    private enum Key {
        static let personality = "personality"
        static let pendingRuns = "pendingRuns"
        static let runs = "runs"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let screen = LaunchOptions.screenshotScreen {
            persists = false
            applyDemo(for: screen)
        } else {
            persists = true
            personality = load(PersonalityResult.self, key: Key.personality)
            pendingRuns = load([ExperimentRun].self, key: Key.pendingRuns) ?? []
            runs = load([ExperimentRun].self, key: Key.runs) ?? []
        }
    }

    /// Prozentränge des eigenen Ergebnisses oder das Beispielprofil
    var scores: [Trait: Int] { personality?.scores ?? PersonalityTest.example }

    func savePersonality(answers: [Int?]) {
        personality = PersonalityResult(means: PersonalityTest.means(answers: answers), date: .now)
        save(personality, key: Key.personality)
    }

    func pending(_ kind: ExperimentKind) -> ExperimentRun? {
        pendingRuns.first { $0.kind == kind }
    }

    func runs(of kind: ExperimentKind) -> [ExperimentRun] {
        runs.filter { $0.kind == kind }
    }

    func startPending(_ run: ExperimentRun) {
        pendingRuns.removeAll { $0.kind == run.kind }
        pendingRuns.append(run)
        save(pendingRuns, key: Key.pendingRuns)
    }

    func complete(_ run: ExperimentRun) {
        runs.append(run)
        save(runs, key: Key.runs)
        discardPending(run.kind)
    }

    func discardPending(_ kind: ExperimentKind) {
        pendingRuns.removeAll { $0.kind == kind }
        save(pendingRuns, key: Key.pendingRuns)
        Reminder.cancel(kind)
    }

    func resetAll() {
        personality = nil
        runs = []
        save(personality, key: Key.personality)
        save(runs, key: Key.runs)
        for kind in ExperimentKind.allCases { discardPending(kind) }
    }

    // MARK: - Speichern

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T?, key: String) {
        guard persists else { return }
        if let value, let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Beispieldaten für Screenshots

    private func applyDemo(for screen: String) {
        personality = PersonalityResult(
            means: [.conscientiousness: 3.0, .extraversion: 3.8, .openness: 4.3, .agreeableness: 4.2, .calmness: 3.1],
            date: .now)
        runs = ExperimentKind.allCases.map { kind in
            var assignment: [String: Method] = [:]
            var results: [String: Bool] = [:]
            for (index, item) in kind.items.enumerated() {
                let first = index < kind.perMethod
                assignment[item.id] = first ? kind.methods[0] : kind.methods[1]
                results[item.id] = first ? index % 2 == 0 : index != kind.perMethod + 1
            }
            return ExperimentRun(kind: kind, prediction: .reread, assignment: assignment,
                                 learnedAt: .now.addingTimeInterval(-Experiments.recommendedDelay),
                                 testedAt: .now, results: results)
        }
        switch screen {
        case "result": homePath = [.result]
        case "lab", "experiment", "explain": selectedTab = .lab
        case "myths": selectedTab = .knowledge
        case "profile": selectedTab = .profile
        default: break
        }
    }
}

/// Erinnerung an den Test nach der Pause
enum Reminder {
    static func identifier(_ kind: ExperimentKind) -> String { "lernlabor.test.\(kind.rawValue)" }

    static func scheduleTest(_ kind: ExperimentKind, at date: Date) async {
        let center = UNUserNotificationCenter.current()
        let allowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard allowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "Zeit für deinen Test"
        content.body = kind == .rereadQuiz
            ? "Wie viele Suaheli-Wörter sind noch da? Der Test dauert etwa 2 Minuten."
            : "Was weißt du noch von den 12 Fakten? Der Test dauert etwa 2 Minuten."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, date.timeIntervalSinceNow), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: identifier(kind), content: content, trigger: trigger))
    }

    static func cancel(_ kind: ExperimentKind) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(kind)])
    }
}

/// Startparameter für automatisch erzeugte Screenshots, z. B. `-screenshot result`
enum LaunchOptions {
    static var screenshotScreen: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}
