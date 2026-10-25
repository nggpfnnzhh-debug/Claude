import AVFoundation
import UIKit

/// Spricht Anweisungen und Lob – Kinder im Vorschulalter können noch nicht lesen.
///
/// Alle Sätze sind als Aufnahmen in der App enthalten (`voice_manifest.json` + Audiodateien).
/// Es gibt bewusst keine Computerstimme als Ersatz: Sätze ohne Aufnahme werden übersprungen
/// (`VoiceCoverageTests` stellt sicher, dass es keine gibt).
final class Speaker: NSObject {
    static let shared = Speaker()

    private var player: AVAudioPlayer?
    private var queue: [URL] = []
    /// `true`, solange eine Aufnahme läuft oder die Pause bis zur nächsten läuft.
    private var isBusy = false
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
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    /// - Parameter interrupt: `false` hängt den Text an das gerade Gesprochene an.
    func say(_ text: String, interrupt: Bool = true) {
        let enabled = UserDefaults.standard.object(forKey: SettingsKey.speechEnabled) as? Bool ?? true
        guard enabled else { return }
        if interrupt { stop() }
        queue.append(contentsOf: Self.sentences(in: text).compactMap(url(for:)))
        if !isBusy { playNext() }
    }

    func stop() {
        generation += 1
        queue.removeAll()
        player?.stop()
        player = nil
        isBusy = false
    }

    /// Ob Huhu gerade spricht (auch während der kurzen Pause zwischen zwei Sätzen).
    var isSpeaking: Bool { isBusy }

    /// Wartet, bis Huhu zu Ende gesprochen hat – höchstens `timeout` Sekunden,
    /// damit ein Spiel nie hängen bleibt (z. B. wenn ein Anruf die Wiedergabe unterbricht).
    @MainActor
    func waitUntilQuiet(timeout: TimeInterval = 10) async {
        let deadline = Date().addingTimeInterval(timeout)
        while isBusy, Date() < deadline, !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    /// Ob für diesen Satz eine Aufnahme existiert (für Tests).
    func hasClip(for sentence: String) -> Bool {
        url(for: sentence) != nil
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

    private func url(for sentence: String) -> URL? {
        guard let file = clips[sentence] else {
            #if DEBUG
            print("Speaker: keine Aufnahme für „\(sentence)“")
            #endif
            return nil
        }
        return Bundle.main.url(forResource: file, withExtension: nil)
    }

    private func playNext() {
        guard !queue.isEmpty else {
            isBusy = false
            return
        }
        isBusy = true
        let url = queue.removeFirst()
        guard let newPlayer = try? AVAudioPlayer(contentsOf: url) else {
            playNext()
            return
        }
        newPlayer.delegate = self
        player = newPlayer
        if !newPlayer.play() { playNext() }
    }
}

extension Speaker: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Kurze Pause zwischen zwei Sätzen, dann weiter – sofern nicht inzwischen abgebrochen wurde.
        DispatchQueue.main.async {
            let current = self.generation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self, self.generation == current else { return }
                self.player = nil
                self.playNext()
            }
        }
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
    /// Lob, wenn es beim ersten Versuch geklappt hat – auch Lob für genaues Hinschauen.
    static let firstTryPraise = [
        "Super!", "Toll gemacht!", "Richtig!", "Klasse!", "Prima!", "Genau!", "Wunderbar!",
        "Du hast genau hingeschaut!", "Gut überlegt!",
    ]
    /// Lob nach Fehlversuchen: würdigt Ausdauer statt Ergebnis.
    static let persistencePraise = [
        "Du hast nicht aufgegeben!", "Gut, dass du es nochmal versucht hast!", "Geschafft! Weiter so!",
    ]
    static let numberWords = [
        "null", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn",
        "elf", "zwölf", "dreizehn", "vierzehn", "fünfzehn", "sechzehn", "siebzehn", "achtzehn", "neunzehn", "zwanzig",
    ]

    static func praise(afterMistakes: Bool) -> String {
        (afterMistakes ? persistencePraise : firstTryPraise).randomElement() ?? "Super!"
    }
}
