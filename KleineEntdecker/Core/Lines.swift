import Foundation

/// Feste Sätze der App – gesprochen von „Huhu“, der Eule.
/// Alle gesprochenen Sätze sind als Audioaufnahmen hinterlegt
/// (siehe `scripts/voice/generate.py`) – neue Sätze dort ebenfalls eintragen.
enum Lines {
    static let owlIntro = "Huhu! Ich bin Huhu, die Eule."
    static let homeQuestion = "Was möchtest du heute mit mir spielen?"
    static let homeGreeting = "Huhu! \(homeQuestion)"
    static let pickerQuestion = "Wer bist du? Such dir einen Namen aus!"
    static let celebrationPlain = "Super gemacht!"
    static let celebrationStar = "Huhu freut sich! Du hast einen Stern bekommen!"
    static let memoryInstruction = "Finde die Paare! Tippe auf zwei Karten."
    static let memoryPair = "Ein Paar! Super!"
    static let breakTime = "Zeit für eine Pause! Huhu macht jetzt ein Nickerchen. Bis später!"
    static let voicePreview = "Huhu! Wie viele Äpfel siehst du? Toll gemacht!"

    static func hello(_ spokenName: String) -> String { "Huhu, \(spokenName)!" }
    static func celebration(_ spokenName: String) -> String { "Super gemacht, \(spokenName)!" }

    static let fixed = [
        owlIntro, homeQuestion, homeGreeting, pickerQuestion, celebrationPlain, celebrationStar,
        memoryInstruction, memoryPair, breakTime, voicePreview,
    ]
}
