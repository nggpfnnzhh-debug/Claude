import Foundation

/// Feste Sätze der App – gesprochen von „Huhu“, der Eule.
/// Alle gesprochenen Sätze sind als Audioaufnahmen hinterlegt
/// (siehe `scripts/voice/generate.py`) – neue Sätze dort ebenfalls eintragen.
enum Lines {
    static let owlIntro = "Huhu! Ich bin Huhu, die Eule."
    static let homeQuestion = "Was möchtest du heute mit mir spielen?"
    static let homeGreeting = "Huhu! \(homeQuestion)"
    /// Zurück aus einem Spiel – keine erneute Begrüßung.
    static let homeNext = "Was möchtest du als Nächstes spielen?"
    static let pickerQuestion = "Wer bist du? Such dir einen Namen aus!"
    static let celebrationPlain = "Super gemacht!"
    static let celebrationStar = "Huhu freut sich! Ein neuer Stern für deinen Sternenhimmel!"
    static let starSky = "Schau mal, so viele Sterne leuchten schon für dich!"
    static let memoryInstruction = "Finde die Paare! Tippe auf zwei Karten."
    static let memoryPair = "Ein Paar! Super!"
    static let breakTime = "Zeit für eine Pause! Huhu macht jetzt ein Nickerchen. Bis später!"
    /// Nach zwei Fehlversuchen hilft Huhu, statt das Kind raten zu lassen.
    static let hint = "Huhu hilft dir. Schau mal hier!"
    static let countingHint = "Wir zählen zusammen!"

    static func hello(_ spokenName: String) -> String { "Huhu, \(spokenName)!" }
    static func celebration(_ spokenName: String) -> String { "Super gemacht, \(spokenName)!" }

    static let fixed = [
        owlIntro, homeQuestion, homeGreeting, homeNext, pickerQuestion, celebrationPlain, celebrationStar,
        starSky, memoryInstruction, memoryPair, breakTime, hint, countingHint,
    ]
}
