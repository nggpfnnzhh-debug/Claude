import Foundation

/// Ein Spitzname, den sich das Kind selbst aussuchen kann, z. B. „Kleine Biene“.
struct Nickname: Identifiable {
    let name: String
    let emoji: String
    /// Passend zum grammatischen Geschlecht: „Kleiner“, „Kleine“ oder „Kleines“.
    let adjective: String

    var id: String { name }
    var title: String { "\(adjective) \(name)" }
}

enum ChildProfile {
    static let defaultTitle = "Kleine Entdecker"
    static let defaultEmoji = "🦉"
    static let adjectives = ["Kleiner", "Kleine", "Kleines"]
    static let maxNameLength = 15

    static let nicknames: [Nickname] = [
        Nickname(name: "Biene", emoji: "🐝", adjective: "Kleine"),
        Nickname(name: "Bär", emoji: "🐻", adjective: "Kleiner"),
        Nickname(name: "Fuchs", emoji: "🦊", adjective: "Kleiner"),
        Nickname(name: "Maus", emoji: "🐭", adjective: "Kleine"),
        Nickname(name: "Drache", emoji: "🐲", adjective: "Kleiner"),
        Nickname(name: "Einhorn", emoji: "🦄", adjective: "Kleines"),
        Nickname(name: "Pinguin", emoji: "🐧", adjective: "Kleiner"),
        Nickname(name: "Eule", emoji: "🦉", adjective: "Kleine"),
        Nickname(name: "Tiger", emoji: "🐯", adjective: "Kleiner"),
        Nickname(name: "Katze", emoji: "🐱", adjective: "Kleine"),
        Nickname(name: "Frosch", emoji: "🐸", adjective: "Kleiner"),
        Nickname(name: "Dino", emoji: "🦕", adjective: "Kleiner"),
        Nickname(name: "Hase", emoji: "🐰", adjective: "Kleiner"),
        Nickname(name: "Löwe", emoji: "🦁", adjective: "Kleiner"),
        Nickname(name: "Schildkröte", emoji: "🐢", adjective: "Kleine"),
    ]

    /// Überschrift auf dem Startbildschirm, z. B. „Kleiner Max“.
    static func title(name: String, adjective: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultTitle : "\(adjective) \(trimmed)"
    }

    /// Für die Sprachausgabe mitten im Satz, z. B. „kleiner Max“ – oder `nil`, wenn kein Name gesetzt ist.
    static func spokenName(name: String, adjective: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : "\(adjective.lowercased()) \(trimmed)"
    }

    static var currentSpokenName: String? {
        let defaults = UserDefaults.standard
        return spokenName(
            name: defaults.string(forKey: SettingsKey.childName) ?? "",
            adjective: defaults.string(forKey: SettingsKey.childAdjective) ?? "Kleine"
        )
    }
}
