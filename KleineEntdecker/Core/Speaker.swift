import AVFoundation
import UIKit

/// Liest Anweisungen und Lob auf Deutsch vor – Kinder im Vorschulalter können noch nicht lesen.
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "de-DE")

    private init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    /// - Parameter interrupt: `false` hängt den Text an das gerade Gesprochene an.
    func say(_ text: String, interrupt: Bool = true) {
        let enabled = UserDefaults.standard.object(forKey: SettingsKey.speechEnabled) as? Bool ?? true
        guard enabled else { return }
        if interrupt, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.1
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

enum Phrases {
    static let praise = ["Super!", "Toll gemacht!", "Richtig!", "Klasse!", "Prima!", "Genau!", "Wunderbar!"]
    static let retry = ["Fast! Versuch es nochmal.", "Schau noch einmal genau hin.", "Probier ein anderes!"]
    static let numberWords = ["null", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn"]

    static var randomPraise: String { praise.randomElement() ?? "Super!" }
    static var randomRetry: String { retry.randomElement() ?? "Versuch es nochmal." }
}
