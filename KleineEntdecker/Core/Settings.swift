import Foundation

enum SettingsKey {
    static let speechEnabled = "speechEnabled"
    static let breakMinutes = "breakMinutes"
    static let childName = "childName"
    static let childAdjective = "childAdjective"
    static let childEmoji = "childEmoji"
    static let didAskNickname = "didAskNickname"
}

enum SettingsDefault {
    /// Kurze Einheiten sind in diesem Alter ideal – die Pausen-Erinnerung ist daher standardmäßig an.
    static let breakMinutes = 15
}
