import Foundation

/// Speichert die gesammelten Sterne pro Spiel – ausschließlich lokal auf dem Gerät.
final class ProgressStore: ObservableObject {
    @Published private(set) var stars: [String: Int]

    private let defaults: UserDefaults
    private let key = "starsByGame"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        stars = defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    var totalStars: Int { stars.values.reduce(0, +) }

    func stars(for game: Game) -> Int {
        stars[game.rawValue] ?? 0
    }

    func addStar(for game: Game) {
        stars[game.rawValue, default: 0] += 1
        defaults.set(stars, forKey: key)
    }

    func reset() {
        stars = [:]
        defaults.removeObject(forKey: key)
    }
}
