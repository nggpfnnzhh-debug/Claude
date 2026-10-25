import XCTest
@testable import KleineEntdecker

/// Stellt sicher, dass jeder Satz, den die App sprechen kann, als Aufnahme vorliegt.
/// Schlägt der Test fehl: Satz in scripts/voice/generate.py ergänzen und den Workflow „Stimme erzeugen“ starten.
final class VoiceCoverageTests: XCTestCase {
    private func taskTexts(games: [Game]) -> [String] {
        var texts: [String] = []
        for game in games {
            for level in 0...game.maxLevel {
                for _ in 0..<60 {
                    for task in TaskFactory.tasks(for: game, level: level) {
                        texts.append(task.instruction)
                        texts.append(task.correctFeedback)
                        texts += task.choices.map(\.wrongFeedback)
                        switch task.prompt {
                        case let .letter(_, sound): texts.append(sound)
                        case let .word(_, syllables): texts.append(syllables)
                        default: break
                        }
                    }
                }
            }
        }
        return texts
    }

    private func spokenTexts() -> [String] {
        var texts: [String] = []
        // Ohne Jahreszeit-Motive …
        Seasonal.override = Seasonal(season: .summer)
        texts += taskTexts(games: Game.allCases.filter { $0 != .memory })
        // … und mit allen Jahreszeiten und Festen (Zählen und Mengen nutzen dieselben Motive).
        for variant in Seasonal.allVariants {
            Seasonal.override = variant
            texts += taskTexts(games: [.counting, .moreLess])
            texts += variant.memoryCards.map(\.name)
            if let announcement = variant.announcement { texts.append(announcement) }
        }
        Seasonal.override = nil
        // Uhr: alle Zeiten vollständig, nicht nur zufällig erzeugte
        for hour in 1...12 {
            for minute in [0, 30] {
                let time = TaskFactory.timeText(hour: hour, minute: minute)
                texts += ["Wo ist es \(time)?", "Es ist \(time).", "Hier ist es \(time)."]
            }
        }
        texts += Phrases.firstTryPraise + Phrases.persistencePraise + Phrases.numberWords.dropFirst()
        texts += Lines.fixed
        texts += Game.allCases.compactMap(\.tapHint)
        for nickname in ChildProfile.nicknames {
            let spoken = ChildProfile.spokenName(name: nickname.name, adjective: nickname.adjective) ?? ""
            texts.append(Lines.hello(spoken))
            texts.append(Lines.celebration(spoken))
        }
        texts += MemoryGameView.animals.map(\.name)
        return texts
    }

    func testEverySpokenSentenceHasRecording() {
        let sentences = Set(spokenTexts().flatMap(Speaker.sentences(in:)))
        let missing = sentences.filter { !Speaker.shared.hasClip(for: $0) }.sorted()
        XCTAssertTrue(missing.isEmpty, "Ohne Aufnahme (\(missing.count)): \(missing)")
    }

    func testSentenceSplitting() {
        XCTAssertEqual(Speaker.sentences(in: "Das ist Blau. Wo ist Rot?"), ["Das ist Blau.", "Wo ist Rot?"])
        XCTAssertEqual(Speaker.sentences(in: "Super! Drei!"), ["Super!", "Drei!"])
        XCTAssertEqual(Speaker.sentences(in: "Ba-na-ne. Drei Silben!"), ["Ba-na-ne.", "Drei Silben!"])
        XCTAssertEqual(Speaker.sentences(in: "A"), ["A"])
    }
}
