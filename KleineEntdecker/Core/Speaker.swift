import AVFoundation
import UIKit

/// Liest Anweisungen und Lob auf Deutsch vor – Kinder im Vorschulalter können noch nicht lesen.
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    /// Alle installierten deutschen Stimmen, die natürlichste zuerst (Premium vor Erweitert vor Standard).
    static var germanVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("de") && !isNovelty($0) }
            .sorted { rank($0) > rank($1) }
    }

    /// Die vom Elternteil gewählte Stimme oder – automatisch – die beste installierte.
    static var currentVoice: AVSpeechSynthesisVoice? {
        if let identifier = UserDefaults.standard.string(forKey: SettingsKey.voiceIdentifier),
           !identifier.isEmpty,
           let chosen = AVSpeechSynthesisVoice(identifier: identifier) {
            return chosen
        }
        return germanVoices.first ?? AVSpeechSynthesisVoice(language: "de-DE")
    }

    static func qualityLabel(_ voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .premium: return "Premium"
        case .enhanced: return "Erweitert"
        default: return "Standard"
        }
    }

    private static func rank(_ voice: AVSpeechSynthesisVoice) -> Int {
        let quality: Int
        switch voice.quality {
        case .premium: quality = 30
        case .enhanced: quality = 20
        default: quality = 10
        }
        // Bei gleicher Qualität Hochdeutsch (de-DE) bevorzugen.
        return quality + (voice.language == "de-DE" ? 1 : 0)
    }

    /// Spaßstimmen wie „Grandma“ oder „Bubbles“ sind für Lernansagen ungeeignet.
    private static func isNovelty(_ voice: AVSpeechSynthesisVoice) -> Bool {
        if #available(iOS 17.0, *) {
            return voice.voiceTraits.contains(.isNoveltyVoice)
        }
        return false
    }

    /// - Parameter interrupt: `false` hängt den Text an das gerade Gesprochene an.
    func say(_ text: String, interrupt: Bool = true) {
        let enabled = UserDefaults.standard.object(forKey: SettingsKey.speechEnabled) as? Bool ?? true
        guard enabled else { return }
        speak(text, voice: Self.currentVoice, interrupt: interrupt)
    }

    /// Spielt eine Hörprobe ab – auch wenn die Sprachausgabe gerade ausgeschaltet ist.
    func preview(voice: AVSpeechSynthesisVoice?) {
        speak("Hallo! Wie viele Äpfel siehst du? Toll gemacht!", voice: voice ?? Self.currentVoice, interrupt: true)
    }

    private func speak(_ text: String, voice: AVSpeechSynthesisVoice?, interrupt: Bool) {
        if interrupt, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // Natürliche Tonhöhe; nur etwas ruhiger als normal, damit Kinder gut folgen können.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.15
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
