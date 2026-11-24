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
    /// Gelernt, aber noch nicht getestet
    private(set) var pendingRun: ExperimentRun?
    private(set) var runs: [ExperimentRun] = []

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let persists: Bool

    private enum Key {
        static let personality = "personality"
        static let pendingRun = "pendingRun"
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
            pendingRun = load(ExperimentRun.self, key: Key.pendingRun)
            runs = load([ExperimentRun].self, key: Key.runs) ?? []
        }
    }

    /// Prozentränge des eigenen Ergebnisses oder das Beispielprofil
    var scores: [Trait: Int] { personality?.scores ?? PersonalityTest.example }

    func savePersonality(answers: [Int?]) {
        personality = PersonalityResult(means: PersonalityTest.means(answers: answers), date: .now)
        save(personality, key: Key.personality)
    }

    func startPending(_ run: ExperimentRun) {
        pendingRun = run
        save(pendingRun, key: Key.pendingRun)
    }

    func complete(_ run: ExperimentRun) {
        runs.append(run)
        save(runs, key: Key.runs)
        discardPending()
    }

    func discardPending() {
        pendingRun = nil
        save(pendingRun, key: Key.pendingRun)
        Reminder.cancel()
    }

    func resetAll() {
        personality = nil
        runs = []
        save(personality, key: Key.personality)
        save(runs, key: Key.runs)
        discardPending()
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
        var assignment: [String: Method] = [:]
        var results: [String: Bool] = [:]
        for (index, pair) in RereadVsQuiz.words.enumerated() {
            assignment[pair.swahili] = index < RereadVsQuiz.perMethod ? .reread : .quiz
            results[pair.swahili] = index < RereadVsQuiz.perMethod ? index % 2 == 0 : index != 9
        }
        runs = [ExperimentRun(prediction: .reread, assignment: assignment,
                              learnedAt: .now.addingTimeInterval(-RereadVsQuiz.recommendedDelay),
                              testedAt: .now, results: results)]
        switch screen {
        case "result": homePath = [.result]
        case "lab", "experiment": selectedTab = .lab
        case "myths": selectedTab = .knowledge
        case "profile": selectedTab = .profile
        default: break
        }
    }
}

/// Erinnerung an den Test nach der Pause
enum Reminder {
    static let identifier = "lernlabor.test"

    static func scheduleTest(at date: Date) async {
        let center = UNUserNotificationCenter.current()
        let allowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard allowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "Zeit für deinen Test"
        content.body = "Wie viele Suaheli-Wörter sind noch da? Der Test dauert etwa 2 Minuten."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, date.timeIntervalSinceNow), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
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
