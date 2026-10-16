import Foundation

/// Startparameter für automatisch erzeugte App-Store-Screenshots,
/// z. B. `-screenshot counting` öffnet direkt das Zählspiel.
enum LaunchOptions {
    static var screenshotScreen: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    static var screenshotGame: Game? {
        screenshotScreen.flatMap(Game.init(rawValue:))
    }

    /// Zeigt auf dem Startbildschirm ein paar gesammelte Sterne, damit die Screenshots lebendig wirken.
    static func prepareScreenshotModeIfNeeded() {
        guard screenshotScreen != nil else { return }
        let demoStars = ["counting": 4, "colors": 3, "shapes": 2, "letters": 3, "patterns": 1, "memory": 2]
        UserDefaults.standard.set(demoStars, forKey: "starsByGame")
        UserDefaults.standard.set(0, forKey: SettingsKey.breakMinutes)
        UserDefaults.standard.set("Biene", forKey: SettingsKey.childName)
        UserDefaults.standard.set("Kleine", forKey: SettingsKey.childAdjective)
        UserDefaults.standard.set("🐝", forKey: SettingsKey.childEmoji)
    }
}
