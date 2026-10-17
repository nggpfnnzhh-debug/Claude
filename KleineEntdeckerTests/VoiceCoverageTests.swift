import XCTest
@testable import KleineEntdecker

/// Stellt sicher, dass jeder Satz, den die App sprechen kann, als Aufnahme vorliegt.
/// Schlägt der Test fehl: Satz in scripts/voice/generate.py ergänzen und den Workflow „Stimme erzeugen“ starten.
final class VoiceCoverageTests: XCTestCase {
    private func spokenTexts() -> [String] {
        var texts: [String] = []
        for game in Game.allCases where game != .memory {
            for _ in 0..<60 {
                for countingMax in [5, 10] {
                    for task in TaskFactory.tasks(for: game, countingUpTo: countingMax) {
                        texts.append(task.instruction)
                        texts.append(task.correctFeedback)
                        texts += task.choices.map(\.wrongFeedback)
                        if case let .letter(letter) = task.prompt { texts.append(letter) }
                    }
                }
            }
        }
        texts += Phrases.praise + Phrases.retry + Phrases.numberWords.dropFirst()
        texts += Lines.fixed
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
        XCTAssertTrue(missing.isEmpty, "Ohne Aufnahme: \(missing)")
    }

    func testSentenceSplitting() {
        XCTAssertEqual(Speaker.sentences(in: "Das ist Blau. Wo ist Rot?"), ["Das ist Blau.", "Wo ist Rot?"])
        XCTAssertEqual(Speaker.sentences(in: "Super! Drei!"), ["Super!", "Drei!"])
        XCTAssertEqual(Speaker.sentences(in: "A"), ["A"])
    }
}
