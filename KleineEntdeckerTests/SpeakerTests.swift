import XCTest
@testable import KleineEntdecker

/// Prüft, dass die Spiele erst weiterschalten, wenn Huhu fertig gesprochen hat.
@MainActor
final class SpeakerTests: XCTestCase {
    private var savedSpeechSetting: Any?

    override func setUp() async throws {
        savedSpeechSetting = UserDefaults.standard.object(forKey: SettingsKey.speechEnabled)
        UserDefaults.standard.set(true, forKey: SettingsKey.speechEnabled)
        Speaker.shared.stop()
    }

    override func tearDown() async throws {
        Speaker.shared.stop()
        UserDefaults.standard.set(savedSpeechSetting, forKey: SettingsKey.speechEnabled)
    }

    /// Fehlerfall aus dem Test: Nach mehreren Fehlversuchen ist das Lob länger als die früher
    /// fest eingestellten 2,2 Sekunden – die nächste Aufgabe erschien, während Huhu noch sprach.
    func testWaitsUntilLongPraiseAfterMistakesIsFinished() async {
        let task = TaskFactory.tasks(for: .letters, level: 0)[0]
        let text = "\(Phrases.persistencePraise[1]) \(task.correctFeedback)"
        let start = Date()

        Speaker.shared.say(text)
        XCTAssertTrue(Speaker.shared.isSpeaking)
        await Speaker.shared.waitUntilQuiet(timeout: 20)

        XCTAssertFalse(Speaker.shared.isSpeaking)
        XCTAssertGreaterThan(Date().timeIntervalSince(start), 2.2)
    }

    func testStopEndsWaitingImmediately() async {
        Speaker.shared.say(Lines.breakTime)
        Speaker.shared.stop()
        let start = Date()
        await Speaker.shared.waitUntilQuiet()
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.5)
    }

    func testWaitingNeverHangsLongerThanTimeout() async {
        Speaker.shared.say(Lines.breakTime)
        let start = Date()
        await Speaker.shared.waitUntilQuiet(timeout: 0.5)
        XCTAssertLessThan(Date().timeIntervalSince(start), 1.5)
    }

    func testNothingToWaitForWhenSpeechIsOff() async {
        UserDefaults.standard.set(false, forKey: SettingsKey.speechEnabled)
        Speaker.shared.say(Lines.breakTime)
        XCTAssertFalse(Speaker.shared.isSpeaking)
    }
}
