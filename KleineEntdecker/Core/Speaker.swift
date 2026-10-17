import AVFoundation
import UIKit

/// Liest Anweisungen und Lob auf Deutsch vor – Kinder im Vorschulalter können noch nicht lesen.
///
/// Standardmäßig spielt die App vorab aufgenommene Sätze der Stimme „Kerstin“ ab
/// (`voice_manifest.json` + Audiodateien im Bundle). Sätze ohne Aufnahme – etwa ein frei
/// eingetippter Name – spricht die beste installierte iPhone-Stimme.
final class Speaker: NSObject {
    static let shared = Speaker()

    /// Wert für `SettingsKey.voiceIdentifier`: eingebaute Aufnahmen verwenden.
    static let builtInVoiceID = "builtin"
    /// Wert für `SettingsKey.voiceIdentifier`: automatisch die beste iPhone-Stimme.
    static let automaticVoiceID = ""

    private enum Segment {
        case clip(URL)
        case speech(String)
    }

    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var queue: [Segment] = []
    private var isPlaying = false
    /// Wird bei jedem Abbruch erhöht, damit verspätete Rückmeldungen nichts mehr auslösen.
    private var generation = 0

    /// Satz → Dateiname der Aufnahme.
    private let clips: [String: String] = {
        guard let url = Bundle.main.url(forResource: "voice_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return manifest
    }()

    private override init() {
        super.init()
        synthesizer.delegate = self
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    // MARK: - Öffentliche Schnittstelle

    /// - Parameter interrupt: `false` hängt den Text an das gerade Gesprochene an.
    func say(_ text: String, interrupt: Bool = true) {
        let enabled = UserDefaults.standard.object(forKey: SettingsKey.speechEnabled) as? Bool ?? true
        guard enabled else { return }
        enqueue(segments(for: text, voiceID: Self.selectedVoiceID), interrupt: interrupt)
    }

    /// Spielt eine Hörprobe der gewählten Stimme ab – auch wenn die Sprachausgabe ausgeschaltet ist.
    func preview(voiceID: String) {
        enqueue(segments(for: Lines.voicePreview, voiceID: voiceID), interrupt: true, previewVoiceID: voiceID)
    }

    func stop() {
        generation += 1
        queue.removeAll()
        player?.stop()
        player = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
    }

    /// Ob für diesen Satz eine eingebaute Aufnahme existiert (für Tests).
    func hasClip(for sentence: String) -> Bool {
        guard let file = clips[sentence] else { return false }
        return Bundle.main.url(forResource: file, withExtension: nil) != nil
    }

    /// Zerlegt einen Text in Sätze – genau so sind die Aufnahmen geschnitten.
    static func sentences(in text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if ".!?".contains(character) {
                let sentence = current.trimmingCharacters(in: .whitespaces)
                if !sentence.isEmpty { result.append(sentence) }
                current = ""
            }
        }
        let rest = current.trimmingCharacters(in: .whitespaces)
        if !rest.isEmpty { result.append(rest) }
        return result
    }

    // MARK: - Stimmen

    static var selectedVoiceID: String {
        UserDefaults.standard.string(forKey: SettingsKey.voiceIdentifier) ?? builtInVoiceID
    }

    /// Alle installierten deutschen iPhone-Stimmen, die natürlichste zuerst (Premium vor Erweitert vor Standard).
    static var germanVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("de") && !isNovelty($0) }
            .sorted { rank($0) > rank($1) }
    }

    /// Die iPhone-Stimme für Sätze ohne Aufnahme bzw. wenn keine eingebaute Stimme gewählt ist.
    static func systemVoice(for voiceID: String) -> AVSpeechSynthesisVoice? {
        if voiceID != builtInVoiceID, voiceID != automaticVoiceID,
           let chosen = AVSpeechSynthesisVoice(identifier: voiceID) {
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

    // MARK: - Wiedergabe

    private var activeVoiceID = Speaker.builtInVoiceID

    private func segments(for text: String, voiceID: String) -> [Segment] {
        guard voiceID == Self.builtInVoiceID else {
            return [.speech(text)]
        }
        return Self.sentences(in: text).map { sentence -> Segment in
            if let file = clips[sentence], let url = Bundle.main.url(forResource: file, withExtension: nil) {
                return .clip(url)
            }
            return .speech(sentence)
        }
    }

    private func enqueue(_ segments: [Segment], interrupt: Bool, previewVoiceID: String? = nil) {
        if interrupt { stop() }
        activeVoiceID = previewVoiceID ?? Self.selectedVoiceID
        queue.append(contentsOf: segments)
        if !isPlaying { playNext() }
    }

    private func playNext() {
        guard !queue.isEmpty else {
            isPlaying = false
            return
        }
        isPlaying = true
        switch queue.removeFirst() {
        case .clip(let url):
            guard let newPlayer = try? AVAudioPlayer(contentsOf: url) else {
                playNext()
                return
            }
            newPlayer.delegate = self
            player = newPlayer
            if !newPlayer.play() { playNext() }
        case .speech(let text):
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = Self.systemVoice(for: activeVoiceID)
            // Natürliche Tonhöhe; nur etwas ruhiger als normal, damit Kinder gut folgen können.
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
            utterance.pitchMultiplier = 1.0
            synthesizer.speak(utterance)
        }
    }

    /// Kurze Pause zwischen zwei Sätzen, dann weiter – sofern nicht inzwischen abgebrochen wurde.
    private func continueAfterPause() {
        let current = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self, self.generation == current else { return }
            self.playNext()
        }
    }
}

extension Speaker: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.continueAfterPause() }
    }
}

extension Speaker: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.continueAfterPause() }
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
