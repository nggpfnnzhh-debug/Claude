import Foundation

/// Ergebnis einer Runde: wie viele Aufgaben beim ersten Versuch gelöst wurden.
struct RoundResult: Codable, Equatable {
    let firstTry: Int
    let total: Int

    var rate: Double { total > 0 ? Double(firstTry) / Double(total) : 0 }
}

/// Speichert Sterne, Schwierigkeitsstufen und die letzten Rundenergebnisse pro Spiel –
/// ausschließlich lokal auf dem Gerät.
final class ProgressStore: ObservableObject {
    @Published private(set) var stars: [String: Int]
    @Published private(set) var levels: [String: Int]
    @Published private(set) var results: [String: [RoundResult]]

    /// So viele Runden fließen in Stufe und Fördertipps ein.
    static let rememberedRounds = 5
    /// Ab so vielen Runden gibt es eine Einschätzung für die Fördertipps.
    static let minimumRoundsForTips = 2

    private let defaults: UserDefaults
    private let starsKey = "starsByGame"
    private let levelsKey = "levelsByGame"
    private let resultsKey = "resultsByGame"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        stars = defaults.dictionary(forKey: starsKey) as? [String: Int] ?? [:]
        levels = defaults.dictionary(forKey: levelsKey) as? [String: Int] ?? [:]
        if let data = defaults.data(forKey: resultsKey),
           let decoded = try? JSONDecoder().decode([String: [RoundResult]].self, from: data) {
            results = decoded
        } else {
            results = [:]
        }
    }

    var totalStars: Int { stars.values.reduce(0, +) }

    func stars(for game: Game) -> Int {
        stars[game.rawValue] ?? 0
    }

    func level(for game: Game) -> Int {
        min(max(levels[game.rawValue] ?? 0, 0), game.maxLevel)
    }

    /// Durchschnittliche Quote „beim ersten Versuch richtig“ – `nil`, solange zu wenig gespielt wurde.
    func firstTryRate(for game: Game) -> Double? {
        let rounds = results[game.rawValue] ?? []
        guard rounds.count >= Self.minimumRoundsForTips else { return nil }
        return rounds.map(\.rate).reduce(0, +) / Double(rounds.count)
    }

    /// Spiele, bei denen gemeinsames Üben besonders hilft, zuerst.
    func gamesForTips() -> [Game] {
        Game.allCases.sorted { a, b in
            (firstTryRate(for: a) ?? 1) < (firstTryRate(for: b) ?? 1)
        }
    }

    func needsPractice(_ game: Game) -> Bool {
        guard let rate = firstTryRate(for: game) else { return false }
        return rate < 0.6
    }

    /// Nach jeder vollständigen Runde: Stern vergeben, Ergebnis merken, Stufe anpassen.
    func completeRound(for game: Game, result: RoundResult) {
        stars[game.rawValue, default: 0] += 1

        var rounds = results[game.rawValue] ?? []
        rounds.append(result)
        results[game.rawValue] = Array(rounds.suffix(Self.rememberedRounds))

        let current = level(for: game)
        if result.rate >= 0.8, current < game.maxLevel {
            levels[game.rawValue] = current + 1
        } else if result.rate < 0.5, current > 0 {
            levels[game.rawValue] = current - 1
        }
        save()
    }

    func reset() {
        stars = [:]
        levels = [:]
        results = [:]
        defaults.removeObject(forKey: starsKey)
        defaults.removeObject(forKey: levelsKey)
        defaults.removeObject(forKey: resultsKey)
    }

    private func save() {
        defaults.set(stars, forKey: starsKey)
        defaults.set(levels, forKey: levelsKey)
        if let data = try? JSONEncoder().encode(results) {
            defaults.set(data, forKey: resultsKey)
        }
    }
}
